#!/usr/bin/python
"""
This script tries to automate the steps necessary when doing a new
release of an ivoatex document.

Much of this gyrates around document specs.  There are parsed from
ivoatexmeta and are dicts of
{Docversion:, Docdate:, Docdatecode:, Doctype:, BaseURL}.
"""

import datetime
import os
import re
import sys
import webbrowser


def get_ivoatex_meta():
    """returns an ivoatex meta dictionary for the current ivoatexmeta.
    """
    vars = {}
    assignment_pattern = re.compile(
        r"\\.*command\{\\ivoa(\w+)\}\{(.*)\}")
    with open("ivoatexmeta.tex", encoding="utf-8") as f:
        for line in f:
            mat = assignment_pattern.match(line)
            if mat:
                vars[mat.group(1)] = mat.group(2)
    return vars


def add_previous_version(spec):
    """adds a link pointing to the document version defined by spec
    to docname.tex.
    """
    docname = spec["Docname"]
    cur_document_url = spec["BaseURL"]+"/"+spec["Docdatecode"]

    if os.environ.get("IVOATEX_HUSH")!="shsh":
        print("I am opening a web browser that should show the last\n"
            "version of the document.  If it does not, break out of\n"
            "this script and fix DOCVERSION, DOCDATE, or perhaps\n"
            "DOCREPO_BASEURL in the Makefile.")
        webbrowser.open(cur_document_url)
        input("Break if you don't see the document, hit return otherwise")

    if spec["Doctype"] in ("REC", "EN"):
        doctag = "{}-{}".format(spec["Doctype"], spec["Docversion"])
    elif spec["Doctype"]=="NOTE":
        doctag = "Version {}".format(spec["Docversion"])
    else:
        doctag = "{}-{}-{}".format(
            spec["Doctype"], spec["Docversion"], spec["Docdatecode"])

    with open(docname+".tex", encoding="utf-8") as f:
        tex_source = f.read()

    pos = tex_source.find("\n\\previousversion")
    if pos==-1:
        sys.exit(f"No \\previousversion in {docname}.tex?")
    new_source = (tex_source[:pos]
        + f"\n\\previousversion[{cur_document_url}]{{{doctag}}}"
        +tex_source[pos:])

    new_source = re.sub(
        r"\\section\{Change(s from Previous Versions| History)\}",
        rf"\g<0>\n\n%\\subsection{{Changes from {doctag}}}\n",
        new_source)

    new_source = new_source.encode("utf-8")
    with open(docname+".tex", "wb") as f:
        f.write(new_source)


def bump_version(ivoa_version):
    """returns the next minor version of an IVOA spec.

    We're using modern stdproc syntax, i.e., *no* 1.04->1.05 or so.
    """
    major, minor = ivoa_version.split(".")
    minor = int(minor)+1
    return f"{major}.{minor}"


def update_spec(cur_spec):
    """returns plausible defaults for a new release of a document
    described by cur_spec.
    """
    new_spec = cur_spec.copy()
    del new_spec["Docdatecode"]

    new_version_requiring = {"EN": "PEN", "REC": "WD", "NOTE": "NOTE"}
    if cur_spec["Doctype"] in new_version_requiring:
        new_spec["Doctype"] = new_version_requiring[cur_spec["Doctype"]]
        new_spec["Docversion"] = bump_version(cur_spec["Docversion"])

    new_spec["Docdate"] = datetime.date.today().strftime("%Y-%m-%d")

    return new_spec


def update_Makefile(new_spec):
    """edits the makfile to reflect new_spec
    """
    new_lines = []
    with open("Makefile", encoding="utf-8") as f:
        for ln in f:
            if ln.startswith("DOCVERSION = "):
                new_lines.append("DOCVERSION = "+new_spec["Docversion"]+"\n")
            elif ln.startswith("DOCDATE = "):
                new_lines.append("DOCDATE = "+new_spec["Docdate"]+"\n")
            elif ln.startswith("DOCTYPE = "):
                new_lines.append("DOCTYPE = "+new_spec["Doctype"]+"\n")
            else:
                new_lines.append(ln)

    new_content = "".join(new_lines).encode("utf-8")
    with open("Makefile", "wb") as f:
        f.write(new_content)


def update_with_default(spec, key, prompt):
    default = spec[key]
    user_input = input(f"{prompt}? [{default}] ")
    if user_input:
        spec[key] = user_input


def main():
    cur_spec = get_ivoatex_meta()
    new_spec = update_spec(cur_spec)

    update_with_default(new_spec, "Doctype", "New document type")
    update_with_default(new_spec, "Docversion", "New version")
    update_with_default(new_spec, "Docdate", "New document date")

    add_previous_version(cur_spec)
    update_Makefile(new_spec)

if __name__=="__main__":
    main()

# vim:sta:et:sw=4

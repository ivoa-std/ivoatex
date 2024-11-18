#!/usr/bin/env python

"""
A little script to operate the IVOA submission form with data scrubbed
from ivoatex sources.

The keys used here are taken from screen-scraping
https://www.ivoa.net/cgi-bin/up.cgi (which is also the target to POST
to).

Fields needed:

* title
* concise_name
* email
* filename
* authors
* editors
* abstract
* comment
* group_name (this is controlled vocabulary that authors must follow;
  we should probably validate that here)
* version_major, version_minor
* date
* status (one of Note, WD, PR, REC, EN, PEN, Other)

This is a bit lame in that we (largely) work on the repo rather than the
zipfile to work out these values.  If this ever becomes a problem, see
what we are doing to validate the MANIFEST.
"""

import pprint
import os
import re
import subprocess
import sys
import tempfile
import zipfile
from xml.etree import ElementTree as etree

try:
    import requests
except ImportError:
    sys.exit("*** Automatic document submission needs the Python 'requests'"
        " package.\n"
        "*** Please install it (Debian: python3-requests; pypi: requests).\n")


DOCREPO_URL = 'http://testingdocrepo.ivoa.info/new_doc'


class ReportableError(Exception):
    """raise this with a human-readable error message to cause a non-traceback
    program exit.
    """

def H(el_name):
    """returns an XHTML 1.0 Qname for el_name.
    """
    return etree.QName("http://www.w3.org/1999/xhtml", el_name)


def to_text(el):
    """returns a concatenation of the text contents of el and its sub-elements.
    """
    return "".join(el.itertext()).strip()


class DocumentMeta(object):
    """a blackboard to collect the various pieces of information on the
    document.

    For now, we just use attributes named like the fields in the
    IVOA docrepo API.
    """
    _attrs = ["title", "concise_name", "email",
        "authors", "editors", "abstract",
        "comment", "group_name", "version_major", "version_minor",
        "date", "status"]

    def __init__(self, **kwargs):
        for k, v in kwargs.items():
            setattr(self, k, v)
        self._authors = []
        self._editors = []
        self.group_name = None
        self.comment = ""

    def get_post_payload(self):
        """returns a dictionary ready to post with requests.
        """
        payload = {}
        for name in self._attrs:
            if not hasattr(self, name):
                raise ReportableError("Metadata item %s missing.\n This usually"
                    " is because the generated HTML is bad."%name)
            payload[name] = getattr(self, name)
        return payload

    def add_info_from_document(self):
        """tries to obtain missing metadata from the formatted (XHTML) source.
        """
        with open(self.concise_name+".html", "rb") as f:
            tree = etree.parse(f)

        # The following would be a bit smoother if we had xpath; there's
        # no xpath engine in the stdlib, though (and no BeautifulSoup),
        # so let's do a bit of manual work rather than pull in a fat
        # dependency.

        # first h1 is the document title
        for el in tree.iter(H("h1")):
            self.title = to_text(el)
            break

        # pull things with ids or unique classes
        for el in tree.iter():
            if el.get("id")=="abstract":
                # first element currently is an h2 with text "Abstract".
                # actual content is in the element tail.  Ugh.  This needs
                # cleanup.
                el[0].text = ""
                self.abstract = to_text(el)
            elif el.get("id")=="ivoagroup":
                self.group_name = to_text(el)
            elif el.get("class")=="author":
                self._authors.append(to_text(el))
            elif el.get("class")=="editor":
                self._editors.append(to_text(el))

    @property
    def authors(self):
        return ", ".join(self._authors)

    @property
    def editors(self):
        return ", ".join(self._editors)

    @classmethod
    def from_makefile(cls):
        """creates a basic document meta with attributes obtainable
        from the makefile filled in.
        """
        meta_keys = {}
        with open("Makefile", encoding="utf-8") as f:
            for ln in f:
                mat = re.match("(\w+)\s*=\s*(.*)", ln)
                if mat:
                    meta_keys[mat.group(1)] = mat.group(2)

        kwargs = {}
        for input_key, parser_function in [
                ("DOCNAME", lambda v: [("concise_name", v.strip())]),
                ("DOCVERSION", cls._parse_DOCVERSION),
                ("DOCDATE", cls._parse_DOCDATE),
                ("AUTHOR_EMAIL", cls._parse_AUTHOR_EMAIL),
                ("DOCTYPE", lambda v: [("status", v.strip())])]:
            if input_key not in meta_keys:
                raise ReportableError("%s not defined/garbled in Makefile"
                    " but required for upload."%input_key)
            kwargs.update(
                dict(parser_function(meta_keys[input_key])))

        res = cls(**kwargs)

        if "IVOA_GROUP" in meta_keys:
            res.group_name = res._get_wg_code(meta_keys["IVOA_GROUP"])

        return res

    @staticmethod
    def _parse_DOCVERSION(version_string):
        """helps from_makefile by returning form keys from the document version.
        """
        mat = re.match("(\d).(\d+)", version_string)
        if not mat:
            raise ReportableError("DOCVERSION in Makefile (%s) garbled."%
                version_string)
        yield "version_major", mat.group(1)
        yield "version_minor", mat.group(2)

    @staticmethod
    def _parse_DOCDATE(date_string):
        """helps from_makefile by returning form keys from the document date.

        (actually, in the new docrepo we don't need to parse; but
        we still do some basic format validation.
        """
        mat = re.match("(\d\d\d\d)-(\d\d)-(\d\d)", date_string)
        if not mat:
            raise ReportableError("DOCDATE in Makefile (%s) garbled."%
                date_string)

        yield "date", mat.group()

    @staticmethod
    def _parse_AUTHOR_EMAIL(email_string):
        """helps from_makefile by returning a form key for the email.
        """
        yield "email", email_string


def review_and_comment(document_meta):
    """prints document_meta and lets the user add a remark if they want.
    """
    editor = os.environ.get("VISUAL",
        os.environ.get("EDITOR", "nano"))

    fd, path_name = comment_src = tempfile.mkstemp()
    try:
        os.write(fd, b'# optionally enter comment(s) below.\n')
        os.close(fd)
        subprocess.check_call([editor, path_name])
        with open(path_name, encoding="utf-8") as f:
            document_meta.comment = re.sub("(?m)^#.*$", "", f.read())
    finally:
        os.unlink(path_name)

    pprint.pprint(document_meta.get_post_payload())
    print("-----------------------\n")
    print("Going to upload %s\n"%document_meta.title)
    print("*** Version: %s.%s, %s of %s ***\n"%(
        document_meta.version_major,
        document_meta.version_minor,
        document_meta.status,
        document_meta.date))
    print("Hit ^C if this (or anthing in the dict above) is wrong,"
        " enter to upload.")
    input()


def validate_manifest(archive_file_name):
    """raises a ReportableError if we notice anything is wrong with the
    MANIFEST.
    """
    with zipfile.ZipFile(archive_file_name) as archive:
        # strip off the directory part, since that is not part of
        # the manifest paths.
        members = [n.split("/", 1)[-1] for n in archive.namelist()]

    with open("MANIFEST") as f:
        for line_no, line in enumerate(f):
            if line.startswith("#") or not line.strip():
                continue
            try:
                anchor, doctype, path = [s.strip() for s in line.split(";")]
                if not path in members:
                    raise ReportableError(
                        f"MANIFEST: Missing file in line:{line_no+1}: {path}")

                if doctype not in ["document", "schema"]:
                    raise ReportableError(
                        f"MANIFEST: Bad doctype {doctype}"
                        f" in line:{line_no+1}: {path}")

            except Exception as ex:
                raise ReportableError(
                    f"MANIFEST: bad syntax in line {line_no+1} ({ex})")


def main(archive_file_name, dry_run):
    document_meta = DocumentMeta.from_makefile()
    document_meta.add_info_from_document()
    validate_manifest(archive_file_name)
    review_and_comment(document_meta)
    print("Uploading... ", end="", flush=True)

    if dry_run:
        with open("submission-payload.txt", "w", encoding="utf-8"):
            f.write("\n".join(f"{k} {v}" for k, v in
                sorted(document_meta.get_post_payload().items()))+"\n")
        print("*** Aborted since --dry-run was passed.")
        return

    with open(sys.argv[1], "rb") as upload:
        resp = requests.post(DOCREPO_URL,
            data=document_meta.get_post_payload(),
            files=[('filename', (sys.argv[1], upload))])

    sys.stdout.write("done (result in docrepo-response.html)\n")
    with open("docrepo-response.html", "w", encoding="utf-8") as f:
        f.write(resp.text)


if __name__=="__main__":
    import argparse
    parser = argparse.ArgumentParser(
        description="Upload an IVOA document")
    parser.add_argument("pkgname", help="Name of the archive to upload.")
    parser.add_argument("--dry-run", action="store_true",
        dest="dry_run", help="Only do local actions, but do no http requests.")
    args = parser.parse_args()

    try:
        main(args.pkgname, args.dry_run)
    except ReportableError as msg:
        sys.stderr.write("*** Failure while preparing submission:\n")
        sys.exit(msg)

# vim:sta:sw=4:et

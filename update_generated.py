#!/usr/bin/env python
# Update all generated sections in a text file.
#
# This is part of ivoatex.  See COPYING for the license.
#
# Generarated sections are between % GENERATED: <command>
# and % /GENERATED.  They are supposed to contain the output of
# <command>.  <command> get shell-expanded, but since it gets executed
# anyway, it's not even worth doing shell injection.
#
# When this script finishes, it either has updated all sections or
# stopped with an error message of a failed command, in which case the
# original file is unchanged.

from io import StringIO
import csv
import os
import re
import subprocess
import sys

try:
    import requests
except ImportError:
    # silently fail for now; !taptable and !vocterms will not work without
    # requests, though
    pass

class ExecError(Exception):
    def __init__(self, command, stderr):
        Exception.__init__(self, "Failed command %s"%repr(command))
        if isinstance(stderr, bytes):
            stderr = stderr.decode("utf-8", "ignore")
        self.command, self.stderr = command, stderr


def escape_for_TeX(tx):
    """returns tx with TeX's standard active (and other magic) characters
    escaped.
    """
    # the $ is tricky because blindly replacing it with \$ will clash
    # with my backslash replacement.  Let's hope nobody ever has a
    # sterling sign in their schemas...
    return tx.replace("$", "£",
        ).replace("\\", "$\\backslash$"
        ).replace("£", "\\$"
        ).replace("&", "\\&"
        ).replace("#", "\\#"
        ).replace("%", "\\%"
        ).replace("_", "\\_"
        ).replace("}", "\\}"
        ).replace("{", "\\{"
        ).replace('"', '{"}')


def cmd_taptable(table_name):
    """returns an ivoatex-formatted table describing table_name in the
    TAP sevice at $TAPURL.

    This needs the requests module installed, and TAPURL must be defined
    in the makefile.
    """
    tap_url = os.environ["TAPURL"]
    reply = requests.get(tap_url+"/sync", params={
        "LANG": "ADQL",
        "REQUEST": "doQuery",
        "QUERY": 'SELECT column_name, datatype, "size", description'
            ' FROM TAP_SCHEMA.columns WHERE table_name=\'%s\''%table_name,
        "FORMAT": "csv"})

    res = ["\\begin{inlinetable}\n\\small"
        r"\begin{tabular}{p{0.28\textwidth}p{0.2\textwidth}p{0.66\textwidth}}"
        r"\sptablerule"
        r"\multicolumn{3}{l}{\textit{Column names, ADQL types,",
        r"and descriptions for the \texttt{%s} table}}\\"%table_name,
        r"\sptablerule"]

    for row in csv.DictReader(StringIO(reply.text)):
        row = dict((key, escape_for_TeX(value))
            for key, value in row.items())
        if row["size"]=="":
            row["size"] = '(*)'
        elif row["size"]=='1':
            row["size"] = ''
        else:
            row["size"] = "(%s)"%row["size"]

        res.append(r"""
            \makebox[0pt][l]{\scriptsize\ttfamily %(column_name)s}&
            \footnotesize %(datatype)s%(size)s&
            %(description)s\\"""%row)

    res.extend([
        "\\sptablerule\n\\end{tabular}\n\\end{inlinetable}"])

    return "\n".join(res)


def cmd_schemadoc(schema_name, dest_type):
    """returns TeX source for the generated documentation of dest_type within
    schema_name.

    We cannot just use the output of the stylesheet, as TeX escapes in
    XSLT1 are an inefficient nightmare.
    """
    output = subprocess.check_output(["xsltproc",
        "--stringparam", "destType", dest_type,
        "ivoatex/schemadoc.xslt", schema_name]).decode("utf-8")
    # for the TeX escaping, we simply assume there's no nesting
    # of escaped sections, and no annotation uses our magic strings.
    return "\\begin{generated}\n%s\n\\end{generated}\n"%(
        re.sub("(?s)escape-for-TeX{{{(.*?)}}}",
            lambda mat: escape_for_TeX(mat.group(1)), output))


def cmd_vocterms(vocabulary_name):
    """returns TeX source for the terms (identifiers) in an IVOA vocabulary.

    vocabulary_name is whatever is after http://www.ivoa.net/rdf.
    """
    terms = requests.get("http://www.ivoa.net/rdf/"+vocabulary_name,
            headers={"accept": "application/x-desise+json"}
        ).json()["terms"]
    identifiers = [key for key, props in terms.items()
        if "deprecated" not in props]
    return ",\n".join(r"\textsl{{{}}}".format(escape_for_TeX(id))
        for id in sorted(identifiers, key=lambda t: t.lower()))


def process_one_builtin(command):
    """processes a GENERATED block containing a call to a builtin function.

    In the GENERATED opening line, an internal call is signified with a
    leading bang (which process_one already removes).

    What's left is a command spec and blank-separated arguments.  The command
    spec is prepended with cmd_ and then used as a function name to call.
    The remaining material is split and passed to the function as positional
    arguments.

    The function returns the return value of function, which must be a
    string for this to work.
    """
    try:
        parts = command.split()
        print("Calling %s(%s)"%("cmd_"+parts[0], ", ".join(parts[1:])))
        return globals()["cmd_"+parts[0]](*parts[1:])
    except Exception as ex:
        ex.command = command
        raise


def process_one_exec(command):
    """processes a GENERATED block containing a shell command.

    command is the shell command as specified in the GENERATED's opening
    line.

    The output of the command is returned; in case of failures, an ExecError
    is raised.
    """
    print("Executing %s"%command)
    f = subprocess.Popen(command, shell=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        close_fds=True, bufsize=-1)
    stdout, stderr = f.communicate()

    if f.returncode!=0:
        raise ExecError(command, stderr)
    return stdout.decode("utf-8")


def process_one(match_obj):
    """processes one GENERATED block, executing the specified command and
    returning its output.

    This is intended to be used as a callback within re.sub as executed
    by process_all.
    """
    command = match_obj.group("command")
    if command.startswith("!"):
        result = process_one_builtin(command[1:])
    else:
        result = process_one_exec(command)

    return ("%% GENERATED: %s\n"%(command.strip())
        +result
        +"\n% /GENERATED")


def process_all(content):
    """replaces all GENERATED blocks within content.

    Exceptions from within one of the recipes are propagated out.
    """
    return re.sub(r"(?sm)^%\s+GENERATED:\s+(?P<command>.*?)$"
        ".*?"
        r"%\s+/GENERATED",
        process_one,
        content)


def parse_command_line():
    import argparse
    parser = argparse.ArgumentParser(description="Update generated content"
        " in a text file")
    parser.add_argument("filename", action="store", type=str,
        help="File to process (will be overwritten).")
    return parser.parse_args()


def main():
    args = parse_command_line()
    with open(args.filename, "rb") as f:
        content = f.read().decode("utf-8")

    try:
        content = process_all(content)
    except ExecError as ex:
        sys.stderr.write("Command %s failed.  Message below.  Aborting.\n"%
            ex.command)
        sys.stderr.write(ex.stderr+"\n")
        sys.exit(1)

    content = content.encode("utf-8")
    with open(args.filename, "wb") as f:
        f.write(content)


if __name__=="__main__":
    main()

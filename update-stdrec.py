#!/usr/bin/python
# update a the StandardsRegExt record for a release

import datetime
import re
import sys
from xml.etree import ElementTree

for _prefix, _uri in [
        ("vr", "http://www.ivoa.net/xml/VOResource/v1.0"),
        ("vstd", "http://www.ivoa.net/xml/StandardsRegExt/v1.0"),
        ("xsi", "http://www.w3.org/2001/XMLSchema-instance"),
        ("ri", "http://www.ivoa.net/xml/RegistryInterface/v1.0")]:
    ElementTree.register_namespace(_prefix, _uri)


class ReportableError(Exception):
    pass


class DocMeta:
    def __init__(self, version, date, type):
        self.version, self.date, self.type = version, date, type


def get_doc_meta():
    try:
        with open("ivoatexmeta.tex", "r") as f:
            src = f.read()
    except IOError:
        raise ReportableError("Cannot read ivoatexmeta.tex; this usually"
            " means you have not yet run make.")

    try:
        return DocMeta(
            re.search(r"ivoaDocversion}{([^}]+)}", src).group(1),
            re.search(r"ivoaDocdate}{([^}]+)}", src).group(1),
            re.search(r"ivoaDoctype}{([^}]+)}", src).group(1))
    except AttributeError:
        import traceback; traceback.print_exc()
        raise ReportableError("Parse error in ivoatexmeta.  Try running"
            " make and file a bug against ivoatex if the error persists.")


def main(source_name):
    doc_meta = get_doc_meta()
    try:
        source_tree = ElementTree.parse(source_name)
    except ElementTree.ParseError as ex:
        raise ReportableError("Your StandardsExtRecord {} cannot be"
            " parsed: {}.  Please fix it.".format(
                source_name, ex))

    root = source_tree.getroot()
    root.attrib["updated"
        ] = datetime.datetime.utcnow().isoformat()

    curation = root.find("curation")
    for index, el in enumerate(curation):
        if el.tag=="date":
            break
    else:
        raise ReportableError("No date element in curation.")

    new_update = ElementTree.Element("date", attrib={"role": "Updated"})
    new_update.text = doc_meta.date
    new_update.tail = "\n    "
    curation.insert(index, new_update)

    curation.find("version").text = doc_meta.version
    ev = root.find("endorsedVersion")
    ev.attrib["status"] = doc_meta.type.lower()
    ev.text = doc_meta.version

    with open(source_name, "wb") as f:
        source_tree.write(f, encoding="utf-8")
        f.write(b"\n")


if __name__=="__main__":
    try:
        if len(sys.argv)!=2:
            raise ReportableError("Usage: {} <vor-file-name>")

        main(sys.argv[1])
    except ReportableError as ex:
        sys.exit(str(ex))

# vim:et:sw=4:sta

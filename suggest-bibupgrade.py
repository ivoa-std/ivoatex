#!/usr/bin/python3
"""
A script somewhat naively looking for outdated references an suggesting
updates.

This expects the name of an .aux file as produced by a LaTeX run.  I'd
expect this to be run through

make bib-suggestions

exclusively.

If this actually gets use, we might think about flagging false positives
(i.e., cases where document references are really version-sharp.

Maintenance: Occasionally look at the diffs on docrepo.bib; anything that's
not version 1 very likely belongs here.
"""

import re
import sys

# Maintain docmap as (new) (old) with any whitespace and one pair per line
# Yes, that's the NEW reference tag first.  It's what you see first when
# inspecting things.
_DOCMAP ="""
2021ivoa.spec.1102D 2010ivoa.spec.1202P
2021ivoa.spec.1101D 2010ivoa.rept.1123A
2021ivoa.spec.0616C 2018ivoa.spec.0527P
2021ivoa.spec.0525D 2009ivoa.spec.1007G
2019ivoa.spec.1021O 2013ivoa.spec.0920O
2019ivoa.spec.1011D 2014ivoa.spec.1208D
2019ivoa.spec.1007G 2006ivoa.spec.0528P
2019ivoa.spec.1007F 2014ivoa.spec.0602F
2019ivoa.spec.0927D 2011ivoa.spec.1028T
2018ivoa.spec.0723D 2009ivoa.spec.1104B
2018ivoa.spec.0625P 2008ivoa.spec.0222P
2018ivoa.spec.0621G 2013ivoa.spec.0329G
2018ivoa.spec.0527P 2007ivoa.spec.0402P
2017ivoa.spec.0530P 2013ivoa.spec.1125P
2017ivoa.spec.0524T 2008ivoa.spec.0124R
2017ivoa.spec.0524G 2011ivoa.spec.0531G
2017ivoa.spec.0517G 2010ivoa.spec.0413H
2017ivoa.spec.0517D 2013ivoa.spec.1129D
2017ivoa.spec.0509L 2011ivoa.spec.1028T
2016ivoa.spec.1024H 2010ivoa.spec.1010H
2016ivoa.spec.0523D 2007ivoa.spec.0314P
2015ivoa.spec.1223D 2009ivoa.spec.1111H
2013ivoa.spec.0920O 2009ivoa.spec.1130O
2013ivoa.spec.0329G 2009ivoa.specQ1007G
2012ivoa.spec.1104T 2012ivoa.spec.0411B
2012ivoa.spec.0210T 2008ivoa.spec.0201D
2008ivoa.spec.0201D 2007ivoa.spec.1220D
2011ivoa.spec.0711S 2006ivoa.spec.1101S
2010ivoa.spec.1216B 2009ivoa.spec.0421B
2010ivoa.spec.0413H 2003ivoa.spec.1024H
2009ivoa.spec.1130O 2004ivoa.spec.0811O
2009ivoa.specQ1007G 2008ivoa.spec.0124G
2008ivoa.spec.0325L 2007ivoa.spec.1108L
2008ivoa.spec.0201D 2007ivoa.spec.1220D
2007ivoa.spec.0402P 2005ivoa.spec.1231D
2007ivoa.spec.0302H 2004ivoa.spec.0426H
2007ivoa.spec.0302H std:RM
2017ivoa.spec.0517G std:DocSTDProc
2017ivoa.spec.0517G std:DocSTD
2016ivoa.spec.0523D std:VOID
2016ivoa.spec.0523D std:VOID2
2018ivoa.spec.0625P std:VOR
2016ivoa.spec.1024H std:UWS
2016ivoa.spec.1024H std:UWS11
2019ivoa.spec.0927D std:TAP
2017ivoa.spec.0530P std:DALREGEXT
2010ivoa.spec.1202P std:VODS11
2017ivoa.spec.0517D std:DALI
2017ivoa.spec.0517D std:DALI11
2011ivoa.spec.0711S std:VOEVENT
2011ivoa.spec.0711S std:VOEVENT2
2005ivoa.spec.0819D std:UCD
2012ivoa.spec.0508H std:STDREGEXT
2012ivoa.spec.0827D std:TAPREGEXT
2015ivoa.spec.1223D std:SIAv2
2015ivoa.spec.1223D std:SIAP
2008ivoa.specQ0222P std:SCS
2012ivoa.spec.0210T std:SSAP
2008ivoa.spec.1030O std:ADQL
2018ivoa.spec.0621G std:VOSPACE
2018ivoa.spec.0723D std:RI1
2019ivoa.spec.1011D std:RI2
2007ivoa.spec.1030R std:STC
2017ivoa.spec.0524T std:SSOAUTH
2017ivoa.spec.0524T std:SSOAUTH2
2010ivoa.spec.0218P std:CDP
2017ivoa.spec.0524G std:VOSI
2017ivoa.spec.0524G std:VOSI11
2014ivoa.spec.0523D std:VOUNIT
2017ivoa.spec.0509L std:OBSCORE
2011ivoa.spec.1120M std:SDM
2019ivoa.spec.1007F std:MOC
2019ivoa.spec.1011D std:RegTAP
2015ivoa.spec.0617D std:DataLink
2019ivoa.spec.1021O std:VOTABLE
2021ivoa.spec.1101D note:VOARCH
2018ivoa.spec.0529H note:schemaversioning
2019ivoa.spec.0520D note:DataCollect
2013ivoa.rept.1213D note:TAPNotes
2010ivoa.rept.0618D note:votstc
2023ivoa.spec.1215M 2008ivoa.spec.1030O
2023ivoa.spec.1215G 2014ivoa.spec.0523D
2023ivoa.spec.1215B 2015ivoa.spec.0617D
2023ivoa.spec.1117C 2021ivoa.spec.0310C
2023ivoa.spec.0206D 2021ivoa.spec.0525D
2023ivoa.spec.0125C 2021ivoa.spec.0616C
2022ivoa.spec.1101S 2013ivoa.spec.1005S
2022ivoa.spec.0727F 2019ivoa.spec.1007F
2022ivoa.spec.0222D 2013ivoa.spec.1125P
"""


OLD2NEW = dict((p[1], p[0])
    for p in (ln.split()
        for ln in _DOCMAP.split("\n") if ln.strip()))


def get_suggestion(ref_tag):
    """returns a suggestion for what to replace ref_tag with.

    If ref_tag seems up to date, it is returned unchanged.
    """
    while ref_tag in OLD2NEW:
        ref_tag = OLD2NEW[ref_tag]
    return ref_tag


def iter_ref_tags(f):
    """yields all arguments of citation macro calls within the file f's
    content.

    We expect the citation calls to be all in one line and without
    whitespace and all that.  I think that's how LaTeX produces them:
    We're reading from an aux file here.
    """
    pat = re.compile(r"\\citation\{([^}]*)}")
    for ln in f:
        mat = pat.search(ln)
        if mat:
            yield mat.group(1)


def main():
    if len(sys.argv)!=2:
        sys.exit("Do not call this script directly.")

    suggestions = {}
    with open(sys.argv[1], encoding="utf-8") as f:
        for ref_tag in iter_ref_tags(f):
            replacement = get_suggestion(ref_tag)
            if replacement!=ref_tag:
                suggestions[ref_tag] = replacement

    if suggestions:
        # There may be a bit of mess from the LaTeX run(s) above us, so feed
        # a bit of white space.
        print("\n\n*** Consider updating the following references:")
        for ref_tag, replacement in suggestions.items():
            print(f"{ref_tag} -> {replacement} ?")

    else:
        print("\n\n*** All references seem up to date.")


class TestSuggestions:
    def test_unknown(self):
        assert get_suggestion("whatever")=="whatever"

    def test_recursive(self):
        assert get_suggestion("2004ivoa.spec.0811O")=="2019ivoa.spec.1021O"


def test_get_suggestion():
    import io
    input = io.StringIO(
        "Something not involving citation{ or something\n"
        "\\citation{one}\n"
        "A maformed \\citation{ought to be ignored\n"
        "\\citation{two} and junk after, too.\n")
    assert list(iter_ref_tags(input))==["one", "two"]


if __name__=="__main__":
    main()

#!/usr/bin/python3
"""
A regression test for ivoatexDoc.

The idea is to exercise the various section's claims in something like
a function per section (where we probably shouldn't reference the sections
by the (unstable) numbers; hm).  All this can hopefully be done
in a single document that's being kept in a temporary directory
that is created in run_tests, which also does the scaffolding.

The test functions should raise AssertionErrors when something is wrong.
The assumption is that the first error terminates the entire run.  Still,
by only editing based on what test_first_run produces, you can comment
out intermediate tests during development.

The most convenient mode for development is probably to call run_shell()
at the right time.

Do edits using the edit_file function; it will fail if an edit does
not change anything, which adds some robustness to what naturally is
a bit shaky.

Distributed under CC0 by the IVOA.
"""


import contextlib
import datetime
import os
import subprocess
import tempfile
import traceback


####################### Misc. utilities

def execute(cmd, check_output=None, input=None):
	"""execute a subprocess.Popen-compatible command cmd under supervision.

	Specifically, we run with shell=True so the ivoatexDoc recipes work as
	given in the spec.

	We bail out when either cmd's return code is non-0 or the assertion
	check_stdout is not met.  For now, that is: neither stdout nor stderr
	contains a string.
	"""
	output = subprocess.check_output(cmd, shell=True, input=input,
		stderr=subprocess.STDOUT)
	output = output.decode("utf-8")
	if isinstance(check_output, str):
		with open("last-output.txt", "w", encoding="utf-8") as f:
			f.write(output)
		assert check_output in output, f"'{check_output}' missing"
	return output


def _assert_for_particles(file_name, assertion, particles):
	"""implements assert_in_file.

	assertion is a callable(particle, content), where particle and
	content are either both str or both bytes.  It needs to raise
	an AssertionError if the assertion is wrong.
	"""
	with open(file_name, "rb") as f:
		content = f.read()
	if particles and isinstance(particles[0], str):
		content = content.decode("utf-8")
	
	for part in particles:
		assertion(part, content)


def assert_in_file(file_name, *particles):
	"""raises an assertion error if any of the strings/bytes in particles is
	not present in the file file_name.

	if particles[0] is a string, content will be utf-8 decoded, else
	we will make assertions about byte strings.
	"""
	def _(part, content):
		assert part in content, f"'{part}' not in {file_name}"
	_assert_for_particles(file_name, _, particles)


def assert_not_in_file(file_name, *particles):
	"""raises an assertion error if any of the strings/bytes in particles is
	present in the file file_name.

	See assert_in_file for details.
	"""
	def _(part, content):
		assert part not in content, f"'{part}' present in {file_name}"
	_assert_for_particles(file_name, _, particles)


def run_shell():
	print("\n*** Here is a shell in the document directory:")
	subprocess.call([os.environ.get("SHELL", "sh")])


def do_edit(doc, to_replace, replacement):
	"""replaces to_replace with replacement in doc, making sure something
	actually changed.
	"""
	changed = doc.replace(to_replace, replacement)
	assert doc!=changed, f"{to_replace} -> {replacement} didn't do anything"
	return changed


def edit_file(target_file, replacements):
	"""replaces target_file with a version with replacements applied.

	Each (old, new) replacement must change the document.
	"""
	with open(target_file, encoding="utf-8") as f:
		doc = f.read()

	for to_replace, replacement in replacements:
		doc = do_edit(doc, to_replace, replacement)
	
	with open(target_file, "w", encoding="utf-8") as f:
		f.write(doc)


@contextlib.contextmanager
def in_dir(dest_dir):
	"""executes the controlled block within destDir and then returns
	to the previous directory.
	"""
	owd = os.getcwd()
	os.chdir(dest_dir)
	try:
		yield owd
	finally:
		os.chdir(owd)


########################## Actual tests

def edit_Makefile_template():
	#	Sect. 2.2.3, paragraph "Main metadata"
	edit_file("Makefile", [
		("DOCNAME = ????", "DOCNAME = Regress"),
		("DOCDATE = ???", "DOCDATE = 2023-02-01"),
		("DOCTYPE = ???", "DOCTYPE = NOTE")])


def edit_document_template():
	#	Sect. 2.2.3, paragraph "Additional metadata"
	edit_file("Regress.tex", [
			(r"\input tthdefs", "\\batchmode\n\\input tthdefs"),
			("???? Full title ????", "Regression test"),
			("???? group ????", "Standards and Processes"),
			("\\author[????URL????", "\\author[http://ivoa.net/authors/Fred/Test"),
			("????Alfred Usher Thor????", "Test, F."),
			("????Fred Offline????", "Other-Person, A. N."),
			("???? Abstract ????", "This is a document for a regression test.\n"
				"  It doesn't say anything interesting at all.  But it should\n"
				" press many buttons.\n\nLike multi-paragraph"
				" abstracts, for instance."),
			("???? Or remove the section header ????", "This regression test"
				" supported by the Martian Open Science Cloud project of the"
				" Olympus Mons philosophical society."),
			("??? Write something ????", "This is the start of nothing"),
			(r"\includegraphics[width=0.9\textwidth]{role_diagram.pdf}",
				"(no figure yet)"),
			("???? and so on, LaTeX as you know and love it. ????",
				"\section{Normative Nonsense}"),
		])


def test_first_run():
	# Basically, make sure that a very basic LaTeX call works and yields a
	# plausible PDF.
	execute("make", "Latexmk: All targets (Regress.pdf) are up-to-date")
	execute("pdftotext Regress.pdf")

	assert_in_file("Regress.txt",
		"Working Group\nStandards and Processes",
		"This version\nhttps://www.ivoa.net/documents/Regress/20230201",
		"\nTest, F., Other-Person, A. N.\n",
		"This is an IVOA Note expressing",
		"2 Normative Nonsense\n\n3",
		"‘Key words for use in RFCs to")


def test_template_files():
	assert_in_file("README.md",
		"This document describes/defines FILL-THIS-OUT",
		"see [ivoatexDoc](https://ivoa.net/documents/Notes/IVOATex/)")
	
	assert_in_file("LICENSE",
		"Attribution-ShareAlike 4.0 International")


def test_archdiag():
	execute("cp ivoatex/archdiag-full.xml role_diagram.xml")
	execute("git add role_diagram.xml")
	edit_file("Makefile", [
		("SOURCES = $(DOCNAME).tex", "SOURCES = $(DOCNAME).tex role_diagram.pdf"),
		("FIGURES =", "FIGURES = role_diagram.svg"),])
	edit_file("role_diagram.xml", [
		('<rec name="HiPS" x="430" y="430" w="33"/>',
			'<thisrec name="Regression" x="430" y="430" w="80"/>')])
	edit_file("Regress.tex", [
			("(no figure yet)",
				r"\includegraphics[width=0.9\textwidth]{role_diagram.pdf}")])

	execute("make")

	assert_in_file("role_diagram.pdf", b"%PDF-1.5", b"/Kids [ 2 0 R ]")
	assert_in_file("Regress.log",
		"<role_diagram.pdf, id=47, 803.0pt x 602.25pt>")


def test_extra_macros():
	edit_file("Regress.tex", [
		(r"\previousversion{This is the first public release}",
			"\previousversion[http://ivoa.net/documents/alt]{Regress WD 0.1}"),
		(r"\appendix",
			"Do not use \\ucd{meta.ref.ivorn} in (\\xmlel{FIELD})"
			" or \\vorent{capability}.\n\n"
			"\\begin{inlinetable}\n\\begin{tabular}{ll}\n\\sptablerule\n"
			"a&b \\\\\n\\sptablerule\n"
			"\\end{tabular}\\end{inlinetable}\n"
			"\\appendix"),
		("?This is the start of nothing",
			"In a Regression test, we sometimes want to break things.\n\n"
			"\\begin{admonition}{Note}\nBut still be reasonable.\\end{admonition}"),
		])
	
	execute("make Regress.html")

	assert_in_file("Regress.html",
		"<i>meta.ref.ivorn</i>",
		'(<span class="xmlel">FIELD</span>)',
		'<span class="vorent">capability</span>',
		'<div class="admonition">',
		'<p class="admonition-type">Note</p>',
		'But still be reasonable.',
		'<table class="tabular">',
		'<tr><td align="left">a</td>')


def test_verbatims():
	edit_file("Regress.tex", [
		(r"\input tthdefs",
			"\\input tthdefs\n\\lstset{flexiblecolumns=true,showstringspaces=False}"),
		(r"\section{Normative Nonsense}", "\\section{Normative Nonsense}\n"
			"\\begin{lstlisting}[language=XML]\n"
			'foo_1 = "\\galt\'s?"\n'
			'<ja-klar/>\n'
			'\\end{lstlisting}\n')])

	execute("make")
	execute("pdftotext Regress.pdf")

	assert_in_file("Regress.txt",
		'foo_1 = "\\galt\'s?"\n'
		'<ja-klar/>')


def test_referencing():
	edit_file("Regress.tex", [
		(r"\section{Normative Nonsense}", "\\section{Normative Nonsense}\n"
			"We are not talking about \\citet{2010ivoa.spec.1202P}\n")])

	execute("make")
	execute("pdftotext Regress.pdf")

	assert_in_file("Regress.txt",
		'We are not talking about Plante and Stébé et al. (2010)',
		"Bradner, S. (1997), ‘Key words",
		"Collections, Services Version 1.1’",
		"http://doi.org/10.5479/ADS/bib/2010ivoa.spec.1202P")

	execute("make bib-suggestions",
		"2010ivoa.spec.1202P -> 2021ivoa.spec.1102D ?")


def test_auxiliaryurl_and_test():
	edit_file("Regress.tex", [
		(r"\section{Normative Nonsense}", "\\section{Normative Nonsense}\n"
			"See (\\auxiliaryurl{our-instance.xml}) for details.")])
	edit_file("Makefile", [
		('AUX_FILES =', 'AUX_FILES = our-schema.xml')])
	with open("our-instance.xml", "w") as f:
		f.write(
"""<ri:Resource xmlns:ri="http://www.ivoa.net/xml/RegistryInterface/v1.0" xmlns:vg="http://www.ivoa.net/xml/VORegistry/v1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" created="2014-09-24T08:36:00Z" status="active" updated="2020-09-17T10:19:29Z" xsi:type="vg:Authority">
  <title>GAVO Education and Outreach WG</title>
  <identifier>ivo://edu.gavo.org</identifier>
  <curation>
  	<publisher>GAVO</publisher>
  	<contact><name>Winnie</name></contact>
  </curation>
  <content>
    <subject>virtual-observatories</subject>
    <description>authority</description>
    <referenceURL>http://www.g-vo.org/</referenceURL>
  </content>
  <managingOrg>ivo://org.gavo.dc/org</managingOrg>
</ri:Resource>""")

	execute("make Regress.html")

	assert_in_file("Regress.html",
		'See (<a href="https://www.ivoa.net/documents/Regress/20230201/'
		'our-instance.xml">https://www.ivoa.net/documents/Regress/'
		'20230201/our-instance.xml</a>) for')

	edit_file("Makefile", [
		("test:", "STILTS ?= stilts\ntest:"),
		('@echo "No tests defined yet"',
			'@$(STILTS) xsdvalidate schemaloc="http://www.ivoa.net/xml/VORegistry/v1.0=http://www.ivoa.net/xml/VORegistry/v1.0" doc=our-instance.xml')])

	assert execute("make test")==""


def test_git_integration():
	execute("git init")
	edit_file("Makefile", [
		("SOURCES = ", "SOURCES = gitmeta.tex ")])
	edit_file("Regress.tex", [
		(r"\input tthdefs", "\\input tthdefs\n\\input gitmeta")])
	execute("make")
	execute("pdftotext Regress.pdf")

	assert_in_file("Regress.txt",
		"Version Control",
		"Revision ",
		"-dirty, "+datetime.datetime.now().strftime("%Y-%m-%d"))

	execute("git add Regress.tex")
	execute("git commit -am 'test commit'")
	execute("make")
	execute("pdftotext Regress.pdf")

	with open("Regress.txt", encoding="utf-8") as f:
		tx = f.read()
	assert "-dirty" not in tx, "Commit has not removed -dirty tag?"
	# or perhaps obtain git commit hash and check for its presence?


def test_generated_content():
	# It would certainly be great if we tested schemadoc here, too,
	# but for now I'm not desperate enough to include a full schema here.
	edit_file("Regress.tex", [
		(r"\appendix", "\n".join([
			r"\section{Generated Nonsense}",
			"",
			r"% GENERATED: echo I am building from $TAPURL",
			r"% /GENERATED",
			"",
			r"% GENERATED: !taptable rr.relationship",
			r"% /GENERATED",
			"",
			r"% GENERATED: !vocterms datalink/core",
			r"% /GENERATED",
			"",
			r"\appendix"]))])
	edit_file("Makefile", [
		("-include ivoa",
			"export TAPURL=http://reg.g-vo.org/tap\n\n-include ivoa")])

	execute("make generate")
	execute("make")
	execute("pdftotext Regress.pdf")

	assert_in_file("Regress.txt",
		"I am building from http://reg.g-vo.org/tap", # shell execution
		"related_id", # from taptable
		"auxiliary, bias," # from vocterms
		)


def test_new_release():
	# keep newrelease.py from opening web browsers.
	os.environ["IVOATEX_HUSH"] = "shsh"
	execute("make new-release", input=b"EN\n\n\n")

	assert_in_file("Makefile",
		"DOCDATE = "+datetime.date.today().strftime("%Y-%m-%d"),
		"DOCTYPE = EN")
	assert_in_file("Regress.tex",
		"\previousversion[https://www.ivoa.net/documents/Regress/20230201]{Version 1.0}",
		"%\subsection{Changes from Version 1.0}")

	execute("make new-release", input=b"\n\n\n")
	assert_in_file("Makefile",
		"DOCTYPE = PEN",
		"DOCVERSION = 1.2")
	assert_in_file("Regress.tex",
		"\previousversion[https://www.ivoa.net/documents/Regress/20",
		"]{EN-1.1}",
		"%\subsection{Changes from EN-1.1}")


def test_html_content():
	# This test builds on various previous tests and will fail if these
	# are skipped.
	execute("make Regress.html")
	assert_in_file("Regress.html",
		'<div id="abstract"><h2>Abstract</h2>',
		' This is an IVOA Proposed Endorsed Note for review',
		'<a href="#tth_sEc1">1  Introduction</a>',
		'<p class="admonition-type">Note</p>',
		'<a href="#std:RFC2119" id="CITEstd:RFC2119" class="tth_citation">',
		'(Bradner, 1997)</a>',
		'<img class="archdiag" src="role_diagram.svg" alt="role_diagram.svg"/>',
		'<a href="#2010ivoa.spec.1202P" id="CITE2010ivoa.spec.1202P" class="tth_citation">',
		'Plante and Stébé et al. (2010)</a>',
		'<span class="verbline">foo_1 = "\\galt\'s?"',
		'<i>meta.ref.ivorn</i>', # \ucd macro: perhaps make this a span?
		'<span class="xmlel">FIELD</span>')


def test_all_bibliography():
	# with a little bit of luck, this will fail in interesting ways if
	# we git bibliography entries wrong
	edit_file("Regress.tex", [
		(r"\appendix", "\n".join([
			r"\nocite{*}"
			r"\appendix"]))])
	
	execute("make Regress.html")

	assert_not_in_file("Regress.blg",
		"isn't style-file defined")

	assert_in_file("Regress.html",
		"<dt><b>Taylor (2006)</b></dt>", # author tag from ivoabib
		'<a href="https://ui.adsabs.harvard.edu/abs/2006ASPC..351..666T"><tt>https://ui.', # rendered link
		'<dt><b>Plante &amp; Demleitner et al. (2018)</b></dt>', # from ivoabib
		'IVOA Recommendation 25 June 2018', # howpublished rendered
		'<a href="http://doi.org/10.5479/ADS/bib/2018ivoa.spec.0625P"><tt>http://doi.org/10.5479', # ivoabib link
	)


def run_tests(branch_name):
		os.environ["DOCNAME"] = "Regress"
		execute("mkdir $DOCNAME")
		os.chdir(os.environ["DOCNAME"])

		execute("git init")
		execute("git submodule add https://github.com/ivoa-std/ivoatex")
# TODO: make repo configurable like with branch
#		execute("git submodule add https://github.com/mbtaylor/ivoatex")
		if branch_name:
			with in_dir("ivoatex"):
				execute(f"git checkout '{branch_name}'")

		execute("sh ivoatex/make-templates.sh $DOCNAME")
		execute('git commit -m "Starting $DOCNAME"')

		edit_Makefile_template()
		edit_document_template()

		test_first_run()
		test_template_files()

		if True:
			test_archdiag()

			test_extra_macros()

			test_verbatims()

			test_referencing()

			test_auxiliaryurl_and_test()

			test_git_integration()

			test_generated_content()

			test_new_release()

			test_html_content()

		test_all_bibliography()

		run_shell()


def parse_command_line():
	import argparse
	parser = argparse.ArgumentParser(description="ivoaTeX regression test")
	parser.add_argument("--branch",
		dest="branch_name", default=None, metavar="NAME",
		help="run against ivoatex branch NAME rather than master")

	return parser.parse_args()


def main():
	args = parse_command_line()

	with tempfile.TemporaryDirectory("ivoatex") as dir:
		try:
			print(f"Testing in {dir}")
			os.chdir(dir)
			run_tests(args.branch_name)
		except Exception as ex:
			traceback.print_exc()
			print(f"**Failure. Dumping you in a shell in the testbed.")
			print("Exit the shell to tear it down.")
			run_shell()


if __name__=="__main__":
	main()


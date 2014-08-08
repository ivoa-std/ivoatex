#  ivoatex control makefile
#
#  This is for inclusion into a main Makefile from one level up.
#  This main Makefile must define DOCNAME, DOCVERSION, DOCDATE, DOCSTATUS
#  SOURCES
#
#  Main useful targets are
#
#    (default): builds a PDF of the main document
#     forcetex: runs TeX several times (to update aux files)
#     archive:  builds PDF and HTML documents, as well as SAMP.zip file
#               suitable for submission to IVOA doc coordinator
#               (default target)
#     clean:    delete 

CSS_HREF = http://www.ivoa.net/misc/ivoa_doc.css
TTH = ivoatex/tth_C/tth
ARCHIVE_FILES = $(DOCNAME).tex $(DOCNAME).pdf $(DOCNAME).html $(FIGURES)

#  Requirements:
#     XML validator and XSLT processor
#     pdflatex
#     PDF->GIF converter (ImageMagick)
#     jar (JDK)
#  All most likely present on, e.g., a linux disribution.
#  Could use substitites for some of these if they are not available.
XSLTPROC = xsltproc
XMLLINT = xmllint -noout
PDFLATEX = pdflatex
PDF2GIF = convert -density 54x54
JAR = jar

TEXINPUTS=.;ivoatex

.SUFFIXES: .pdf .gif .tex
.PHONY: biblio


$(DOCNAME).pdf: $(DOCNAME).tex $(FIGURES) ivoatexmeta.tex
	$(PDFLATEX) $(DOCNAME)


forcetex:
	$(PDFLATEX) $(DOCNAME)   # && $(PDFLATEX) $(DOCNAME) && $(PDFLATEX) $(DOCNAME)


archive: $(DOC).pdf $(DOC).html $(UPLOAD).zip $(ARCHIVE).zip

clean:
	rm -f $(DOCNAME).pdf $(DOCNAME).aux $(DOCNAME).log $(DOCNAME).toc texput.log
	rm -f $(DOCNAME).html $(DOCNAME).xhtml
	rm -f *.bbl *.blg *.out debug.html

ivoatexmeta.tex: Makefile
	rm -f $@
	touch $@
	echo '% GENERATED FILE -- edit this in the Makefile' >>$@
	echo '\newcommand{\ivoaDocversion}{$(DOCVERSION)}' >>$@
	echo '\newcommand{\ivoaDocdate}{$(DOCDATE)}' >>$@
	echo '\newcommand{\ivoaDocdatecode}{$(DOCDATE)}' | sed -e 's/-//g' >>$@
	echo '\newcommand{\ivoaDoctype}{$(DOCTYPE)}' >>$@
	echo '\newcommand{\ivoaDocname}{$(DOCNAME)}' >>$@

$(DOCNAME).html: $(DOCNAME).pdf $(FIGURES:=.gif) ivoatex/tth-ivoa.xslt $(TTH)
	$(TTH) -w2 -e2 -u2 -pivoatex -L$(DOCNAME) <$(DOCNAME).tex \
						|	tee debug.html \
          	| $(XSLTPROC) --html \
                         --stringparam CSS_HREF $(CSS_HREF) \
                      ivoatex/tth-ivoa.xslt - \
           >$(DOCNAME).html


# the following has no explicit dependencies, as we don't want
# to run BibTeX everytime the TeX input is changed.  The idea is
# that when people do bibliography-relevant changes, they run
# make biblio manually.
$(DOCNAME).bbl: $(DOCNAME).tex ivoatex/ivoabib.bib
	$(PDFLATEX) $(DOCNAME).tex
	bibtex $(DOCNAME).aux
	$(PDFLATEX) $(DOCNAME).tex 2>&1 >/dev/null
	touch $(DOCNAME).tex


biblio: $(DOCNAME).bbl


#$(UPLOAD).zip: $(DOC).pdf $(DOC).html $(FIGURES:=.gif)
#	rm -rf tmp/
#	mkdir tmp
#	cp $(DOC).pdf tmp/$(UPLOAD).pdf
#	cp $(DOC).html tmp/$(UPLOAD).html
#	cp $(FIGURES:=.gif) tmp/
#	cd tmp; $(JAR) cfM ../$(UPLOAD).zip \
#                       $(UPLOAD).pdf $(UPLOAD).html $(FIGURES:=.gif)
#	rm -rf tmp/
#
#$(ARCHIVE).zip: $(ARCHIVE_FILES)
#	rm -rf tmp/
#	mkdir tmp
#	cp $(ARCHIVE_FILES) tmp/
#	cd tmp; $(JAR) cfM ../$(ARCHIVE).zip $(ARCHIVE_FILES)
#	rm -rf tmp/
#
#  Build TtH from source.  See http://hutchinson.belmont.ma.us/tth/.
#  TtH source seems to be highly portable, so compilation should be easy
#  as long as you have a C compiler.
$(TTH): ivoatex/tth_C/tth.c
	$(CC) -o $(TTH) ivoatex/tth_C/tth.c

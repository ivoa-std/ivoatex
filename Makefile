#  ivoatex control makefile
#
#  This is for inclusion into a main Makefile from one level up.
#  This main Makefile must define DOCNAME, DOCVERSION, DOCDATE, DOCTYPE
#  SOURCES; also, FIGURES as needed.
#
#  See README for the targets in here useful to the user.

CSS_HREF = http://www.ivoa.net/misc/ivoa_doc.css
TTH = ivoatex/tth_C/tth
ARCHIVE_FILES = $(DOCNAME).tex $(DOCNAME).pdf $(DOCNAME).html $(FIGURES)

#  Requirements:
#     XSLT processor
#     C compiler
#     GNU make (or another sufficiently powerful make)
#     pdflatex
#     PDF->GIF converter (ImageMagick)
#     zip
#  All most likely present on, e.g., a linux disribution.
#  Could use substitites for some of these if they are not available.
XSLTPROC = xsltproc
XMLLINT = xmllint -noout
PDFLATEX = pdflatex
PDF2GIF = convert -density 54x54
ZIP = zip

TEXINPUTS=.;ivoatex

# standard file name according to S&D standards
versionedName:=$(DOCTYPE)-$(DOCNAME)-$(DOCVERSION)
ifneq "$(DOCTYPE)" "REC"
		versionedName:=$(versionedName)-$(subst -,,$(DOCDATE))
endif

.SUFFIXES: .pdf .gif .tex
.PHONY: biblio


$(DOCNAME).pdf: $(SOURCES) $(FIGURES) ivoatexmeta.tex
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
          	| $(XSLTPROC) --html \
                         --stringparam CSS_HREF $(CSS_HREF) \
                      ivoatex/tth-ivoa.xslt - \
           >$(DOCNAME).html


$(DOCNAME).bbl: $(DOCNAME).tex ivoatex/ivoabib.bib
	$(PDFLATEX) $(DOCNAME).tex
	bibtex $(DOCNAME).aux
	$(PDFLATEX) $(DOCNAME).tex 2>&1 >/dev/null
	touch $(DOCNAME).tex

# We don't let the pdf depend on .bbl, as we don't want to run BibTeX
# everytime the TeX input is changed.  The idea is that when people do
# bibliography-relevant changes, they run make biblio manually.
biblio: $(DOCNAME).bbl


package: $(DOCNAME).html $(DOCNAME).pdf
	rm -rf -- $(versionedName)
	mkdir $(versionedName)
	cp $(DOCNAME).html $(versionedName)/$(versionedName).html
	cp $(DOCNAME).pdf $(versionedName)/$(versionedName).pdf

ifneq ($(strip $(FIGURES)),)
	cp $(FIGURES) $(versionedName)
endif

	zip -r $(versionedName).zip $(versionedName)
	rm -rf -- $(versionedName)


#  Build TtH from source.  See http://hutchinson.belmont.ma.us/tth/.
#  TtH source seems to be highly portable, so compilation should be easy
#  as long as you have a C compiler.
$(TTH): ivoatex/tth_C/tth.c
	$(CC) -o $(TTH) ivoatex/tth_C/tth.c

#  ivoatex control makefile
#
#  This is for inclusion into a main Makefile from one level up.
#  This main Makefile must define DOCNAME, DOCVERSION, DOCDATE, DOCTYPE
#  SOURCES; also, FIGURES as needed.
#
#  See http://ivoa.net/documents/Notes/IVOATex/index.html 
#  for the targets in here useful to the user.
#
#  You should *not* need to change anything here while authoring documents.
#  All customisation should happen in the user Makefile

IVOATEX_VERSION = 0.4

CSS_HREF = http://www.ivoa.net/misc/ivoa_doc.css
TTH = ivoatex/tth_C/tth
ARCHIVE_FILES = $(DOCNAME).tex $(DOCNAME).pdf $(DOCNAME).html $(FIGURES)

#  Requirements:
#     XSLT processor
#     C compiler
#     GNU make (or another sufficiently powerful make)
#     pdflatex
#     ghostscript (if you plan on postscript/pdf figures)
#     zip
#  All most likely present on, e.g., a linux disribution.
#  Could use substitites for some of these if they are not available.
XSLTPROC = xsltproc
XMLLINT = xmllint -noout
PDFLATEX = pdflatex
CONVERT = convert
ZIP = zip

export TEXINPUTS=.:ivoatex:

# standard file name according to S&D standards
versionedName:=$(DOCTYPE)-$(DOCNAME)-$(DOCVERSION)
ifneq "$(DOCTYPE)" "REC"
		versionedName:=$(versionedName)-$(subst -,,$(DOCDATE))
endif

GENERATED_PNGS = $(addsuffix .png, $(VECTORFIGURES))

.SUFFIXES: .pdf .gif .tex .png
.PHONY: biblio

%.pdffig.png: %.pdffig
#	# simple ImageMagic -antialias didn't work too well
	$(CONVERT) -density 300 $< temp-$@
	$(CONVERT) temp-$@ -scale 25% $@
	rm temp-$@

$(DOCNAME).pdf: ivoatexmeta.tex $(SOURCES) $(FIGURES) $(VECTORFIGURES)
	$(PDFLATEX) $(DOCNAME)


forcetex:
	$(PDFLATEX) $(DOCNAME)   # && $(PDFLATEX) $(DOCNAME) && $(PDFLATEX) $(DOCNAME)


archive: $(DOC).pdf $(DOC).html $(UPLOAD).zip $(ARCHIVE).zip

clean:
	rm -f $(DOCNAME).pdf $(DOCNAME).aux $(DOCNAME).log $(DOCNAME).toc texput.log
	rm -f $(DOCNAME).html $(DOCNAME).xhtml
	rm -f *.bbl *.blg *.out debug.html
	rm -f *.pdffig.png

ivoatexmeta.tex: Makefile
	rm -f $@
	touch $@
	echo '% GENERATED FILE -- edit this in the Makefile' >>$@
	/bin/echo '\newcommand{\ivoaDocversion}{$(DOCVERSION)}' >>$@
	/bin/echo '\newcommand{\ivoaDocdate}{$(DOCDATE)}' >>$@
	/bin/echo '\newcommand{\ivoaDocdatecode}{$(DOCDATE)}' | sed -e 's/-//g' >>$@
	/bin/echo '\newcommand{\ivoaDoctype}{$(DOCTYPE)}' >>$@
	/bin/echo '\newcommand{\ivoaDocname}{$(DOCNAME)}' >>$@

$(DOCNAME).html: $(DOCNAME).pdf ivoatex/tth-ivoa.xslt $(TTH) \
		$(GENERATED_PNGS)
	$(TTH) -w2 -e2 -u2 -pivoatex -L$(DOCNAME) <$(DOCNAME).tex \
		| $(XSLTPROC) --html \
                         --stringparam CSS_HREF $(CSS_HREF) \
                      ivoatex/tth-ivoa.xslt - \
           >$(DOCNAME).html


$(DOCNAME).bbl: $(DOCNAME).tex ivoatex/ivoabib.bib ivoatexmeta.tex
	$(PDFLATEX) $(DOCNAME).tex
	bibtex $(DOCNAME).aux
	$(PDFLATEX) $(DOCNAME).tex 2>&1 >/dev/null
	touch $(DOCNAME).tex

# We don't let the pdf depend on .bbl, as we don't want to run BibTeX
# everytime the TeX input is changed.  The idea is that when people do
# bibliography-relevant changes, they run make biblio manually.
biblio: $(DOCNAME).bbl


package: $(DOCNAME).html $(DOCNAME).pdf \
		$(GENERATED_PNGS)	$(FIGURES) $(AUX_FILES)
	rm -rf -- $(versionedName)
	mkdir $(versionedName)
	cp $(DOCNAME).html $(versionedName)/$(versionedName).html
	cp $(DOCNAME).pdf $(versionedName)/$(versionedName).pdf

ifneq ($(strip $(FIGURES)),)
	cp $(FIGURES) $(versionedName)
endif
ifneq ($(strip $(GENERATED_PNGS)),)
	cp $(GENERATED_PNGS) $(versionedName)
endif
ifneq ($(strip $(AUX_FILES)),)
	cp $(AUX_FILES) $(versionedName)
endif
#	# make sure files will be readable by the web server later on
	chmod -R go+w $(versionedName)
	zip -r $(versionedName).zip $(versionedName)
	rm -rf -- $(versionedName)


#  Build TtH from source.  See http://hutchinson.belmont.ma.us/tth/.
#  TtH source seems to be highly portable, so compilation should be easy
#  as long as you have a C compiler.
$(TTH): ivoatex/tth_C/tth.c
	$(CC) -o $(TTH) ivoatex/tth_C/tth.c

############# below here: building an ivoatex distribution

IVOATEX_FILES = archdiag.png fromivoadoc.xslt Makefile COPYING \
	ivoabib.bib Makefile.template tthdefs.tex document.template \
	ivoa.cls README  tth-ivoa.xslt IVOA.jpg \
	svn-ignore.txt tthntbib.sty 
TTH_FILES= tth_C/CHANGES tth_C/latex2gif tth_C/ps2gif tth_C/tth.c \
	tth_C/tth_manual.html tth_C/INSTALL tth_C/license.txt tth_C/ps2png \
	tth_C/tth.1 tth_C/tth.gif

IVOATEX_ARCHIVE = ivoatex-$(IVOATEX_VERSION).tar.gz

.PHONY: ivoatex-install

$(IVOATEX_ARCHIVE): $(IVOATEX_FILES)
	@echo "This target must be run inside *ivoatex*"
	-mkdir ivoatex
	cp $(IVOATEX_FILES) ivoatex
	-mkdir ivoatex/tth_C
	cp $(TTH_FILES) ivoatex/tth_C
	tar -czf ivoatex-$(IVOATEX_VERSION).tar.gz ivoatex
	rm -rf ivoatex


ivoatex-installdist: $(IVOATEX_ARCHIVE)
	@echo "This target will only work for Markus"
	scp $(IVOATEX_ARCHIVE) alnilam:/var/www/soft/ivoatex/
	ssh alnilam "cd /var/www/soft/ivoatex/; ln -sf $(IVOATEX_ARCHIVE) ivoatex-latest.tar.gz"

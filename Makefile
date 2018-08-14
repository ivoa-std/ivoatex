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

IVOATEX_VERSION = 1.1

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
#     librsvg2-bin (to teach convert to turn svg to pdf, the arch diagram)
#  All of these are likely present on, e.g., a linux distribution,
#  except for librsvg, which is part of the gnome svg toolkit.
#  Hence, please commit both role_diagram.svg and role_diagram.pdf into
#  your VCS.
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

GENERATED_PNGS = $(VECTORFIGURES:pdf=png)

.SUFFIXES: .pdf .gif .tex .png
.PHONY: biblio docrepo.bib

%.png: %.pdf
	# simple ImageMagic -antialias didn't work too well
	$(CONVERT) -density 300 -scale 25% $< $@


$(DOCNAME).pdf: ivoatexmeta.tex $(SOURCES) $(FIGURES) $(VECTORFIGURES)
	$(PDFLATEX) $(DOCNAME)


forcetex:
	$(PDFLATEX) $(DOCNAME)   # && $(PDFLATEX) $(DOCNAME) && $(PDFLATEX) $(DOCNAME)


arxiv-upload: $(SOURCES) biblio $(FIGURES) $(VECTORFIGURES) ivoatexmeta.tex
	mkdir -p stuff-for-arxiv/ivoatex
	cp ivoatex/ivoa.cls ivoatex/tthdefs.tex stuff-for-arxiv
	cp ivoatex/IVOA.jpg stuff-for-arxiv/ivoatex
	# HACK: 2015-10-05 MD: arXiv produces an hyperref option clash without
	# this
	echo nohypertex >> stuff-for-arxiv/00README.XXX
	cp $(SOURCES) $(DOCNAME).bbl $(FIGURES) $(VECTORFIGURES) \
		ivoatexmeta.tex  stuff-for-arxiv
	tar -cvzf arxiv-upload.tar.gz -C stuff-for-arxiv .
	rm -r stuff-for-arxiv

clean:
	rm -f $(DOCNAME).pdf $(DOCNAME).aux $(DOCNAME).log $(DOCNAME).toc texput.log ivoatexmeta.tex
	rm -f $(DOCNAME).html $(DOCNAME).xhtml
	rm -f *.bbl *.blg *.out debug.html
	rm -f arxiv-upload.tar.gz
	rm -f $(GENERATED_PNGS)

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

#		| tee debug.html \

$(DOCNAME).bbl: $(DOCNAME).tex ivoatex/ivoabib.bib ivoatexmeta.tex
	-$(PDFLATEX) -interaction scrollmode $(DOCNAME).tex
	bibtex $(DOCNAME).aux
	$(PDFLATEX) -interaction batchmode $(DOCNAME).tex 2>&1 >/dev/null
	touch $(DOCNAME).tex

# We don't let the pdf depend on .bbl, as we don't want to run BibTeX
# every time the TeX input is changed.  The idea is that when people do
# bibliography-relevant changes, they run make biblio manually.
biblio: $(DOCNAME).bbl

# The architecture diagram is generated from a spec in the document
# directory and a stylesheet.
role_diagram.svg: role_diagram.xml
	$(XSLTPROC) -o $@ ivoatex/make-archdiag.xslt role_diagram.xml 

# Regrettably, pdflatex can't use svg, so we need to convert it
# using convert (which only works with an extra library).  That's 
# a major pain.  Hm.
%.pdf: %.svg
	convert -antialias $< $@ || cp ivoatex/svg-fallback.pdf $@

# generate may modify DOCNAME.tex controlled by arbitrary external binaries.
# It is impossible to model these dependencies (here), and anyway
# I feel something like that shouldn't run automatically.
# Also, it needs python installed, which may not be available on all
# installations.
generate:
	python ivoatex/update_generated.py $(DOCNAME).tex

package: $(DOCNAME).tex $(DOCNAME).html $(DOCNAME).pdf \
		$(GENERATED_PNGS)	$(FIGURES) $(AUX_FILES)
	rm -rf -- $(versionedName)
	mkdir $(versionedName)
	cp $(DOCNAME).tex $(versionedName)/$(versionedName).tex
	cp $(DOCNAME).html $(versionedName)/$(versionedName).html
	cp $(DOCNAME).pdf $(versionedName)/$(versionedName).pdf

ifneq ($(strip $(FIGURES)),)
	cp $(FIGURES) $(versionedName)
endif
ifneq ($(strip $(GENERATED_PNGS)),)
	cp $(GENERATED_PNGS) $(versionedName)
endif
ifneq ($(strip $(AUX_FILES)),)
	cp -r $(AUX_FILES) $(versionedName)
endif
#	# make sure files will be readable by the web server later on
	chmod -R go+w $(versionedName)
	zip -r $(versionedName).zip $(versionedName)
	rm -rf -- $(versionedName)


upload: package
	python ivoatex/submission.py $(versionedName).zip


#  Build TtH from source.  See http://hutchinson.belmont.ma.us/tth/.
#  TtH source seems to be highly portable, so compilation should be easy
#  as long as you have a C compiler.
$(TTH): ivoatex/tth_C/tth.c
	$(CC) -o $(TTH) ivoatex/tth_C/tth.c

############# architecture diagram stuff (to be executed in this directory)

archdiag-l2.svg: archdiag-full.xml make-archdiag.xslt
	$(XSLTPROC) -o $@ make-archdiag.xslt archdiag-full.xml 

archdiag-l1.svg: make-archdiag.xslt
	echo '<archdiag xmlns="http://ivoa.net/archdiag"/>' | \
		$(XSLTPROC) -o $@ make-archdiag.xslt - 

archdiag-l0.svg: make-archdiag.xslt
	echo '<archdiag0 xmlns="http://ivoa.net/archdiag"/>' | \
		$(XSLTPROC) -o $@ make-archdiag.xslt - 


############# below here: building an ivoatex distribution

IVOATEX_FILES = fromivoadoc.xslt Makefile COPYING \
	ivoabib.bib Makefile.template tthdefs.tex document.template \
	ivoa.cls README  tth-ivoa.xslt IVOA.jpg docrepo.bib\
	svn-ignore.txt tthntbib.sty update_generated.py schemadoc.xslt \
	ivoa.bst CHANGES archdiag-full.xml make-archdiag.xslt stdrec-template.xml \
	submission.py svg-fallback.pdf
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

# re-gets the ivoa records from ADS
docrepo.bib:
	curl -o "$@" "http://adsabs.harvard.edu/cgi-bin/nph-abs_connect?db_key=ALL&warnings=YES&version=1&bibcode=%3F%3F%3F%3Fivoa.spec&nr_to_return=1000&start_nr=1&data_type=BIBTEX&use_text=YES"

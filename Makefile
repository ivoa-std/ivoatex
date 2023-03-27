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

IVOATEX_VERSION = 1.2

.DELETE_ON_ERROR:

CSS_HREF = https://www.ivoa.net/misc/ivoa_doc.css
TTH = ivoatex/tth_C/tth
ARCHIVE_FILES = $(DOCNAME).tex $(DOCNAME).pdf $(DOCNAME).html $(FIGURES)
PYTHON?=python3

#  Requirements:
#     XSLT processor
#     C compiler
#     GNU make (or another sufficiently powerful make)
#     texlive
#     ghostscript (if you plan on postscript/pdf figures)
#     zip
#     librsvg2-bin or inkscape (for architecture diagrams)
#     pdftk if you want to build draft pdfs with a watermark
#     optionally, latexmk.
#  If you don't have librsvg2 but you do have inkscape, you
#  can set the SVGENGINE environment variable to inkscape.
#  Then, ivoatex will use inkscape for svg -> pdf conversion.

XSLTPROC = xsltproc
XMLLINT = xmllint -noout
LATEXMK_BANNER := $(shell latexmk --version 2> /dev/null)
ifdef LATEXMK_BANNER
	PDFLATEX = latexmk -pdf
else
	PDFLATEX = pdflatex
endif
CONVERT = convert
ZIP = zip

export TEXINPUTS=.:ivoatex:


# standard file name according to S&D standards
versionedName:=$(DOCTYPE)-$(DOCNAME)-$(DOCVERSION)
ifneq "$(DOCTYPE)" "REC"
		versionedName:=$(versionedName)-$(subst -,,$(DOCDATE))
endif
DOCREPO_BASEURL ?= https://www.ivoa.net/documents/$(DOCNAME)

GENERATED_PNGS = $(VECTORFIGURES:pdf=png)

.SUFFIXES: .pdf .gif .tex .png
.PHONY: biblio docrepo.bib

%.png: %.pdf
	# simple ImageMagic -antialias didn't work too well
	$(CONVERT) -density 300 -scale 25% $< $@


$(DOCNAME).pdf: ivoatexmeta.tex $(SOURCES) $(FIGURES) $(VECTORFIGURES)
ifndef DOCNAME
	$(error No DOCNAME defined.  Do not call plain make in ivoatex.)
endif
	$(PDFLATEX) $(DOCNAME)

forcetex:
	make -W $(DOCNAME).tex $(DOCNAME).pdf

new-release: ivoatexmeta.tex
	$(PYTHON) ivoatex/newrelease.py

$(DOCNAME)-draft.pdf: $(DOCNAME).pdf draft-background.pdf
	pdftk $< background draft-background.pdf output $@

draft-background.pdf: ivoatex/draft-background.tex
	pdflatex $<

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
	rm -f *.bbl *.blg *.out debug.html *.fls *.fdb_latexmk
	rm -f arxiv-upload.tar.gz
	rm -f $(GENERATED_PNGS)

update:
	@echo "*** updating ivoatex from github"
	git submodule update --remote --rebase

.FORCE:

gitmeta.tex: .FORCE
	@/bin/echo -n '\vcsrevision{' > $@
	@/bin/echo -n "$(shell git log -1 --date=short --pretty=%h 2> /dev/null)" >> $@
	@if [ ! -z "$(shell git status --porcelain -uno 2> /dev/null)" ]; then /bin/echo -n -dirty >> $@; fi
	@/bin/echo } >> $@
	@/bin/echo '\vcsdate{' $(shell git log -1 --date=short --pretty=%ai 2> /dev/null) '}' >>$@


ivoatexmeta.tex: Makefile
	rm -f $@
	touch $@
	echo '% GENERATED FILE -- edit this in the Makefile' >>$@
	/bin/echo '\newcommand{\ivoaDocversion}{$(DOCVERSION)}' >>$@
	/bin/echo '\newcommand{\ivoaDocdate}{$(DOCDATE)}' >>$@
	/bin/echo '\newcommand{\ivoaDocdatecode}{$(DOCDATE)}' | sed -e 's/-//g' >>$@
	/bin/echo '\newcommand{\ivoaDoctype}{$(DOCTYPE)}' >>$@
	/bin/echo '\newcommand{\ivoaDocname}{$(DOCNAME)}' >>$@
	/bin/echo '\renewcommand{\ivoaBaseURL}{$(DOCREPO_BASEURL)}' >>$@


$(DOCNAME).html: $(DOCNAME).pdf ivoatex/tth-ivoa.xslt $(TTH) \
		$(GENERATED_PNGS)
	$(TTH) -w2 -e2 -u2 -pivoatex -L$(DOCNAME) <$(DOCNAME).tex \
		| $(XSLTPROC) --html \
                  --stringparam CSS_HREF $(CSS_HREF) \
                  --stringparam docbase "$(DOCREPO_BASEURL)" \
                  ivoatex/tth-ivoa.xslt - \
           >$(DOCNAME).html

#		| tee debug.html \

$(DOCNAME).bbl: $(DOCNAME).tex ivoatex/ivoabib.bib ivoatexmeta.tex
ifdef LATEXMK_BANNER
	$(PDFLATEX) -bibtex $(DOCNAME).tex
else
	-$(PDFLATEX) -interaction batchmode $(DOCNAME).tex
	bibtex $(DOCNAME).aux
	-$(PDFLATEX) -interaction batchmode $(DOCNAME).tex 2>&1 >/dev/null
	$(PDFLATEX) -interaction scrollmode $(DOCNAME).tex
endif

# We don't let the pdf depend on .bbl, as we don't want to run BibTeX
# every time the TeX input is changed.  The idea is that when people do
# bibliography-relevant changes, they run make biblio manually.
biblio: $(DOCNAME).bbl

# The architecture diagram is generated from a spec in the document
# directory and a stylesheet.
role_diagram.svg: role_diagram.xml
	$(XSLTPROC) -o $@ ivoatex/make-archdiag.xslt role_diagram.xml

# Regrettably, pdflatex can't use svg, so we need to convert it.
# We're using inkscape here rather than convert because convert
# rasterises the svg.
ifeq ($(SVGENGINE),inkscape)
%.pdf: %.svg
	inkscape --export-filename=$@ --export-type=pdf $< \
		|| cp ivoatex/svg-fallback.pdf $@
else
%.pdf: %.svg
	rsvg-convert --output=$@ --format=pdf $< \
		|| cp ivoatex/svg-fallback.pdf $@
endif

# generate may modify DOCNAME.tex controlled by arbitrary external binaries.
# It is impossible to model these dependencies (here), and anyway
# I feel something like that shouldn't run automatically.
# Also, it needs python installed, which may not be available on all
# installations.
generate:
	$(PYTHON) ivoatex/update_generated.py "$(DOCNAME).tex"

bib-suggestions: $(DOCNAME).pdf
	$(PYTHON) ivoatex/suggest-bibupgrade.py $(DOCNAME).aux

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
	$(PYTHON) ivoatex/submission.py $(versionedName).zip


#  Build TtH from source.  See http://hutchinson.belmont.ma.us/tth/.
#  TtH source seems to be highly portable, so compilation should be easy
#  as long as you have a C compiler.
$(TTH): ivoatex/tth_C/tth.c
	$(CC) -o $(TTH) ivoatex/tth_C/tth.c

############# architecture diagram stuff (to be executed in this directory)

ARCHDIAG_XSLT = make-archdiag.xslt

archdiag-l2.svg: archdiag-full.xml  $(ARCHDIAG_XSLT)
	$(XSLTPROC) -o $@ $(ARCHDIAG_XSLT) archdiag-full.xml

archdiag-debug.svg: archdiag-full.xml $(ARCHDIAG_XSLT)
	$(XSLTPROC) --stringparam WITHJS True -o $@ $(ARCHDIAG_XSLT) \
		archdiag-full.xml

archdiag-l1.svg: $(ARCHDIAG_XSLT)
	echo '<archdiag xmlns="http://ivoa.net/archdiag"/>' | \
		$(XSLTPROC) -o $@ $(ARCHDIAG_XSLT) -

archdiag-l0.svg: $(ARCHDIAG_XSLT)
	echo '<archdiag0 xmlns="http://ivoa.net/archdiag"/>' | \
		$(XSLTPROC) -o $@ $(ARCHDIAG_XSLT) -


############# below here: building an ivoatex distribution

IVOATEX_FILES = fromivoadoc.xslt Makefile COPYING \
	ivoabib.bib Makefile.template tthdefs.tex document.template \
	ivoa.cls README.rst  tth-ivoa.xslt IVOA.jpg docrepo.bib\
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
	scp $(IVOATEX_ARCHIVE) www.g-vo.org:/var/www/ivoatex/
	ssh www.g-vo.org "cd /var/www/ivoatex/; ln -sf $(IVOATEX_ARCHIVE) ivoatex-latest.tar.gz"

# re-gets the ivoa records from ADS
docrepo.bib:
	python3 fetch_from_ads.py

############# GitHub workflows configuration

.PHONY: github-preview

GITHUB_WORKFLOWS        = .github/workflows
GITHUB_BUILD            = $(GITHUB_WORKFLOWS)/build.yml
GITHUB_PREVIEW          = $(GITHUB_WORKFLOWS)/preview.yml
GITHUB_BUILD_TEMPLATE   = ivoatex/github_workflow_build.yml.template
GITHUB_PREVIEW_TEMPLATE = ivoatex/github_workflow_preview.yml.template

$(GITHUB_WORKFLOWS):
	@mkdir -p $@

$(GITHUB_BUILD): $(GITHUB_WORKFLOWS) $(GITHUB_BUILD_TEMPLATE)
	@sed "s!^\(\s*doc_name:\)!\1 $(DOCNAME)!g" $(GITHUB_BUILD_TEMPLATE) > $@
	@git add "$@"
	@echo -e "* GitHub Workflow for PDF preview in PullRequest configured:\n      $@"
	@echo '  => Run "git commit && git push" to enable GitHub PDF preview.'

$(GITHUB_PREVIEW): $(GITHUB_WORKFLOWS) $(GITHUB_PREVIEW_TEMPLATE)
	@sed "s!^\(\s*doc_name:\)!\1 $(DOCNAME)!g" $(GITHUB_PREVIEW_TEMPLATE) > $@
	@git add "$@"
	@echo -e "* GitHub Workflow for PDF preview at pushed commit configured:\n\
	        $@\n\
	  -----------------------------------------------------------------------\n\
	    Clickable badge toward the generated PDF preview:\n\n\
	        [![PDF-Preview](https://img.shields.io/badge/Preview-PDF-blue)]\
	(../../releases/download/auto-pdf-preview/$(DOCNAME)-draft.pdf)\n\n\
	    You can add it into your README.md to give an easy way to access\n\
	    the PDF preview to your users.\n\
	  -----------------------------------------------------------------------"
	@echo '  => Run "git commit && git push" to enable GitHub PDF preview.'

github-preview: $(GITHUB_BUILD) $(GITHUB_PREVIEW)


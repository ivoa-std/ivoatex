The ivoaTeX document preparation system
=======================================

IvoaTeX is a TeX-based software for authoring IVOA_ standards and
Notes. Authors are encouraged to use it in connection with a version
controlled repository.

The design goals are:

* version-controlled (or at least controllable) source file(s),
* reasonable-quality PDF and HTML output,
* low to moderate installation effort (on POSIX systems with LaTeX),
* support with routine drudgery.

.. _IVOA: https://www.ivoa.net


Getting ivoaTeX
---------------

IvoaTeX is designed to be included with the document source,
preferably via ``git submodule`` (or ``svn:externals``, though support
for that is waning quickly as ivoaTeX evolves).  See ivoatexDoc_ for
more information on how this is intended to work.

.. _ivoatexDoc: http://ivoa.net/documents/Notes/IVOATexDoc/

We occasionally make downloadable releases of ivoatex on
http://ivoatex.g-vo.org/.


Crib Sheet
----------

For your convenience (you should skim over the note anyway), here's a
few crib sheets on ivoaTeX operation.


Installing the dependencies
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Debian-derived systems::

  apt-get install build-essential texlive-latex-extra zip xsltproc\
    texlive-bibtex-extra latexmk librsvg2-bin ghostscript cm-super\
    librsvg2-bin

Fedora::

  dnf install texlive-scheme-full libxslt make gcc zip\
    librsvg2-tools ImageMagick ghostscript

Mac OS X with MacPorts::

  port install ImageMagick  libxslt ghostscript texlive +full


Checking Out a Standard from Github and Building it
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Documents developed on github can be built like this::

   git clone --recurse-submodules https://github.com/ivoa-std/ADQL
   cd ADQL
   make biblio
   make forcetex

This produces the standards document ``ADQL.pdf``.  If you have latexmk
installed, a simple ``make`` will work as well.

Automatic PDF preview in GitHub
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To enable the automatic generation of a PDF preview in GitHub::

   make github-preview
   git commit -m 'Add/Update GH-Workflows for PDF Preview'
   git push

Once the generated files pushed on GitHub, this will produce a PDF preview
after each pushed commit. This PDF will be available in the GitHub's
Pre-Release ``Auto PDF Preview``.

You may want to have a link toward this PDF preview. For this, you can add the
clickable badge returned by the ``make`` command into your ``README.md``.

A PDF preview is also generated at each update of a PullRequest. To get it,
go on the page of your PullRequest, click on the tab ``Checks`` and then on
``Artifacts``. This artifact will be automatically deleted after some time.


Documentation
-------------

Documentation on ivoatex, including a chapter on a quick start, is
given in the IVOA note `The IVOATeX Document Preparation System`_.

.. _The IVOATeX Document Preparation System: https://ivoa.net/documents/Notes/IVOATexDoc/


Trouble?
--------

In case of ivoatex-related issues, contact gavo@ari.uni-heidelberg.de,
or file an issue at github.


Acknowledgements
----------------

The immediate predecessor of this is the document generation system created
by Mark Taylor for SAMP and VOTable; essentially, this is a generalisation
of Mark's work.  This, in turn, built on work done by Sebastien Derriere.

Another inspiration was Paul Harrison's ivoadoc system; in particular,
parts of the XSL style sheet were taken from there, as well as the idea of
using svn:externals.

The document generation from XML schema files was adapted from XSLT
stylesheets written by Ray Plante.


Fonts
-----

The fonts embedded in the architecture diagram are derived from
Liberation Sans and Liberation Sans Mono in the following way::

  pyftsubset /usr/share/fonts/truetype/ttf-liberation/LiberationSansNarrow-Regular.ttf --unicodes="20,41-5a,61-7a" --output-file="lsn-sub.ttf"
  pyftsubset /usr/share/fonts/truetype/ttf-liberation/LiberationSans-Regular.ttf --unicodes="20,41-5a,61-7a" --output-file="ls-sub.ttf"

What is inserted into the CSS within the XSLT is then the output of::

  base64 -w0 ls-sub.ttf


License
-------

Unless stated otherwise in the files, ivoatex is (c) 2014-2022, the
GAVO project and can be used and distributed under the GNU General
Public License (ask for additional licenses if you're unhappy with the
GPL). See COPYING for details.

The files in ``tth_C`` have their own license.  See there for details.

The font excerpts in the architecture diagram are (C) 2007 Red Hat, Inc.
All rights reserved and are used in compliance with GPL exception (a)
in Red Hat's license agreement.

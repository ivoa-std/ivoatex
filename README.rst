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

.. _IVOA: http://www.ivoa.net


Getting ivoaTeX
---------------

IvoaTeX is designed to be included with the document source,
preferably via mechanisms of the version control system chosen (e.g.,
``svn:externals`` or ``git submodule``).


Crib Sheet
----------

For your convenience (you should skim over the note anyway), here's a
few crib sheets on ivoaTeX operation.


Installing the dependencies
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Debian-derived systems::

  apt-get install build-essential texlive-latex-extra zip xsltproc\
    texlive-bibtex-extra imagemagick ghostscript cm-super librsvg2-bin

Fedora::

  dnf install texlive-scheme-full libxslt make gcc zip\
    ImageMagick ghostscript

Mac OS X with MacPorts::

  port install ImageMagick  libxslt ghostscript texlive +full


Checking Out a Standard from Github and Building it
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

::

   git clone --recurse-submodules https://github.com/ivoa-std/ADQL
   cd ADQL
   make biblio
   make forcetex

This produces the standards document ``ADQL.pdf``.


Documentation
-------------

Documentation on ivoatex, including a chapter on a quick start, is
given in the IVOA note `The IVOATeX Document Preparation System`_.

.. _The IVOATeX Document Preparation System: http://ivoa.net/documents/Notes/IVOATex/index.html



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

Unless stated otherwise in the files, ivoatex is (c) 2014-2015, the
GAVO project and can be used and distributed under the GNU General
Public License (ask for additional licenses if you're unhappy with the
GPL). See COPYING for details.

The files in ``tth_C`` have their own license.  See there for details.

The font excerpts in the architecture diagram are (C) 2007 Red Hat, Inc.
All rights reserved and are used in compliance with GPL exception (a)
in Red Hat's license agreement.

=======================
ivoaTeX Regression Test
=======================

To give the maintainers of ivoaTeX_ a bit more confidence when doing
changes, this is a regression test that goes through the motions of
starting a document and building it, exercising as many of the features
mentioned in ivoatexDoc as I can.

To see if you have broken anything, just commit your changes into a
branch and run::

  python run-regression.py --branch <your-branch-name>

By default, run-regression will exercise the master branch.

See the docstring in run-regression.py on how to add to the tests.

Maintained by Markus Demleitner <msdemlei@ari.uni-heidelberg.de>

Distributed under CC0 by the IVOA.

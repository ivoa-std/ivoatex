#!/bin/sh
# A script to copy templates from ivoatex when starting a document.

if [ $# -ne 1 ]; then
	echo "Usage: startup.sh <document base name>"
	echo "This is used to initialise the document directory for an"
	echo "iovatex document.  See ivoatexDoc for details."
	exit 1
fi

copyAndAdd() {
	# copies $1 to $2 if $2 does not exist.  Also adds $2 to git in that case.
	if [ ! -f "$2" ]; then
		cp "$1" "$2"
		git add "$2"
	fi
}


copyAndAdd ivoatex/document.template "$1.tex"
copyAndAdd ivoatex/Makefile.template Makefile
copyAndAdd ivoatex/svn-ignore.txt .gitignore
copyAndAdd ivoatex/readme-template.rst README.rst
copyAndAdd ivoatex/license-template.txt LICENSE

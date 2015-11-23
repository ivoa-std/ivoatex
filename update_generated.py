#!/usr/bin/env python
# Update all generated sections in a text file.
#
# This is part of ivoatex.  See COPYING for the license.
#
# Generarated sections are between % GENERATED: <command> 
# and % /GENERATED.  They are supposed to contain the output of
# <command>.  <command> get shell-expanded, but since it gets executed
# anyway, it's not even worth doing shell injection.
#
# When this script finishes, it either has updated all sections or
# stopped with an error message of a failed command, in which case the
# original file is unchanged.

import re
import subprocess
import sys


class ExecError(Exception):
	def __init__(self, command, stderr):
		Exception.__init__(self, "Failed command %s"%repr(command))
		self.command, self.stderr = command, stderr


def processOne(matchObj):
	command = matchObj.group("command")
	print "Executing %s"%command
	f = subprocess.Popen(command, shell=True,
		stdout=subprocess.PIPE, stderr=subprocess.PIPE,
		close_fds=True, bufsize=-1)
	stdout, stderr = f.communicate()

	if f.returncode!=0:
		raise ExecError(command, stderr)
	return ("%% GENERATED: %s\n"%(command.strip())
		+stdout
		+"\n% /GENERATED")


def processAll(content):
	return re.sub(r"(?sm)^%\s+GENERATED:\s+(?P<command>.*?)$"
		".*?"
		r"%\s+/GENERATED", 
		processOne,
		content)


def parseCommandLine():
	import argparse
	parser = argparse.ArgumentParser(description="Update generated content"
		" in a text file")
	parser.add_argument("filename", action="store", type=str,
		help="File to process (will be overwritten).")
	return parser.parse_args()


def main():
	args = parseCommandLine()
	with open(args.filename) as f:
		content = f.read()
	
	try:
		content = processAll(content)
	except ExecError, ex:
		sys.stderr.write("Command %s failed.  Message below.  Aborting.\n"%
			ex.command)
		sys.stderr.write(ex.stderr+"\n")
		sys.exit(1)
	
	with open(args.filename, "w") as f:
		f.write(content)


if __name__=="__main__":
	main()

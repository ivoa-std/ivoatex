#!/usr/bin/env python

"""
A little script to operate the IVOA submission form with data scrubbed
from ivoatex sources.

The keys used here are taken from screen-scraping 
http://www.ivoa.net/cgi-bin/up.cgi (which is also the target to POST
to).

Fields needed:

* doctitle
* conciseName
* email
* filename
* author
* editor
* abstract
* comment

* group (one of app, dal, dm, gws, reg, dcp, std, semantics, the, voe, vot,
  voq)
* docver1, docver2
* year, month, day
* doctype (one of note, wd, pr, rec, other)
"""

import pprint
import os
import re
import subprocess
import sys
import tempfile
from xml.etree import ElementTree as etree

try:
	import requests
except ImportError:
	sys.exit("*** Automatic document submission needs python-requests.\n"
		"*** Install a package named like this or get it from\n"
		"*** https://pypi.python.org/pypi/requests")


DOCREPO_URL = 'http://www.ivoa.net/cgi-bin/up.cgi' 


class ReportableError(Exception):
	"""raise this with a human-readable error message to cause a non-traceback
	program exit.
	"""

def H(el_name):
	"""returns an XHTML 1.0 Qname for el_name.
	"""
	return etree.QName("http://www.w3.org/1999/xhtml", el_name)


def to_text(el):
	"""returns a concatenation of the text contents of el and its sub-elements.
	"""
	return "".join(el.itertext()).strip().encode("utf-8")


class DocumentMeta(object):
	"""a blackboard to collect the various pieces of information on the
	document.

	For now, we just use attributes named like the fields in the
	IVOA docrepo API.
	"""
	_attrs = ["doctitle", "conciseName", "email",
		"author", "editor", "abstract",
		"comment", "group", "docver1", "docver2",
		"year", "month", "day", "doctype"]
	
	def __init__(self, **kwargs):
		for k, v in kwargs.iteritems():
			setattr(self, k, v)
		self._authors = []
		self._editors = []
		self.group = None
		self.comment = ""

	def get_post_payload(self):
		"""returns a dictionary ready to post with requests.
		"""
		payload = {}
		for name in self._attrs:
			if not hasattr(self, name):
				raise ReportableError("Metadata item %s missing.\n This usually"
					" is because the generated HTML is bad."%name)
			payload[name] = getattr(self, name)
		return payload

	def get_date(self):
		"""returns the document date in ISO format.
		"""
		return "%s-%s-%s"%(self.year, self.month, self.day)

	def add_info_from_document(self):
		"""tries to obtain missing metadata from the formatted (XHTML) source.
		"""
		with open(self.conciseName+".html") as f:
			tree = etree.parse(f)

		# The following would be a bit smoother if we had xpath; there's
		# no xpath engine in the stdlib, though (and no BeautifulSoup),
		# so let's do a bit of manual work rather than pull in a fat
		# dependency.

		# first h1 is the document title
		for el in tree.iter(H("h1")):
			self.doctitle = to_text(el)
			break

		# pull things with ids or unique classes
		for el in tree.iter():
			if el.get("id")=="abstract":
				# first element currently is an h2 with text "Abstract".
				# actual content is in the element tail.  Ugh.  This needs
				# cleanup.
				el[0].text = ""
				self.abstract = to_text(el)
			elif el.get("id")=="ivoagroup":
				self.group = self._get_wg_code(to_text(el))
			elif el.get("class")=="author":
				self._authors.append(to_text(el))
			elif el.get("class")=="editor":
				self._editors.append(to_text(el))

	@property
	def author(self):
		return ", ".join(self._authors)

	@property
	def editor(self):
		return ", ".join(self._editors)

	@classmethod
	def from_makefile(cls):
		"""creates a basic document meta with attributes obtainable
		from the makefile filled in.
		"""
		meta_keys = {}
		with open("Makefile") as f:
			for ln in f:
				mat = re.match("(\w+)\s*=\s*(.*)", ln)
				if mat:
					meta_keys[mat.group(1)] = mat.group(2)
		
		kwargs = {}
		for input_key, parser_function in [
				("DOCNAME", lambda v: [("conciseName", v.strip())]),
				("DOCVERSION", cls._parse_DOCVERSION),
				("DOCDATE", cls._parse_DOCDATE),
				("AUTHOR_EMAIL", cls._parse_AUTHOR_EMAIL),
				("DOCTYPE", lambda v: [("doctype", v.strip().lower())])]:
			if input_key not in meta_keys:
				raise ReportableError("%s not defined/garbled in Makefile"
					" but required for upload."%input_key)
			kwargs.update(
				dict(parser_function(meta_keys[input_key])))

		##### Temporary HACK: map pen to other:
		kwargs["doctype"] = {"pen": "other"}.get(kwargs["doctype"], kwargs["doctype"])
		res = cls(**kwargs)

		if "IVOA_GROUP" in meta_keys:
			res.group = res._get_wg_code(meta_keys["IVOA_GROUP"])

		return res

	_wg_mapping = {
		"Applications": "app",
 	 	"DAL": "dal",
 	 	"Data Access Layer": "dal",
 	 	"Data Models": "dm",
 	 	"Grid and Web Services": "gws",
 	 	"Registry": "reg",
 	 	"Data Curation and Preservation": "dcp",
 	 	"Documents and Standards": "std",
 	 	"Standards and Processes": "std",
 	 	"Semantics": "semantics",
 	 	"Theory": "the",
 	 	"VO Event": "voe",
 	 	"Time Domain": "voe",
 	 	"Education": "edu",
 	 	"No Group": "none",
 	 }

	def _get_wg_code(self, wg_string):
		"""returns one of the docrepo codes for the ivoa WGs.

		This will look at wg_string only if self.group isn't already
		set (in which case self.group is simply returned); this allows
		overriding the WG name in the Makefile if necessary.
		"""
		if self.group:
			return self.group
		if wg_string not in self._wg_mapping:
			raise ReportableError("ivoagroup must be one of %s.  If this is"
				" really inappropriate, set IVOA_GROUP =No Group in the Makefile"%
				", ".join(self._wg_mapping.keys()))
		return self._wg_mapping[wg_string]

	@staticmethod
	def _parse_DOCVERSION(version_string):
		"""helps from_makefile by returning form keys from the document version.
		"""
		mat = re.match("(\d).(\d+)", version_string)
		if not mat:
			raise ReportableError("DOCVERSION in Makefile (%s) garbled."%
				version_string)
		yield "docver1", mat.group(1)
		yield "docver2", mat.group(2)

	@staticmethod
	def _parse_DOCDATE(date_string):
		"""helps from_makefile by returning form keys from the document date.
		"""
		mat = re.match("(\d\d\d\d)-(\d\d)-(\d\d)", date_string)
		if not mat:
			raise ReportableError("DOCDATE in Makefile (%s) garbled."%
				date_string)

		yield "year", mat.group(1)
		yield "month", mat.group(2)
		yield "day", mat.group(3)

	@staticmethod
	def _parse_AUTHOR_EMAIL(email_string):
		"""helps from_makefile by returning a form key for the email.
		"""
		yield "email", email_string


def review_and_comment(document_meta):
	"""prints document_meta and lets the user add a remark if they want.
	"""
	editor = os.environ.get("VISUAL", 
		os.environ.get("EDITOR", "nano"))

	fd, path_name = comment_src = tempfile.mkstemp()
	try:
		os.write(fd, "# optionally enter comment(s) below.\n")
		os.close(fd)
		subprocess.check_call([editor, path_name])
		with open(path_name) as f:
			document_meta.comment = re.sub("(?m)^#.*$", "", f.read())
	finally:
		os.unlink(path_name)

	pprint.pprint(document_meta.get_post_payload())
	print("-----------------------\n")
	print("Going to upload %s\n"%document_meta.doctitle)
	print("*** Version: %s.%s, %s of %s ***\n"%(
		document_meta.docver1,
		document_meta.docver2,
		document_meta.doctype, 
		document_meta.get_date()))
	print("Hit ^C if this (or anthing in the dict above) is wrong,"
		" enter to upload.")
	raw_input()


def main(archive_file_name):
	document_meta = DocumentMeta.from_makefile()
	document_meta.add_info_from_document()
	review_and_comment(document_meta)
	sys.stdout.write("Uploading... ")
	sys.stdout.flush()

	with open(sys.argv[1]) as upload:
		resp = requests.post(DOCREPO_URL, 
			data=document_meta.get_post_payload(),
			files=[('filename', (sys.argv[1], upload))])

	sys.stdout.write("done (result in docrepo-response.html)\n")
	with open("docrepo-response.html", "w") as f:
		f.write(resp.text)


if __name__=="__main__":
	try:
		if len(sys.argv)!=2:
			raise ReportableError(
				"Usage: %s <upload package file name>"%sys.argv[0])
		main(sys.argv[1])
	except ReportableError, msg:
		sys.stderr.write("*** Failure while preparing submission:\n")
		sys.exit(msg)

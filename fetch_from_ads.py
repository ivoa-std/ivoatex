"""
A script to fetch the IVOA records from ADS using the ADS API.

You'll need to get an ADS API key (see
https://github.com/adsabs/adsabs-dev-api) to run this and put it into the
environment variable ADS_TOKEN.

If successful, it will write BibTeX to docrepo.bib (as needed by ivoatex).

Copyright 2020, the GAVO project

This is part of ivoatex, covered by the GPL.  See COPYING for details.
"""

import json
import os
from urllib import parse, request

API_URL = "https://api.adsabs.harvard.edu/v1/"

try:
    ADS_TOKEN = os.environ["ADS_TOKEN"]
except KeyError:
    sys.exit("No ADS_TOKEN defined.  Get an ADS API key and put it there.")


def do_api_request(_path, _payload=None, **arguments):
    """returns the json-decoded result of an ADS request to path with
    arguments.

    path is relative to API_URL.
    """
    # Yeah, I know, I could save this with requests; but it'd be an
    # extra dependency, and avoiding that is worth a few lines.
    auth_header = {"Authorization": "Bearer:%s"%ADS_TOKEN}
    req = request.Request(
        API_URL+_path+"?"+parse.urlencode(arguments),
        _payload,
        auth_header)
    f = request.urlopen(req)
    return json.load(f)


def main():
    bibcode_recs = do_api_request("search/query/", 
        q="bibstem:(ivoa.spec or ivoa.rept)",
        rows="500",
        fl="bibcode")
    
    bibtex_args = {
        "bibcode": [r["bibcode"] for r in bibcode_recs["response"]["docs"]],}
    bibtex_recs = do_api_request("export/bibtex",
        _payload=json.dumps(bibtex_args).encode("ascii"))
    with open("docrepo.bib", "w") as f:
        f.write(bibtex_recs["export"])


if __name__=="__main__":
    main()
# vi:sw=4:et:sta

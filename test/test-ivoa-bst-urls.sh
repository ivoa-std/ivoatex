#! /bin/sh -

name=test-ivoa-bst-urls

BSTINPUTS=.. bibtex $name >$name.stdout
#grep -Ei '(harvarditem|doi|url)' $name.bbl >$name.out
#mv $name.bbl $name.out

status=0

if diff $name.good $name.bbl >$name.diff; then
    echo "$0 good"
    for e in bbl blg diff stdout; do rm $name.$e; done
else
    echo "$0 failed: diffs in $name.diff"
    status=1
fi

exit $status

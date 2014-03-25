#!/bin/bash

# Check that the languages/ dir exists
if [ ! -d "languages/" ]; then
  echo "You need to run this script from the root of the Ebooksforlib folder, not from inside bin/."
  exit
fi

xgettext.pl -D=views -D=lib -o="languages/en.po" -v -v -v
xgettext.pl -D=views -D=lib -o="languages/no.po" -v -v -v

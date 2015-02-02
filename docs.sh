#!/bin/bash

#perl -n -e 'if (/^#include "(.*)"/) { print `cat $1` } else { print }' extra/index.md > index.md
docco -o docs/linear Report.md -l linear
sed 's/<link \(.*\) href="/<link \1 href="docs\/linear\//' docs/linear/Report.html > Report.html
rm -f docs/linear/Report.html

docco Makefile
docco src/*

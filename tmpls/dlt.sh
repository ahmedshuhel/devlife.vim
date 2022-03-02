#!/bin/sh

DATE=$(date '+%Y-%m-%d')
cat  << EOF
# $DATE

- [Previous]($1)

## Tasks
EOF

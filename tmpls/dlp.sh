#!/bin/sh

TITLE=$1
DATE=$(date '+%Y-%m-%d')

cat << EOF
---
subject: $TITLE
state: draft
tags:
 - idea
---
# $TITLE

## Outline

- TBD
EOF

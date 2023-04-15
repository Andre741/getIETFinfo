#!/bin/bash

###
### GETRFCTYPE - Figure out if this RFC is real or one of the non-issued ones
###
### Version 2.0.1
###
### Written in 2005-2007 by Jari Arkko
### Donated to the public domain.
###

for f in $*
do
  if [ -s $f ]
  then
    i=/tmp/$$.tmp
    rm -f $i
    head -2 $f > $i
    if fgrep 'was never issued' $i > /dev/null
    then
      type=notissued
    else
      type=published
    fi
    rm -f $i
  else
    type=empty
  fi
  echo $f:$type
done

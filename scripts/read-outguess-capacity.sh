#!/bin/sh

## Usage:
##   outguess -k pass -d message.txt cover.jpg stego.jpg | sh this-script.sh`
##  Outputs the capacity in bytes.

bits=`sed -nr 's/Extracting usable bits:   ([[:digit:]]+) bits/\1/p'`
expr $bits / 8  # convert to bytes

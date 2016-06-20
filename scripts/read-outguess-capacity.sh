#!/bin/sh

## Usage:
##   `outguess -k pass -d message.txt cover.jpg stego.jpg 2>&1 | sh this-script.sh`
##  Outputs the capacity in bytes. Remember to redirect stderr.

bits=`sed -nr 's/Extracting usable bits:   ([[:digit:]]+) bits/\1/p'`
expr $bits / 8  # convert to bytes

#!/bin/sh

## Usage:
##   `steghide info file.jpg -p password 2>/dev/null | sh this-script.sh`
##  Outputs the capacity in bytes.

KB=`sed -nr 's/ +capacity: ([[:digit:]]+),[[:digit:]]+ KB/\1/p'`
expr $KB '*' 1000  # convert to bytes

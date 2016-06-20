#!/bin/sh

## Usage:
##   `steghide info file.jpg | sh this-script.sh`
##  Outputs the capacity in bytes.

KB=`sed -nr 's/ +capacity: ([[:digit:]]+),0 KB/\1/p'`
expr $KB '*' 1000  # convert to bytes

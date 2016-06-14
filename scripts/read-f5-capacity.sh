#!/bin/sh

## Usage:
##   `java -jar 5.jar e -e message.txt cover.jpg stego.jpg | sh this-script.sh`
##  Outputs the capacity in bytes.

sed -nr 's/default code: ([[:digit:]]+) bytes \(efficiency: 1.1 bits per change\)/\1/p'

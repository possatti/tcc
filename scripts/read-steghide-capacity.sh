#!/bin/sh

KB=`sed -nr 's/ +capacity: ([[:digit:]]+),0 KB/\1/p'`
expr $KB '*' 1000  # convert to bytes

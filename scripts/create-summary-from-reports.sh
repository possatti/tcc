#!/usr/bin/env bash

## Set some bash options.
##  - http://kvz.io/blog/2013/11/21/bash-best-practices/
set -o errexit  # make script exit when a command fails.
set -o nounset  # exit when script tries to use undeclared variables.
#set -o xtrace   # trace what gets executed.

# Displays usage and quit with error.
usage() {
  echo " Usage: $0 <REPORTS_DIR>"
  echo
  echo ' Description:'
  echo "   Process StegExpose reports to make a small summary."
  echo
  echo ' Arguments:'
  echo '   REPORTS_DIR - Path to where the reports are.'
  echo
  echo ' Options:'
  echo '   -h --help'
  echo '      Shows the usage.'
  exit 1
}

# Parse options and arguments.
ARGUMENTS_COUNT=0
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
        usage
        ;;
    *)
        ARGUMENTS_COUNT=$(( $ARGUMENTS_COUNT + 1 ))
        ARGUMENTS[$ARGUMENTS_COUNT]="$1"
        shift 1
        ;;
  esac
done

# Check whether we've got the right number of arguments
[ "$ARGUMENTS_COUNT" -eq "1" ] || usage

# Assign arguments to variables.
REPORTS_DIR="${ARGUMENTS[1]}"

PERCENTAGES="10 20 30 40 50 60 70 80 90 100"
TOOLS="f5 steghide outguess stepic lsbsteg"

# Prints header.
echo -n ","
for TOOL in $TOOLS; do
  echo -n "$TOOL,"
done
echo

# Prints number of detected clean images, for each tool.
echo -n "0%,"
DETECTED_CLEAN_JPG=$(cat "$REPORTS_DIR/clean-jpeg.csv" | grep "true" | wc -l)
TOTAL_CLEAN_JPG=$(cat "$REPORTS_DIR/clean-jpeg.csv" | grep "jpg" | wc -l)
echo -n "$DETECTED_CLEAN_JPG de $TOTAL_CLEAN_JPG,"
echo -n "$DETECTED_CLEAN_JPG de $TOTAL_CLEAN_JPG,"
echo -n "$DETECTED_CLEAN_JPG de $TOTAL_CLEAN_JPG,"
DETECTED_CLEAN_PNG=$(cat "$REPORTS_DIR/clean-png.csv" | grep "true" | wc -l)
TOTAL_CLEAN_PNG=$(cat "$REPORTS_DIR/clean-png.csv" | grep "png" | wc -l)
echo -n "$DETECTED_CLEAN_PNG de $TOTAL_CLEAN_PNG,"
echo -n "$DETECTED_CLEAN_PNG de $TOTAL_CLEAN_PNG,"
echo


for PERCENTAGE in $PERCENTAGES; do
  # Prints percentages at the side.
  echo -n "$PERCENTAGE%,"

  # Print values for each report.
  for TOOL in $TOOLS; do
    # Number of total analysed images for that percentage and tool.
    TOTAL=$(cat "$REPORTS_DIR/$TOOL.csv" | sed -nr "/^.*${PERCENTAGE}p.*$/p" | wc -l)
    # Number of detected images for that percentage and tool.
    DETECTED=$(cat "$REPORTS_DIR/$TOOL.csv" | sed -nr "/^.*${PERCENTAGE}p.*true/p" | wc -l)
    echo -n "$DETECTED de $TOTAL,"
  done
  echo
done

#!/bin/sh

##
## Description:
##   This script converts JPEG images into PNG images.
##

usage() {
	echo "Usage:"
	echo "  sh convert-jpg-png.sh IMAGE [IMAGE...] [-o OUTPUT_DIR]"
	echo ""
	echo "Arguments"
	echo "  IMAGE: JPEG image to be converted to PNG."
	echo ""
	echo "Options:"
	echo "  -o --output OUTPUT_DIR"
	echo "    Output images to this location."
	exit
}

err() {
	echo "convert-jpg-png.sh: $@" 1>&2
}

# Print usage if there are no args.
if [ -z "$1" ]; then
	usage
fi

# Default variables.
OUTPUT_DIR=`pwd`
IMAGES=""

# Parse arguments.
while [ -n "$1" ]; do
	case "$1" in
		-h|--help)
			usage
			;;
		-o|--output)
			shift
			OUTPUT_DIR=$1
			;;
		*)
			IMAGES="$IMAGES $1"
	esac
	shift
done

# Filter JPG images.
JPG_IMAGES=""
for IMAGE in $IMAGES; do
	if echo $IMAGE | grep "\.[Jj][Pp][Gg]$" > /dev/null ; then
		JPG_IMAGES="$JPG_IMAGES $IMAGE"
	else
		err "'$IMAGE' is not a JPG."
	fi
done

# Create directory if it doesn't exist already.
mkdir $OUTPUT_DIR -p

# Convert images.
err "Outputing PNG images into '$OUTPUT_DIR'"
for JPG in $JPG_IMAGES; do
	PNG_NAME=` echo "$JPG" | sed -r 's;.jpe?g;.png;' `
	err "Converting '$JPG' into '$PNG_NAME'"
	convert "$JPG" "$OUTPUT_DIR/$PNG_NAME"
done

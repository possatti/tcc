#!/usr/bin/env bash

##
## Create 4 files containing ~1%, 25%, 50% and 90% of the image capacity,
## using the specified algorithm.
##

# Displays usage and quit.
usage() {
  echo " Usage: $0 <algorithm> <image_path> <output_dir> [-h] [-d]"
  echo
  echo ' Arguments:'
  echo '   image_path - Path to the clean image.'
  echo '   algorithm - One of these: [f5, outguess, steghide, stepic].'
  echo '   output_dir - Where the resulting stego-images should be placed.'
  echo
  echo ' Options:'
  echo '   -h --help'
  echo '      Shows the usage.'
  echo '   -d --debug'
  echo '      Enables debugging.'
  exit
}

# Outputs arguments to stdout.
info() {
  local NOW=$(date +"%F %T")
  echo "[$NOW] INFO  $@"
}

# Outputs arguments to stderr.
err() {
  local NOW=$(date +"%F %T")
  echo "[$NOW] ERROR  $@" 1>&2
}

# Outputs debugging info to stderr.
debug() {
  if [[ $DEBUG ]]; then
    local NOW=$(date +"%F %T")
    echo "[$NOW] DEBUG  $@" 1>&2
  fi
}

# Parse options and arguments.
ARGUMENTS_COUNT=0
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -d|--debug)
            DEBUG=true
            shift 1
            ;;
        *)
            ARGUMENTS_COUNT=$(( $ARGUMENTS_COUNT + 1 ))
            ARGUMENTS[$ARGUMENTS_COUNT]="$1"
            shift 1
            ;;
    esac
done

# Check wether we've got the right number of arguments
[ "$ARGUMENTS_COUNT" -eq "3" ] || usage

# Assign arguments to variables.
ALGORITHM="${ARGUMENTS[1]}"
IMAGE_PATH="${ARGUMENTS[2]}"
OUTPUT_DIR="${ARGUMENTS[3]}"

# Set password that will be used for all steganography tools.
PASSWORD="steganography123"

# Declare a tiny secret message that will be used for checking the
# steganographic capacity of images.
TESTING_MESSAGE="Why a raven is like a writing desk?"

# Debug arguments info.
debug '$ALGORITHM:' "$ALGORITHM"
debug '$IMAGE_PATH:' "$IMAGE_PATH"
debug '$OUTPUT_DIR:' "$OUTPUT_DIR"

# Shortcuts for steganography tools that are not present in $PATH.
shopt -s expand_aliases
alias f5="java -jar tools/f5.jar"

# Check wether the steganography tool needed is present.
type "$ALGORITHM" >/dev/null 2>&1 || { err "$ALGORITHM is not installed. Aborting."; exit 1; }

exit

# Embeds a message file into the cover image.
# Arguments: <COVER_PATH> <STEGO_PATH> <MESSAGE_PATH>
outguess_embed() {
  local COVER_PATH="$1"
  local STEGO_PATH="$2"
  local MESSAGE_PATH="$3"

  outguess "$COVER_PATH" "$STEGO_PATH" -d "$MESSAGE_PATH" -k "$PASSWORD"
}

# Extracts the hidden message from the stego file.
# Usage: extract <STEGO_FILE> <EXTRACTED_MESSAGE_PATH>
outguess_extract() {
  local STEGO_FILE="$1"
  local EXTRACTED_MESSAGE_PATH="$2"

  outguess -r "$STEGO_FILE" "$EXTRACTED_MESSAGE_PATH" -k "$PASSWORD"
}

# Outputs the image's steganographic capacity (in bytes).
# Arguments: <IMAGE_PATH>
outguess_capacity() {
  local IMAGE_PATH=$1
  local TEMP_STEGO_PATH="temp_stego_image.jpg"
  local TEMP_MESSAGE_PATH="temp_message.txt"
  echo $TESTING_MESSAGE > $TEMP_MESSAGE_PATH

  local EMBEDDING_OUTPUT=$(embed $IMAGE_PATH $TEMP_STEGO_PATH $TEMP_MESSAGE_PATH 2>&1)
  echo "EMBEDDING_OUTPUT: $EMBEDDING_OUTPUT" 1>&2
  local BITS=$(echo $EMBEDDING_OUTPUT | sed -nr 's/Correctable message size: ([[:digit:]]+) bits, .*%/\1/p')
  echo "BITS: $BITS" 1>&2
  expr $BITS '/' 8
}

# Checks it the stego-image contains the proper hidden message.
# Usage: check <EXTRACTING_COMMAND> <STEGO_FILE_PATH> <EXPECTED_MESSAGE_PATH>
check() {
  local EXTRACTING_COMMAND=$1
  local STEGO_FILE_PATH=$2
  local EXPECTED_MESSAGE_PATH=$3
  local TEMP_MESSAGE_PATH="temp_extracted_$IMAGE_PATH.txt"

  extract $STEGO_FILE_PATH $TEMP_MESSAGE_PATH

  diff --brief $TEMP_MESSAGE_PATH $EXPECTED_MESSAGE_PATH
  if [ "$?" -eq 1 ]; then
    err "'$STEGO_FILE_PATH' does not have the proper hidden message!"
    err "Expected: '$EXPECTED_MESSAGE_PATH'."
    err "Got: '$TEMP_MESSAGE_PATH'."
    exit 1
  fi

  rm $TEMP_MESSAGE_PATH
}

# Usage: create_name <OLD_NAME> <PERCENTAGE>
create_name() {
  local OLD_NAME=$(basename $1)
  local PERCENTAGE=$2
  echo $OLD_NAME | sed -r "s;(.+)\.(.+);\1_${PERCENTAGE}p.\2;"
}

# Usage: do_embed <PERCENTAGE>
do_embed() {
  local PERCENTAGE=$1
  local TEMP_MESSAGE_PATH="temp_message.txt"

  info "Embedding ${PERCENTAGE}% of '$IMAGE_PATH' capacity..."
  NUMBER_BYTES=$(echo "$CAPACITY * $PERCENTAGE / 100" | bc)
  head -c $NUMBER_BYTES $MERGED_BOOKS_PATH > $TEMP_MESSAGE_PATH
  NEW_NAME=$(create_name $IMAGE_PATH)
  STEGO_PATH=$OUTPUT_DIR/$NEW_NAME

  info "Embedding $NUMBER_BYTES bytes into image and saving to '$STEGO_PATH'..."
  embed $IMAGE_PATH $STEGO_PATH $TEMP_MESSAGE_PATH

  info "Checking whether '$STEGO_PATH' contains the proper message..."
  check $STEGO_PATH $TEMP_MESSAGE_PATH
  rm $TEMP_MESSAGE_PATH
}

# Create files with ~1%, 25%, 50% and 90% of the image capacity.
do_all_embedding() {
  EMBEDING_FUNCTION=$1
  EXTRACTING_FUNCTION=$2
  CAPACITY_FUNCTION=$3

  info "Working on '$IMAGE_PATH'..."
  mkdir -p $OUTPUT_DIR
  CAPACITY=$(capacity $IMAGE_PATH)
  debug "CAPACITY: $CAPACITY"
  info "Esteganographic capacity for '$IMAGE_PATH' is $CAPACITY bytes."

  # 25% of book
  do_embed 1
  do_embed 25
  do_embed 50
  do_embed 90

  info "All done for '$IMAGE_PATH'."
}

do_all_embedding

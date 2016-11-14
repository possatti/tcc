#!/usr/bin/env bash

##
## Create 4 files containing ~1%, 25%, 50% and 90% of the image capacity,
## using the specified algorithm.
##

# Set some bash options.
#  - http://kvz.io/blog/2013/11/21/bash-best-practices/
set -o errexit  # make script exit when a command fails.
set -o nounset  # exit when script tries to use undeclared variables.
#set -o xtrace   # trace what gets executed.

# Displays usage and quit.
usage() {
  echo " Usage: $0 <ALGORITHM> <IMAGE_PATH> <OUTPUT_DIR> [-h] [-d] [-l FILE]"
  echo
  echo ' Arguments:'
  echo '   ALGORITHM - One of these: [f5, outguess, steghide, stepic].'
  echo '   IMAGE_PATH - Path to the clean image.'
  echo '   OUTPUT_DIR - Where the resulting stego-images should be placed.'
  echo
  echo ' Options:'
  echo '   -h --help'
  echo '      Shows the usage.'
  echo '   -d --debug'
  echo '      Enables debugging.'
  # echo '   -l --log  FILE'
  # echo '      Log messages to the specified file path.'
  exit
}

# Outputs arguments to stdout.
info() {
  local NOW=$(date +"%F %T")
  echo "[$NOW] INFO  $@"
}

# Outputs arguments to stderr and quit.
err() {
  local NOW=$(date +"%F %T")
  echo "[$NOW] ERROR  $@" 1>&2
  exit 1
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

# Check whether we've got the right number of arguments
[ "$ARGUMENTS_COUNT" -eq "3" ] || usage

# Assign arguments to variables.
ALGORITHM="${ARGUMENTS[1]}"
IMAGE_PATH="${ARGUMENTS[2]}"
OUTPUT_DIR="${ARGUMENTS[3]}"

# Set password that will be used for all steganography tools.
PASSWORD="steganography123"

# Set where the file containg the books are.
MERGED_BOOKS_PATH="messages/books.txt"

# Declare a tiny secret message that will be used for checking the
# steganographic capacity of images.
TESTING_MESSAGE="Why a raven is like a writing desk?"

# Debug arguments info.
debug "ALGORITHM: $ALGORITHM"
debug "IMAGE_PATH: $IMAGE_PATH"
debug "OUTPUT_DIR: $OUTPUT_DIR"

# Shortcuts for steganography tools that are not present in $PATH.
shopt -s expand_aliases
alias f5="java -jar tools/f5.jar"

# Check whether the steganography tool needed is present.
type "$ALGORITHM" >/dev/null 2>&1 || \
  err "$ALGORITHM is not installed. Aborting."

# Check whether the cover image really exists
[ -f "$IMAGE_PATH" ] || err "The image file doesn't exist!"

# Create the output directory, if it doesn't exist
mkdir -p "$OUTPUT_DIR" || \
  err "The output directory doesn't exist and could not be created!"

# Embeds a message file into the cover image.
# Arguments: <COVER_PATH> <STEGO_PATH> <MESSAGE_PATH>
outguess_embed() {
  local COVER_PATH="$1"
  local STEGO_PATH="$2"
  local MESSAGE_PATH="$3"

  outguess "$COVER_PATH" "$STEGO_PATH" -d "$MESSAGE_PATH" -k "$PASSWORD"
}

## Test outguess_extract function.
# echo "I don't know..." > "test-message.tmp.jpg"
# outguess_embed "$IMAGE_PATH" "stego-test.tmp.jpg" "test-message.tmp.jpg"
# info "Embedding test finished."
# exit

# Extracts the hidden message from the stego file.
# Usage: extract <STEGO_FILE> <OUTPUT_MESSAGE_PATH>
outguess_extract() {
  local STEGO_FILE="$1"
  local OUTPUT_MESSAGE_PATH="$2"

  outguess -r "$STEGO_FILE" "$OUTPUT_MESSAGE_PATH" -k "$PASSWORD"
}

## Test outguess_embed function.
# outguess_extract "stego-test.tmp.jpg" "extracted-message.tmp.txt"
# info "Extraction test finished."
# exit


# Outputs the image's steganographic capacity (in bytes).
# Arguments: <IMAGE_PATH>
outguess_capacity() {
  local IMAGE_PATH="$1"
  local TEMP_STEGO_PATH="stego-image.tmp.jpg"
  local TEMP_MESSAGE_PATH="message.tmp.txt"
  echo "$TESTING_MESSAGE" > "$TEMP_MESSAGE_PATH"

  local EMBEDDING_OUTPUT=$(outguess_embed "$IMAGE_PATH" "$TEMP_STEGO_PATH" "$TEMP_MESSAGE_PATH" 2>&1)
  debug "EMBEDDING_OUTPUT: $EMBEDDING_OUTPUT"
  local BITS=$(echo "$EMBEDDING_OUTPUT" | sed -nr 's/Correctable message size: ([[:digit:]]+) bits, .*%/\1/p')
  debug "BITS: $BITS"
  bc <<< "$BITS / 8"

}

## Test capacity function.
# outguess_capacity "$IMAGE_PATH"
# info "Capacity test finished."
# exit


# Checks it the stego-image contains the proper hidden message. If it doesn't
# contain the proper message, that script is halted with an error message. If
# it contains the correct message, then everything resumes as usual.
# Arguments: <EXTRACTING_COMMAND> <STEGO_FILE_PATH> <EXPECTED_MESSAGE_PATH>
check() {
  local EXTRACTING_COMMAND="$1"
  local STEGO_FILE_PATH="$2"
  local EXPECTED_MESSAGE_PATH="$3"
  local TEMP_MESSAGE_PATH="extracted-message.tmp.txt"

  "$EXTRACTING_COMMAND" "$STEGO_FILE_PATH" "$TEMP_MESSAGE_PATH"

  diff --brief "$TEMP_MESSAGE_PATH" "$EXPECTED_MESSAGE_PATH" || \
    err "'$STEGO_FILE_PATH' does not have the proper hidden message!" \
      "Expected: '$EXPECTED_MESSAGE_PATH'." \
      "Got: '$TEMP_MESSAGE_PATH'."

  info "'$STEGO_FILE_PATH' contains the proper hidden message."

  rm "$TEMP_MESSAGE_PATH"
}

## Test check function
# echo "I don't know..." > "message.tmp.txt"
# outguess_embed "$IMAGE_PATH" "stego.tmp.jpg" "message.tmp.txt"
# check "outguess_extract" "stego.tmp.jpg" "message.tmp.txt"
# info "Checking test finished."
# exit


# Usage: create_name <OLD_NAME> <PERCENTAGE>
# <PERCENTAGE>: Percentage without the '%' symbol. E.g. 05, 90, etc.
create_name() {
  local OLD_NAME=$(basename "$1")
  local PERCENTAGE="$2"
  echo "$OLD_NAME" | sed -r "s;(.+)\.(.+);\1_${PERCENTAGE}p.\2;"
}

## Test create_name function
# create_name "$IMAGE_PATH" 5
# create_name "$IMAGE_PATH" 90
# info "Creating name test finished."
# exit

# Embeds some text on the image
# Usage: do_embed <PERCENTAGE> <CAPACITY> <EXTRACT_COMMAND> <EMBED_COMMAND>
# <PERCENTAGE>: Percentage without the '%' symbol. E.g. 05, 90, etc.
# do_embed() {
#   local PERCENTAGE="$1"
#   local TEMP_MESSAGE_PATH="message.tmp.txt"

#   info "Embedding ${PERCENTAGE}% of '$IMAGE_PATH' capacity..."
#   NUMBER_BYTES=$(echo "$CAPACITY * $PERCENTAGE / 100" | bc)
#   head -c $NUMBER_BYTES $MERGED_BOOKS_PATH > $TEMP_MESSAGE_PATH
#   NEW_NAME=$(create_name $IMAGE_PATH)
#   STEGO_PATH=$OUTPUT_DIR/$NEW_NAME

#   info "Embedding $NUMBER_BYTES bytes into image and saving to '$STEGO_PATH'..."
#   embed $IMAGE_PATH $STEGO_PATH $TEMP_MESSAGE_PATH

#   info "Checking whether '$STEGO_PATH' contains the proper message..."
#   check $STEGO_PATH $TEMP_MESSAGE_PATH
#   rm $TEMP_MESSAGE_PATH
# }

# Create files with ~1%, 25%, 50% and 90% of the image capacity.
main() {
  # Define which functions are going to be used.
  local EMBEDING_FUNCTION="${ALGORITHM}_embed"
  local EXTRACTING_FUNCTION="${ALGORITHM}_extract"
  local CAPACITY_FUNCTION="${ALGORITHM}_capacity"

  info "Working on '$IMAGE_PATH'..."

  # Define the image's capacity.
  local CAPACITY=$("$CAPACITY_FUNCTION" "$IMAGE_PATH")
  [ "$CAPACITY" ] || err "\$CAPACITY was not set!"
  info "Esteganographic capacity for '$IMAGE_PATH' is $CAPACITY bytes."

  # Create stego-files with ~1%, 25%, 50% and 90% of image's capacity.
  for PERCENTAGE in 1 25 50 90; do
    info "Embedding ${PERCENTAGE}% of '$IMAGE_PATH' capacity..."

    # Define how many bytes shoulf be embedded.
    local NUMBER_BYTES=$(bc <<< "$CAPACITY * $PERCENTAGE / 100")
    [ "$NUMBER_BYTES" ] || err "\$NUMBER_BYTES was not set."
    info "Embedding ${PERCENTAGE}% of image's capacity (${NUMBER_BYTES} bytes) into the image."

    # Read some bytes from books and write into a temporary file.
    local TEMP_MESSAGE_PATH="message.tmp.txt"
    head -c "$NUMBER_BYTES" "$MERGED_BOOKS_PATH" > "$TEMP_MESSAGE_PATH" || \
      err "Failed to read bytes from books and create temporary message!"

    # Define stego-image's name and path.
    local STEGO_NAME=$(create_name "$IMAGE_PATH" "$PERCENTAGE")
    [ "$STEGO_NAME" ] || err "\$STEGO_NAME was not set."
    local STEGO_PATH="$OUTPUT_DIR/$STEGO_NAME"
    [ "$STEGO_PATH" ] || err "\$STEGO_PATH was not set."
    info "Stego-image will be saved to '$STEGO_PATH'."

    # Embed message into the image
    "$EMBEDING_FUNCTION" "$IMAGE_PATH" "$STEGO_PATH" "$TEMP_MESSAGE_PATH"

    # Check whether the stego-image contains the correct message.
    info "Checking whether '$STEGO_PATH' contains the proper message..."
    check "$EXTRACTING_FUNCTION" "$STEGO_PATH" "$TEMP_MESSAGE_PATH"
  done

  info "All done for '$IMAGE_PATH'."
}

# Run the main function.
main

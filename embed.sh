#!/usr/bin/env bash


# Set some bash options.
#  - http://kvz.io/blog/2013/11/21/bash-best-practices/
set -o errexit  # make script exit when a command fails.
set -o nounset  # exit when script tries to use undeclared variables.
#set -o xtrace   # trace what gets executed.

# Displays usage and quit.
usage() {
  echo " Usage: $0 <ALGORITHM> <IMAGE_PATH> <OUTPUT_DIR>"
  echo
  echo ' Description:'
  echo "   Create four files containing 1%, 25%, 50% and 90% of the image's"
  echo "   capacity, using the specified algorithm."
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
  echo '   -l --log  FILE'
  echo '      Log messages to the specified file path.'
  echo '   -s --strict'
  echo '      Quits the script on the first error.'
  exit
}

## Default variables
# Set password that will be used for all steganography tools.
PASSWORD="steganography123"
# Set where the file containg the books are.
MERGED_BOOKS_PATH="messages/books.txt"
# Declare a tiny secret message that will be used for checking the
# steganographic capacity of images.
TESTING_MESSAGE="Why a raven is like a writing desk?"
# Don't log, by default.
LOG_PATH=""
# Don't debug, by default.
DEBUG=""
# Don't use strict, by default.
STRICT=""

# Outputs arguments to stdout.
info() {
  local NOW=$(date +"%F %T")
  if [ "$LOG_PATH" ]; then
    echo "[$NOW] INFO  $@" >>"$LOG_PATH"
  else
    echo "[$NOW] INFO  $@"
  fi
}

# Outputs arguments to stderr and quit.
err() {
  local NOW=$(date +"%F %T")
  if [ "$LOG_PATH" ]; then
    echo "[$NOW] ERROR  $@" >>"$LOG_PATH"
  else
    echo "[$NOW] ERROR  $@" 1>&2
  fi

  # Quit if strict mode is on.
  if [ -n "$STRICT" ]; then
    exit 1
  fi
}

# Outputs debugging info to stderr.
debug() {
  if [ "$DEBUG" ]; then
    local NOW=$(date +"%F %T")
    if [ "$LOG_PATH" ]; then
      echo "[$NOW] DEBUG  $@" >>"$LOG_PATH"
    else
      echo "[$NOW] DEBUG  $@" 1>&2
    fi
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
        DEBUG="true"
        shift 1
        ;;
    -s|--strict)
        STRICT="true"
        shift 1
        ;;
    -l|--log)
        [ "$2" ] || usage
        LOG_PATH="$2"
        shift 2
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

# Create the output directory, if it doesn't exist
mkdir -p "$OUTPUT_DIR" || \
  err "The output directory doesn't exist and could not be created!"

# Create the directory that will contain the log if needded
if [ "$LOG_PATH" ]; then
  LOG_DIR=$(dirname "$LOG_PATH")
  mkdir -p "$LOG_DIR" || \
    err "The log directory doesn't exist and could not be created!"
fi

# Debug arguments info.
debug "ALGORITHM: $ALGORITHM"
debug "IMAGE_PATH: $IMAGE_PATH"
debug "OUTPUT_DIR: $OUTPUT_DIR"

# Shortcuts for steganography tools that are not present in $PATH.
shopt -s expand_aliases
alias f5="java -jar tools/f5.jar"
alias lsbsteg="python tools/LSBSteg.py"

# Check whether the steganography tool needed is present.
type "$ALGORITHM" >/dev/null 2>&1 || \
  err "$ALGORITHM is not installed. Aborting."

# Check whether the cover image really exists
[ -f "$IMAGE_PATH" ] || err "The image file doesn't exist!"

# Embeds a message file into the cover image.
# Arguments: <COVER_PATH> <STEGO_PATH> <MESSAGE_PATH>
steghide_embed() {
  local COVER_PATH="$1"
  local STEGO_PATH="$2"
  local MESSAGE_PATH="$3"
  steghide embed -cf "$COVER_PATH" -sf "$STEGO_PATH" -ef "$MESSAGE_PATH" -p "$PASSWORD"
  [ "$?" -eq "0" ] || err "Failed to use steghide on image '$COVER_PATH'."
}
outguess_embed() {
  local COVER_PATH="$1"
  local STEGO_PATH="$2"
  local MESSAGE_PATH="$3"
  outguess "$COVER_PATH" "$STEGO_PATH" -d "$MESSAGE_PATH" -k "$PASSWORD"
  [ "$?" -eq "0" ] || err "Failed to use outguess on image '$COVER_PATH'."
}
f5_embed() {
  local COVER_PATH="$1"
  local STEGO_PATH="$2"
  local MESSAGE_PATH="$3"
  f5 e "$COVER_PATH" "$STEGO_PATH" -e "$MESSAGE_PATH" -p "$PASSWORD"
  [ "$?" -eq "0" ] || err "Failed to use f5 on image '$COVER_PATH'."
}
stepic_embed() {
  local COVER_PATH="$1"
  local STEGO_PATH="$2"
  local MESSAGE_PATH="$3"
  stepic --encode --image-in "$COVER_PATH" --out "$STEGO_PATH" --data-in "$MESSAGE_PATH"
  [ "$?" -eq "0" ] || err "Failed to use stepic on image '$COVER_PATH'."
}
lsbsteg_embed() {
  local COVER_PATH="$1"
  local STEGO_PATH="$2"
  local MESSAGE_PATH="$3"
  lsbsteg -image "$COVER_PATH" -steg-out "$STEGO_PATH" -binary "$MESSAGE_PATH"
  [ "$?" -eq "0" ] || err "Failed to use lsbsteg on image '$COVER_PATH'."
}

## Test outguess_extract function.
# echo "I don't know..." > "test-message.tmp.jpg"
# outguess_embed "$IMAGE_PATH" "stego-test.tmp.jpg" "test-message.tmp.jpg"
# info "Embedding test finished."
# exit

# Extracts the hidden message from the stego file.
# Usage: extract <STEGO_FILE> <OUTPUT_MESSAGE_PATH>
steghide_extract() {
  local STEGO_FILE="$1"
  local OUTPUT_MESSAGE_PATH="$2"
  steghide extract --stegofile "$STEGO_FILE" --extractfile "$OUTPUT_MESSAGE_PATH" --passphrase "$PASSWORD"
}
outguess_extract() {
  local STEGO_FILE="$1"
  local OUTPUT_MESSAGE_PATH="$2"
  outguess -r "$STEGO_FILE" "$OUTPUT_MESSAGE_PATH" -k "$PASSWORD"
}
f5_extract() {
  local STEGO_FILE="$1"
  local OUTPUT_MESSAGE_PATH="$2"
  f5 x "$STEGO_FILE" -e "$OUTPUT_MESSAGE_PATH" -p "$PASSWORD"
}
stepic_extract() {
  local STEGO_FILE="$1"
  local OUTPUT_MESSAGE_PATH="$2"
  stepic --decode --image-in "$STEGO_FILE" --out "$OUTPUT_MESSAGE_PATH"
}
lsbsteg_extract() {
  local STEGO_FILE="$1"
  local OUTPUT_MESSAGE_PATH="$2"
  lsbsteg -steg-image "$STEGO_FILE" -out "$OUTPUT_MESSAGE_PATH"
}

## Test outguess_embed function.
# outguess_extract "stego-test.tmp.jpg" "extracted-message.tmp.txt"
# info "Extraction test finished."
# exit


# Outputs the image's steganographic capacity (in bytes).
# Arguments: <IMAGE_PATH>
steghide_capacity() {
  local IMAGE_PATH="$1"

  # Use 'steghide info' to show the image's steganographic capacity.
  local OUTPUT=$(steghide info "$IMAGE_PATH" -p any_invalid_password 2>/dev/null)
  debug "OUTPUT: $OUTPUT"
  local KILO_BYTES=$(echo "$OUTPUT" | sed -nr 's/ +capacity: ([[:digit:]]+),[[:digit:]]+ KB/\1/p')
  debug "KILO_BYTES: $KILO_BYTES"

  # Convert to bytes (uses 1000 instead of 1024 on purpose, for "safety").
  bc <<< "$KILO_BYTES * 1000"
}
outguess_capacity() {
  local IMAGE_PATH="$1"
  local TEMP_STEGO_PATH="stego-image.tmp.jpg"
  local TEMP_MESSAGE_PATH="message.tmp.txt"
  echo "$TESTING_MESSAGE" > "$TEMP_MESSAGE_PATH"

  # Embeds a small message, so that we can read the capacity.
  local EMBEDDING_OUTPUT=$(outguess_embed "$IMAGE_PATH" "$TEMP_STEGO_PATH" "$TEMP_MESSAGE_PATH" 2>&1)
  debug "EMBEDDING_OUTPUT: $EMBEDDING_OUTPUT"
  local BITS=$(echo "$EMBEDDING_OUTPUT" | sed -nr 's/Correctable message size: ([[:digit:]]+) bits, .*%/\1/p')
  debug "BITS: $BITS"
  bc <<< "$BITS / 8"

  # Remove temporary files.
  rm -f "$TEMP_STEGO_PATH" "$TEMP_MESSAGE_PATH"
}
f5_capacity() {
  local IMAGE_PATH="$1"
  local TEMP_STEGO_PATH="stego-image.tmp.jpg"
  local TEMP_MESSAGE_PATH="message.tmp.txt"
  echo "$TESTING_MESSAGE" > "$TEMP_MESSAGE_PATH"

  # Embeds a small message, so that we can read the capacity.
  local EMBEDDING_OUTPUT=$(f5_embed "$IMAGE_PATH" "$TEMP_STEGO_PATH" "$TEMP_MESSAGE_PATH" 2>&1)
  debug "EMBEDDING_OUTPUT: $EMBEDDING_OUTPUT"


  local BYTES=$(echo "$EMBEDDING_OUTPUT" | sed -nr 's/default code: ([[:digit:]]+) bytes \(efficiency: .* bits per change\)/\1/p')
  debug "BYTES: $BYTES"
  echo $BYTES

  # Remove temporary files.
  rm -f "$TEMP_STEGO_PATH" "$TEMP_MESSAGE_PATH"
}
stepic_capacity() {
  local IMAGE_PATH="$1"

  # Read image's size in bytes.
  local IMAGE_SIZE=$(du "$IMAGE_PATH" --bytes | cut -f1)
  debug "IMAGE_SIZE: $IMAGE_SIZE"

  # The number of usable LSBs is the image's size devided by 8.
  bc <<< "$IMAGE_SIZE / 8"
}
lsbsteg_capacity() {
  local IMAGE_PATH="$1"

  # Read image's size in bytes.
  local IMAGE_SIZE=$(du "$IMAGE_PATH" --bytes | cut -f1)
  debug "IMAGE_SIZE: $IMAGE_SIZE"

  # The number of usable LSBs is the image's size devided by 8.
  bc <<< "$IMAGE_SIZE / 8"
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


# Create files with ~1%, 25%, 50% and 90% of the image capacity.
main() {
  # Define which functions are going to be used.
  local EMBEDING_FUNCTION="${ALGORITHM}_embed"
  local EXTRACTING_FUNCTION="${ALGORITHM}_extract"
  local CAPACITY_FUNCTION="${ALGORITHM}_capacity"

  info "Using $ALGORITHM on '$IMAGE_PATH'..."

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

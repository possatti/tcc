#/bin/bash

##
## Create four files containing ~1%, 25%, 50% and 90% of the image capacity,
## using the specified algorithm.
##

usage() {
  echo " Usage: $0 <image_path> <algorithm> <output_dir> [-h]"
  echo
  echo '   image_path - Path to the clean image.'
  echo '   algorithm - One of the four: f5, outguess, steghide, stepic.'
  echo '   output_dir - Where the resulting stego-images should be placed.'
  exit
}

# Checks we've got the right arguments
if [ "$1" == '-h' ]; then usage; fi
if [ "$1" == '--help' ]; then usage; fi
if [ "$#" -lt '3' ]; then usage; fi

IMAGE_PATH=$1
ALGORITHM=$2
OUTPUT_DIR=$3
PASSWORD=steganography123
TESTING_MESSAGE="Why a raven is like a writing desk?"
F5="java -jar tools/f5.jar"

# Outputs arguments to stdout.
info() {
  $NOW=$(date +"%F %T")
  echo $NOW 'INFO' $@
}

# Outputs arguments to stderr.
err() {
  $NOW=$(date +"%F %T")
  echo $NOW 'ERROR' $@ 1>&2
}

# Embeds a message file into the cover image.
# Usage: outguess_embed <IMAGE_PATH> <STEGO_PATH> <MESSAGE_PATH>
outguess_embed() {
  #outguess -d $MESSAGE_PATH $IMAGE_PATH $STEGO_PATH -k $PASSWORD
  outguess $1 $2 -d $3 -k $PASSWORD
}

# Extracts the hidden message from the file.
# Usage: outguess_extract <STEGO_FILE> <EXTRACTED_MESSAGE_PATH>
outguess_extract() {
  local STEGO_FILE=$1
  local EXTRACTED_MESSAGE_PATH=$2

  outguess -r $STEGO_FILE $EXTRACTED_MESSAGE_PATH -k $PASSWORD
}

# Outputs the image's steganographic capacity.
# Usage: outguess_capacity <IMAGE_PATH>
outguess_capacity() {
  local TEMP_IMAGE_PATH=$1
  local TEMP_STEGO_PATH="temp_stego_image.jpg"
  local TEMP_MESSAGE_PATH="temp_message.txt"
  echo $TESTING_MESSAGE > $TEMP_MESSAGE_PATH

  local EMBEDDING_OUTPUT=$(outguess_embed $1 $TEMP_STEGO_PATH $TEMP_MESSAGE_PATH 2>&1)
  local BITS=$($EMBEDDING_OUTPUT | sed -nr 's/Correctable message size: ([[:digit:]]+) bits, .*%/\1/p')
  expr $BITS / 8
}


# Checks it the stego-image contains the proper hidden message.
# Usage: check <EXTRACTING_COMMAND> <STEGO_FILE_PATH> <EXPECTED_MESSAGE_PATH>
check() {
  local EXTRACTING_COMMAND=$1
  local STEGO_FILE_PATH=$2
  local EXPECTED_MESSAGE_PATH=$3
  local TEMP_MESSAGE_PATH="temp_extracted_$IMAGE_PATH.txt"

  $EXTRACTING_COMMAND $STEGO_FILE_PATH $TEMP_MESSAGE_PATH

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
  echo OLD_NAME | sed -r "s;(.+)\.(.+);\1_${PERCENTAGE}p.\2;"
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
  outguess_embed $IMAGE_PATH $STEGO_PATH $TEMP_MESSAGE_PATH

  info "Checking whether '$STEGO_PATH' contains the proper message..."
  outguess_check $STEGO_PATH $TEMP_MESSAGE_PATH
  rm $TEMP_MESSAGE_PATH
}

# Create files with ~1%, 25%, 50% and 90% of the image capacity.
do_all_embedding() {
  EMBEDING_FUNCTION=$1
  EXTRACTING_FUNCTION=$2
  CAPACITY_FUNCTION=$3

  info "Working on '$IMAGE_PATH'..."
  mkdir -p $OUTPUT_DIR
  CAPACITY=$($CAPACITY_FUNCTION $IMAGE_PATH)
  info "Esteganographic capacity for '$IMAGE_PATH' is $CAPACITY bytes."

  # 25% of book
  do_embed 1
  do_embed 25
  do_embed 50
  do_embed 90

  info "All done for '$IMAGE_PATH'."
}

do_all_embedding

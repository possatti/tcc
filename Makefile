# Makefile options.
SHELL=/bin/bash
.ONESHELL:
.PHONY: clean all outguess f5 steghide stepic stegexpose

# Directories.
IMAGES_DIR=images
CLEAN_JPEG_IMAGES_DIR=$(IMAGES_DIR)/clean_jpeg
CLEAN_PNG_IMAGES_DIR=$(IMAGES_DIR)/clean_png
MESSAGES_DIR=messages

# StegExpose variables.
REPORTS_DIR=reports
CLEAN_REPORT=$(REPORTS_DIR)/clean.csv
STEGHIDE_REPORT=$(REPORTS_DIR)/steghide.csv
F5_REPORT=$(REPORTS_DIR)/f5.csv
OUTGUESS_REPORT=$(REPORTS_DIR)/outguess.csv
STEPIC_REPORT=$(REPORTS_DIR)/stepic.csv
StegExpose=java -jar tools/StegExpose.jar

# Other variables.
KEY=steganography123
NUKE_MESSAGE=$(MESSAGES_DIR)/nuke.txt
BOOKS=$(wildcard $(MESSAGES_DIR)/books/pg*.txt)
MERGED_BOOKS=$(MESSAGES_DIR)/books.txt


# Embedding functions.
# Usage: $(call func,cover,estego,message)
steghide_embed=steghide embed -cf $(1) -sf $(2) -ef $(3) -p $(KEY)
f5_embed=$(F5) e -e $(3) $(1) $(2) -p $(KEY)
outguess_embed=outguess -d $(3) $(1) $(2) -k $(KEY)
stepic_embed=stepic --encode --image-in $(1) --data-in $(3) --out $(2)

# Extracting functions
# Usage: $(call func,stego_file,destination)
outguess_extract=outguess -k $(KEY) -r $(1) $(2)
steghide_extract=steghide extract --passphrase $(KEY) --stegofile $(1) --extractfile $(2)
f5_extract=$(F5) x -p $(KEY) -e $(2) $(1)
stepic_extract=stepic --decode --image-in $(1) --out $(2)

# Checking functions.
# Usage: $(call func,stego_file,expected_message)
define outguess_check
outguess -k $(KEY) -r $(1) tmp-extracted.txt
diff --brief tmp-extracted.txt $(2)
if [ $$? -eq 1 ]; then
	echo " >> $(1) does not have the proper hidden message."
	exit 1
fi
rm tmp-extracted.txt
endef


# Scripts to read the steganographic capacity. (Output in bytes to read from file)
lsb_capacity=du $(1) --bytes | cut -f1 | sed -r 's;.*;&/8;' | bc
steghide_capacity=sh scripts/read-steghide-capacity.sh
f5_capacity=sh scripts/read-f5-capacity.sh
outguess_capacity=sh scripts/read-outguess-capacity.sh

# Helper functions.
# Usage: $(call bytes_to_read,capacity,percentage)
bytes_to_read=echo "$(1) * 0.$(2)" | bc | sed -r "s;([[:digit:]]+)\..*;\1;"
# Usage: $(call read_bytes_from_books,n_bytes,file_name)
read_bytes_from_books=head -c $(1) $(MERGED_BOOKS) > $(2)
# Usage: $(call name_p,original_name,percentage)
# Description: Change the original name from "image.jpg" to "image_25p.jpg" for example.
name_p=echo $(1) | sed -r "s;(.+)\.(.+);\1_$(2)p.\2;"

# StegExpose helper function.
# Usage: $(call func,test_dir,csv)
run_stegexpose=$(StegExpose) $(1) default default $(2)


# Do everything!
all: steghide f5 outguess stepic stegexpose

# Merge the books together.
$(MERGED_BOOKS): $(BOOKS)
	cd $(MESSAGES_DIR)/books
	sh ../../scripts/merge-books.sh
	mv books.txt ..

# Rules for making all esteganography.
steghide:
	mkdir $(STEGHIDE_DIR) -p
	for image in $(IMAGE_NAMES); do
		make "$(STEGHIDE_DIR)/$$image"
	done

f5:
	mkdir $(F5_DIR) -p
	for image in $(IMAGE_NAMES); do
		make "$(F5_DIR)/$$image"
	done

outguess:
	mkdir $(OUTGUESS_DIR) -p
	for image in $(IMAGE_NAMES); do
		make "$(OUTGUESS_DIR)/$$image"
	done

stepic:
	mkdir $(STEPIC_DIR) -p
	for image in `ls $(CLEAN_PNG_IMAGES_DIR)`; do
		make "$(STEPIC_DIR)/$$image"
	done


# Rule for applying steganalysis with StegExpose.
stegexpose:
	mkdir -p $(REPORTS_DIR)
	echo " >> Running StegExpose on '$(STEGHIDE_DIR)'..."
	$(StegExpose) $(STEGHIDE_DIR) default default $(STEGHIDE_REPORT)
	echo " >> Running StegExpose on '$(F5_DIR)'..."
	$(StegExpose) $(F5_DIR) default default $(F5_REPORT)
	echo " >> Running StegExpose on '$(OUTGUESS_DIR)'..."
	$(StegExpose) $(OUTGUESS_DIR) default default $(OUTGUESS_REPORT)
	echo " >> Running StegExpose on '$(STEPIC_DIR)'..."
	$(StegExpose) $(STEPIC_DIR) default default $(STEPIC_REPORT)
	echo " >> All done with StegExpose."

# Clean the directories.
clean:
	if [ -d "$(OUTGUESS_DIR)" ]; then rm -r $(OUTGUESS_DIR); fi
	if [ -d "$(STEGHIDE_DIR)" ]; then rm -r $(STEGHIDE_DIR); fi
	if [ -d "$(F5_DIR)" ]; then rm -r $(F5_DIR); fi

# Makefile options.
SHELL=/bin/bash
.ONESHELL:
.PHONY: clean all outguess f5 steghide stepic stegexpose

# Directories and images.
IMAGES_DIR = images
CLEAN_JPEG_IMAGES_DIR = $(IMAGES_DIR)/clean_jpeg
CLEAN_JPEG_IMAGES = $(wildcard $(CLEAN_JPEG_IMAGES_DIR)/*.jpg)
CLEAN_PNG_IMAGES_DIR = $(IMAGES_DIR)/clean_png
CLEAN_PNG_IMAGES = $(wildcard $(CLEAN_PNG_IMAGES_DIR)/*.png)
STEGHIDE_DIR = $(IMAGES_DIR)/steghide
OUTGUESS_DIR = $(IMAGES_DIR)/outguess
F5_DIR = $(IMAGES_DIR)/f5
STEPIC_DIR = $(IMAGES_DIR)/stepic

# StegExpose variables.
REPORTS_DIR = reports
CLEAN_REPORT = $(REPORTS_DIR)/clean.csv
STEGHIDE_REPORT = $(REPORTS_DIR)/steghide.csv
F5_REPORT = $(REPORTS_DIR)/f5.csv
OUTGUESS_REPORT = $(REPORTS_DIR)/outguess.csv
STEPIC_REPORT = $(REPORTS_DIR)/stepic.csv
StegExpose = java -jar tools/StegExpose.jar

# Other variables.
MESSAGES_DIR = messages
BOOKS = $(wildcard $(MESSAGES_DIR)/books/pg*.txt)
MERGED_BOOKS = $(MESSAGES_DIR)/books.txt


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


# Do everything!
all: clean steghide f5 outguess stepic stegexpose

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
	mkdir -p "$(F5_DIR)"
	for IMAGE_PATH in $(CLEAN_JPEG_IMAGES); do
		./embed.sh "f5" "$$IMAGE_PATH" "$(F5_DIR)" --log "f5-embedding.log" --strict
	done

outguess:
	mkdir -p "$(OUTGUESS_DIR)"
	for IMAGE_PATH in $(CLEAN_JPEG_IMAGES); do
		./embed.sh "outguess" "$$IMAGE_PATH" "$(OUTGUESS_DIR)" --log "outguess-embedding.log" --strict
	done

stepic:
	mkdir -p "$(STEPIC_DIR)"
	for IMAGE_PATH in $(CLEAN_PNG_IMAGES); do
		./embed.sh "stepic" "$$IMAGE_PATH" "$(STEPIC_DIR)" --log "stepic-embedding.log" --strict
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
	if [ -d "$(STEGHIDE_DIR)" ]; then rm -r $(STEGHIDE_DIR); fi
	if [ -d "$(OUTGUESS_DIR)" ]; then rm -r $(OUTGUESS_DIR); fi
	if [ -d "$(F5_DIR)" ]; then rm -r $(F5_DIR); fi
	if [ -d "$(STEPIC_DIR)" ]; then rm -r $(STEPIC_DIR); fi
	rm -f *.tmp.*

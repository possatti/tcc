# Makefile options.
SHELL=/bin/bash
.ONESHELL:
.PHONY: clean all outguess f5 steghide stepic lsbsteg stegexpose backup-data

# Directories and images.
IMAGES_DIR = images
CLEAN_JPEG_IMAGES_DIR = $(IMAGES_DIR)/clean-jpg
CLEAN_JPEG_IMAGES = $(wildcard $(CLEAN_JPEG_IMAGES_DIR)/*.jpg)
CLEAN_PNG_IMAGES_DIR = $(IMAGES_DIR)/clean-png
CLEAN_PNG_IMAGES = $(wildcard $(CLEAN_PNG_IMAGES_DIR)/*.png)
STEGHIDE_DIR = $(IMAGES_DIR)/steghide
OUTGUESS_DIR = $(IMAGES_DIR)/outguess
F5_DIR = $(IMAGES_DIR)/f5
STEPIC_DIR = $(IMAGES_DIR)/stepic
LSBSTEG_DIR = $(IMAGES_DIR)/lsbsteg

# StegExpose variables.
StegExpose = java -jar tools/StegExpose.jar
STEGEXPOSE_SPEED = default
STEGEXPOSE_THRESHOLD = default
REPORTS_DIR = reports
CLEAN_JPEG_REPORT = $(REPORTS_DIR)/clean-jpeg.csv
CLEAN_PNG_REPORT = $(REPORTS_DIR)/clean-png.csv
STEGHIDE_REPORT = $(REPORTS_DIR)/steghide.csv
F5_REPORT = $(REPORTS_DIR)/f5.csv
OUTGUESS_REPORT = $(REPORTS_DIR)/outguess.csv
STEPIC_REPORT = $(REPORTS_DIR)/stepic.csv
LSBSTEG_REPORT = $(REPORTS_DIR)/lsbsteg.csv

# Embedding Logs
LOG_DIR = logs
STEGHIDE_LOG = $(LOG_DIR)/steghide.log
F5_LOG = $(LOG_DIR)/f5.log
OUTGUESS_LOG = $(LOG_DIR)/outguess.log
STEPIC_LOG = $(LOG_DIR)/stepic.log
LSBSTEG_LOG = $(LOG_DIR)/lsbsteg.log

# Other variables.
MESSAGES_DIR = messages
BOOKS = $(wildcard $(MESSAGES_DIR)/books/pg*.txt)
MERGED_BOOKS = $(MESSAGES_DIR)/books.txt


# Do everything!
all: clean steghide f5 outguess stepic lsbsteg stegexpose backup-data

# Merge the books together.
$(MERGED_BOOKS): $(BOOKS)
	cd $(MESSAGES_DIR)/books
	sh ../../scripts/merge-books.sh
	mv books.txt ..

# Rules for making all esteganography.
steghide: $(MERGED_BOOKS)
	mkdir -p "$(STEGHIDE_DIR)"
	for IMAGE_PATH in $(CLEAN_JPEG_IMAGES); do
		./embed.sh "steghide" "$$IMAGE_PATH" "$(STEGHIDE_DIR)" --log "$(STEGHIDE_LOG)" --strict
	done

f5: $(MERGED_BOOKS)
	mkdir -p "$(F5_DIR)"
	for IMAGE_PATH in $(CLEAN_JPEG_IMAGES); do
		./embed.sh "f5" "$$IMAGE_PATH" "$(F5_DIR)" --log "$(F5_LOG)" --strict
	done

outguess: $(MERGED_BOOKS)
	mkdir -p "$(OUTGUESS_DIR)"
	for IMAGE_PATH in $(CLEAN_JPEG_IMAGES); do
		./embed.sh "outguess" "$$IMAGE_PATH" "$(OUTGUESS_DIR)" --log "$(OUTGUESS_LOG)" --strict
	done

stepic: $(MERGED_BOOKS)
	mkdir -p "$(STEPIC_DIR)"
	for IMAGE_PATH in $(CLEAN_PNG_IMAGES); do
		./embed.sh "stepic" "$$IMAGE_PATH" "$(STEPIC_DIR)" --log "$(STEPIC_LOG)" --strict
	done

lsbsteg: $(MERGED_BOOKS)
	mkdir -p "$(LSBSTEG_DIR)"
	for IMAGE_PATH in $(CLEAN_PNG_IMAGES); do
		./embed.sh "lsbsteg" "$$IMAGE_PATH" "$(LSBSTEG_DIR)" --log "$(LSBSTEG_LOG)" --strict
	done


# Rule for applying steganalysis with StegExpose.
stegexpose:
	mkdir -p $(REPORTS_DIR)
	echo " >> Running StegExpose on '$(CLEAN_JPEG_IMAGES_DIR)'..."
	$(StegExpose) $(CLEAN_JPEG_IMAGES_DIR) $(STEGEXPOSE_SPEED) $(STEGEXPOSE_THRESHOLD) $(CLEAN_JPEG_REPORT)
	echo " >> Running StegExpose on '$(CLEAN_PNG_IMAGES_DIR)'..."
	$(StegExpose) $(CLEAN_PNG_IMAGES_DIR) $(STEGEXPOSE_SPEED) $(STEGEXPOSE_THRESHOLD) $(CLEAN_PNG_REPORT)
	echo " >> Running StegExpose on '$(STEGHIDE_DIR)'..."
	$(StegExpose) $(STEGHIDE_DIR) $(STEGEXPOSE_SPEED) $(STEGEXPOSE_THRESHOLD) $(STEGHIDE_REPORT)
	echo " >> Running StegExpose on '$(F5_DIR)'..."
	$(StegExpose) $(F5_DIR) $(STEGEXPOSE_SPEED) $(STEGEXPOSE_THRESHOLD) $(F5_REPORT)
	echo " >> Running StegExpose on '$(OUTGUESS_DIR)'..."
	$(StegExpose) $(OUTGUESS_DIR) $(STEGEXPOSE_SPEED) $(STEGEXPOSE_THRESHOLD) $(OUTGUESS_REPORT)
	echo " >> Running StegExpose on '$(STEPIC_DIR)'..."
	$(StegExpose) $(STEPIC_DIR) $(STEGEXPOSE_SPEED) $(STEGEXPOSE_THRESHOLD) $(STEPIC_REPORT)
	echo " >> Running StegExpose on '$(LSBSTEG_DIR)'..."
	$(StegExpose) $(LSBSTEG_DIR) $(STEGEXPOSE_SPEED) $(STEGEXPOSE_THRESHOLD) $(LSBSTEG_REPORT)
	echo " >> All done with StegExpose."

backup-data:
	NOW=`date +"%F_%T"`
	zip -r "experimento_$${NOW}.zip" "$(LOG_DIR)" "$(REPORTS_DIR)"

# Clean the directories.
clean:
	# Remove directories containing stego-images.
	rm -rf $(STEGHIDE_DIR)
	rm -rf $(OUTGUESS_DIR)
	rm -rf $(F5_DIR)
	rm -rf $(STEPIC_DIR)
	rm -rf $(LSBSTEG_DIR)
	# Remove reports.
	rm -rf $(REPORTS_DIR)
	# Remove temporary files.
	rm -f *.tmp.*
	# Remove temporary logs.
	rm -rf $(LOG_DIR)
	rm -f *.log

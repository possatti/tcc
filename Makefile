# Makefile options
SHELL=/bin/bash
.ONESHELL:
.PHONY: clean outguess f5 steghide

# F5 steganography tool
F5=java -jar tools/f5.jar

# Directories
CLEAN_IMAGES_DIR=images/clean
STEGHIDE_DIR=images/steghide
F5_DIR=images/f5
OUTGUESS_DIR=images/outguess
MESSAGES_DIR=messages

# Other variables
KEY=steganography123
NUKE_MESSAGE=$(MESSAGES_DIR)/nuke.txt
IMAGE_NAMES=`ls $(CLEAN_IMAGES_DIR)`



$(STEGHIDE_DIR)/%.jpg: $(CLEAN_IMAGES_DIR)/%.jpg $(NUKE_MESSAGE)
	steghide embed -p $(KEY) -cf $< -ef $(NUKE_MESSAGE) -sf $@

$(F5_DIR)/%.jpg: $(CLEAN_IMAGES_DIR)/%.jpg $(NUKE_MESSAGE)
	$(F5) e -e $(NUKE_MESSAGE) $< $@

$(OUTGUESS_DIR)/%.jpg: $(CLEAN_IMAGES_DIR)/%.jpg $(NUKE_MESSAGE)
	outguess -k $(KEY) -d $(MESSAGES_DIR)/nuke.txt $< $@


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

steghide_check:
	for file in $(IMAGE_NAMES); do
		steghide extract -p $(KEY) -sf "$(STEGHIDE_DIR)/$$file" -xf "extracted.txt"
		diff --brief "extracted.txt" "$(MESSAGES_DIR)/nuke.txt"
		comp_value=$$?
		if [ $$comp_value -eq 1 ]; then
			echo "$(STEGHIDE_DIR)/$$file does not have the proper hidden message."
			exit 1
		fi
		rm "extracted.txt"
	done
	echo "All files contain hidden messages."

f5_check:
	for file in $(IMAGE_NAMES); do
		$(F5) x -e "extracted.txt" "$(F5_DIR)/$$file"
		diff --brief "extracted.txt" "$(MESSAGES_DIR)/nuke.txt"
		comp_value=$$?
		if [ $$comp_value -eq 1 ]; then
			echo "$(F5_DIR)/$$file does not have the proper hidden message."
			exit 1
		fi
		rm "extracted.txt"
	done
	echo "All files contain hidden messages."

outguess_check:
	for file in $(IMAGE_NAMES); do
		outguess -k $(KEY) -r "$(OUTGUESS_DIR)/$$file" "extracted.txt"
		diff --brief "extracted.txt" "$(MESSAGES_DIR)/nuke.txt"
		comp_value=$$?
		if [ $$comp_value -eq 1 ]
		then
			echo "$(OUTGUESS_DIR)/$$file does not have the proper hidden message."
			exit 1
		fi
		rm "extracted.txt"
	done
	echo "All files contain hidden messages."

clean:
	if [ -d "$(OUTGUESS_DIR)" ]; then rm -r $(OUTGUESS_DIR); fi
	if [ -d "$(STEGHIDE_DIR)" ]; then rm -r $(STEGHIDE_DIR); fi
	if [ -d "$(F5_DIR)" ]; then rm -r $(F5_DIR); fi

# Makefile options.
SHELL=/bin/bash
.ONESHELL:
.PHONY: clean outguess f5 steghide

# F5 steganography tool.
F5=java -jar tools/f5.jar

# Directories.
CLEAN_IMAGES_DIR=images/clean
STEGHIDE_DIR=images/steghide
F5_DIR=images/f5
OUTGUESS_DIR=images/outguess
MESSAGES_DIR=messages

# Images.
CLEAN_IMAGES=$(wildcard $(CLEAN_IMAGES_DIR)/*.jpg)

# Other variables.
KEY=steganography123
NUKE_MESSAGE=$(MESSAGES_DIR)/nuke.txt
IMAGE_NAMES=`ls $(CLEAN_IMAGES_DIR)`
BOOKS=$(wildcard $(MESSAGES_DIR)/books/pg*.txt)
MERGED_BOOKS=$(MESSAGES_DIR)/books.txt

# Embedding functions.
# Usage: $(call func,cover,estego,message)
steghide_embed=steghide embed -cf $(1) -sf $(2) -ef $(3) -p $(KEY)
f5_embed=$(F5) e -e $(3) $(1) $(2)
outguess_embed=outguess -d $(3) $(1) $(2) -k $(KEY)

# Extracting functions
# Usage: $(call func,stego_file,destination)
outguess_extract=outguess -k $(KEY) -r $(1) $(2)
steghide_extract=steghide extract --passphrase $(KEY) --stegofile $(1) --extractfile $(2)
f5_extract=$(F5) x -p $(KEY) -e $(2) $(1)

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
define steghide_check
$(call steghide_extract,$(1),tmp-extracted.txt)
diff --brief tmp-extracted.txt $(2)
if [ $$? -eq 1 ]; then
	echo " >> $(1) does not have the proper hidden message."
	exit 1
fi
rm tmp-extracted.txt
endef
define f5_check
$(call f5_extract,$(1),tmp-extracted.txt)
diff --brief tmp-extracted.txt $(2)
if [ $$? -eq 1 ]; then
	echo " >> $(1) does not have the proper hidden message."
	exit 1
fi
rm tmp-extracted.txt
endef

# Scripts to read the steganographic capacity.
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
name_p=echo $(1) | sed -r "s;(.+)\.jpg;\1_$(2)p.jpg;"


# Merge the books together.
$(MERGED_BOOKS): $(BOOKS)
	cd $(MESSAGES_DIR)/books
	sh ../../scripts/merge-books.sh
	mv books.txt ..


# Transforming rules.
$(STEGHIDE_DIR)/%.jpg: $(CLEAN_IMAGES_DIR)/%.jpg $(NUKE_MESSAGE)
	@mkdir $(OUTGUESS_DIR) -p
	capacity=`steghide info $< -p $(KEY) 2>/dev/null | $(steghide_capacity)`
	$(call steghide_embed,$<,$@,$(NUKE_MESSAGE))
	echo " >> capacity: $$capacity"

	# 25% of book
	n_bytes=`$(call bytes_to_read,$$capacity,25)`
	$(call read_bytes_from_books,$$n_bytes,tmp-books.txt)
	name=`$(call name_p,$@,25)`
	$(call steghide_embed,$<,$$name,tmp-books.txt)
	$(call steghide_check,$$name,tmp-books.txt)
	rm tmp-books.txt

	# 50% of book
	n_bytes=`$(call bytes_to_read,$$capacity,50)`
	$(call read_bytes_from_books,$$n_bytes,tmp-books.txt)
	name=`$(call name_p,$@,50)`
	$(call steghide_embed,$<,$$name,tmp-books.txt)
	$(call steghide_check,$$name,tmp-books.txt)
	rm tmp-books.txt

	# 90% of book
	n_bytes=`$(call bytes_to_read,$$capacity,90)`
	$(call read_bytes_from_books,$$n_bytes,tmp-books.txt)
	name=`$(call name_p,$@,90)`
	$(call steghide_embed,$<,$$name,tmp-books.txt)
	$(call steghide_check,$$name,tmp-books.txt)
	rm tmp-books.txt

$(F5_DIR)/%.jpg: $(CLEAN_IMAGES_DIR)/%.jpg $(NUKE_MESSAGE)
	$(call f5_embed, $<, $@, $(NUKE_MESSAGE))

$(OUTGUESS_DIR)/%.jpg: $(CLEAN_IMAGES_DIR)/%.jpg $(NUKE_MESSAGE)
	@mkdir $(OUTGUESS_DIR) -p
	capacity=`$(call outguess_embed, $<, $@, $(NUKE_MESSAGE)) 2>&1 | $(outguess_capacity)`
	$(call outguess_check,$@,$(NUKE_MESSAGE))
	echo " >> capacity: $$capacity"

	# 25% of book
	n_bytes=`$(call bytes_to_read,$$capacity,25)`
	$(call read_bytes_from_books,$$n_bytes,tmp-books.txt)
	name=`$(call name_p,$@,25)`
	$(call outguess_embed,$<,$$name,tmp-books.txt)
	$(call outguess_check,$$name,tmp-books.txt)
	rm tmp-books.txt

	# 50% of book
	n_bytes=`$(call bytes_to_read,$$capacity,50)`
	$(call read_bytes_from_books,$$n_bytes,tmp-books.txt)
	name=`$(call name_p,$@,50)`
	$(call outguess_embed,$<,$$name,tmp-books.txt)
	$(call outguess_check,$$name,tmp-books.txt)
	rm tmp-books.txt

	# 90% of book
	n_bytes=`$(call bytes_to_read,$$capacity,90)`
	$(call read_bytes_from_books,$$n_bytes,tmp-books.txt)
	name=`$(call name_p,$@,90)`
	$(call outguess_embed,$<,$$name,tmp-books.txt)
	$(call outguess_check,$$name,tmp-books.txt)
	rm tmp-books.txt


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


# Checking rules.
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


# Clean the directories.
clean:
	if [ -d "$(OUTGUESS_DIR)" ]; then rm -r $(OUTGUESS_DIR); fi
	if [ -d "$(STEGHIDE_DIR)" ]; then rm -r $(STEGHIDE_DIR); fi
	if [ -d "$(F5_DIR)" ]; then rm -r $(F5_DIR); fi

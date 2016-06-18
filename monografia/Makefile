# Makefile options
SHELL=/bin/bash
.ONESHELL:
.PHONY: all clean upload

# Other variables
GOOGLE_DRIVE_DIR = /home/possatti/gdrive/TCC/Monografia
TEX_FILES = monografia.tex 0-abstract.tex 0-resumo.tex 1-introducao.tex 2-referencial.tex 3-desenvolvimento.tex
BIB_FILES = referencias.bib
SOURCE_FILES = $(TEX_FILES) $(BIB_FILES)


all: monografia.pdf

monografia.pdf: $(SOURCE_FILES)
	pdflatex -interaction=nonstopmode -halt-on-error monografia
	bibtex monografia
	pdflatex -interaction=nonstopmode -halt-on-error monografia
	pdflatex -interaction=nonstopmode -halt-on-error monografia
	$(MAKE) deletar_lixo

upload: monografia.pdf $(SOURCE_FILES)
	mkdir $(GOOGLE_DRIVE_DIR) -p
	now=`date +"%F %T"`
	zip "monografia-source.zip" *.tex *.bib -r img/
	cp "monografia.pdf" "$(GOOGLE_DRIVE_DIR)/Monografia $$now.pdf"
	cp "monografia-source.zip" "$(GOOGLE_DRIVE_DIR)/Monografia $$now.zip"
	drive push -no-prompt "$(GOOGLE_DRIVE_DIR)"

deletar_lixo:
	-rm *.bbl
	-rm *.idx
	-rm *.lot
	-rm *.toc
	-rm *.blg
	-rm *.lof
	-rm *.aux
	-rm *.brf
	-rm *.log

clean:
	$(MAKE) deletar_lixo
	rm monografia.pdf

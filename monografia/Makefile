# Makefile options
SHELL=/bin/bash
.ONESHELL:
.PHONY: all clean upload

# Other variables
GOOGLE_DRIVE_DIR = /home/possatti/gdrive/tcc
TEX_FILES = monografia.tex 1-introducao.tex 2-referencial.tex 3-desenvolvimento.tex


all: monografia.pdf

monografia.pdf: monografia.tex
	pdflatex -interaction=nonstopmode -halt-on-error monografia
	bibtex monografia
	pdflatex -interaction=nonstopmode -halt-on-error monografia
	pdflatex -interaction=nonstopmode -halt-on-error monografia
	$(MAKE) deletar_lixo

upload: monografia.pdf
	mkdir $(GOOGLE_DRIVE_DIR) -p
	now=`date +"%F %T"`
	echo $$now
	cp monografia.pdf "$(GOOGLE_DRIVE_DIR)/monografia $$now.pdf"
	#drive push "$(GOOGLE_DRIVE_DIR)" -no-prompt

deletar_lixo:
	-rm monografia.bbl
	-rm monografia.idx
	-rm monografia.lot
	-rm monografia.toc
	-rm abntex2-modelo-include-comandos.aux
	-rm monografia.blg
	-rm monografia.lof
	-rm monografia.aux
	-rm monografia.brf
	-rm monografia.log

clean:
	$(MAKE) deletar_lixo
	rm monografia.pdf

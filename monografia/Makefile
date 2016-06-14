# Makefile options
SHELL=/bin/bash
.ONESHELL:
.PHONY: all clean upload

# Other variables
GOOGLE_DRIVE_DIR = /home/possatti/gdrive/TCC
TEX_FILES = monografia.tex 0-abstract.tex 0-resumo.tex 1-introducao.tex 2-referencial.tex 3-desenvolvimento.tex


all: monografia.pdf

monografia.pdf: $(TEX_FILES)
	pdflatex -interaction=nonstopmode -halt-on-error monografia
	bibtex monografia
	pdflatex -interaction=nonstopmode -halt-on-error monografia
	pdflatex -interaction=nonstopmode -halt-on-error monografia
	$(MAKE) deletar_lixo

upload: monografia.pdf
	mkdir $(GOOGLE_DRIVE_DIR) -p
	now=`date +"%F %T"`
	cp monografia.pdf "$(GOOGLE_DRIVE_DIR)/Monografia $$now.pdf"
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

# Makefile options
SHELL=/bin/bash
.ONESHELL:
.PHONY: all clean upload

# Other variables
GOOGLE_DRIVE_DIR = /home/possatti/gdrive/tcc
TEX_FILES = monografia.tex 0-abstract.tex 0-resumo.tex 1-introducao.tex 2-referencial.tex


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
	echo $$now
	cp monografia.pdf "$(GOOGLE_DRIVE_DIR)/monografia $$now.pdf"
	#drive push "$(GOOGLE_DRIVE_DIR)" -no-prompt

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

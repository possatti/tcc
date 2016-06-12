
TEX_FILES = monografia.tex 1-introducao.tex 2-referencial.tex 3-desenvolvimento.tex

monografia.pdf: monografia.tex
	pdflatex -interaction=nonstopmode -halt-on-error monografia
	bibtex monografia
	pdflatex -interaction=nonstopmode -halt-on-error monografia
	pdflatex -interaction=nonstopmode -halt-on-error monografia
	$(MAKE) deletar_lixo

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

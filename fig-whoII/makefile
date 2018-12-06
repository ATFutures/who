LL=latex
PDF=dvipdfm
LFLAGS=-interaction=nonstopmode -shell-escape
PFLAGS=-dAutoRotatePages=/None
FILEONE = fig1

all: fig1

fig1: fig1pdf clean
png: fig1pdf2 fig1convert clean

fig1pdf:
	pdflatex -shell-escape $(FILEONE).tex
fig1pdf2:
	pdflatex $(FILEONE).tex
fig1convert:
	convert $(FILEONE).pdf -density 2400 $(FILEONE).png

clean:
	rm -f *.aux *.log *.pdf

LFILE = README
DATAFILE = code/download-data

all: knith open 

knith: $(LFILE).Rmd
	echo "rmarkdown::render('$(LFILE).Rmd',output_file='$(LFILE).html')" | R --no-save -q

knitr: $(LFILE).Rmd
	echo "rmarkdown::render('$(LFILE).Rmd',rmarkdown::md_document(variant='markdown_github'))" | R --no-save -q

open: $(LFILE).html
	xdg-open $(LFILE).html &

data: $(DATAFILE).R
	Rscript --verbose $(DATAFILE).R

clean:
	rm -rf *.html *.png README_cache 

.PHONY: all document test check build clean

all: document test check build

document:
	Rscript -e 'devtools::document()'

test:
	Rscript -e 'devtools::test()'

check:
	Rscript -e 'devtools::check()'

build:
	Rscript -e 'devtools::build()'

clean:
	rm -rf man/*
	rm -rf ./amtabulator.Rcheck
	rm -f *.tar.gz

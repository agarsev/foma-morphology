SHELL:=/bin/bash

COMPILE:=foma/foma -q -l
LOOKUP:=foma/flookup -x
LOOKDOWN:=foma/flookup -x -i
CURL:=curl

BIN:=bin
SRC:=src

DATA:=$(wildcard data/*);

tom_url:=www.timesofmalta.com/articles/view/20141201/local/updated-applicants-for-malta-residence-permits-being-given-stolen-addresses.546492
pais_url:=http://politica.elpais.com/politica/2015/01/22/actualidad/1421925009_157997.html

all: tom.tok pais.tok

$(BIN)/%: $(SRC)/%.foma $(BIN)
	$(COMPILE) $< <<<"save stack $@" >/dev/null

%.raw:
	$(CURL) $($*_url) >$@

%.text: %.raw $(BIN)/normalise $(DATA)
	$(LOOKDOWN) $(BIN)/normalise <$< | tr -d '\n' > $@

%.tok: %.text $(BIN)/tokenize $(DATA)
	$(LOOKDOWN) $(BIN)/tokenize <$< | sed '/^$$/d' > $@

clean:
	rm -rf $(BIN) *.text *.tok

pristine: clean
	rm -f *.raw

$(BIN):
	mkdir $(BIN)

.PHONY: clean pristine

.SECONDARY:

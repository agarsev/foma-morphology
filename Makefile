COMPILE:=foma/foma -f
LOOKUP:=foma/flookup -x
LOOKDOWN:=foma/flookup -x -i
DATA:=$(wildcard data/*);
CURL:=curl

tom_url:=www.timesofmalta.com/articles/view/20141201/local/updated-applicants-for-malta-residence-permits-being-given-stolen-addresses.546492
pais_url:=http://politica.elpais.com/politica/2015/01/22/actualidad/1421925009_157997.html

all: tom.tok pais.tok

%.foma: %.regex
	$(COMPILE) $<

%.raw:
	$(CURL) $($*_url) >$@

%.text: %.raw normalise.foma $(DATA)
	cat $< | $(LOOKDOWN) normalise.foma | tr -d '\n' > $@

%.tok: %.text tokenize.foma $(DATA)
	cat $< | $(LOOKDOWN) tokenize.foma | sed '/^$$/d' > $@

clean:
	rm -f *.foma *.text *.tok

pristine: clean
	rm -f *.raw

.PHONY: clean pristine

.SECONDARY:

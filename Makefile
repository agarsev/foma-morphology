COMPILE:=foma/foma -f
LOOKUP:=foma/flookup -x
CURL:=curl

tom_url:=www.timesofmalta.com/articles/view/20141201/local/updated-applicants-for-malta-residence-permits-being-given-stolen-addresses.546492

all: tom.text

%.foma: %.regex
	$(COMPILE) $<

%.raw:
	$(CURL) $($*_url) >$@

%.text: %.raw normalise.foma
	cat $< | $(LOOKUP) normalise.foma | tr -d '\n' > $@

clean:
	rm -f *.foma *.raw *.text

.SECONDARY:

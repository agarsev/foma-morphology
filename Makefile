XFST:=bin/xfst -f
CURL:=curl

TOM:=www.timesofmalta.com/articles/view/20141201/local/updated-applicants-for-malta-residence-permits-being-given-stolen-addresses.546492

all: tom.text

.PHONY: $(TOM)

tom.raw: $(TOM)

%.raw:
	$(CURL) $< -o $@

%.text: %.raw
	head -5 $<

clean:
	rm -f *.raw *.text

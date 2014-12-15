XFST:=bin/xfst -f
CURL:=curl

tom_url:=www.timesofmalta.com/articles/view/20141201/local/updated-applicants-for-malta-residence-permits-being-given-stolen-addresses.546492

all: tom.text

%.raw:
	$(CURL) $($*_url) >$@

%.text: %.raw
	tr -d '\n' < $< | sed -e 's/<p>/\n<p>/g' -e 's/<\/p>/<\/p>\n/g' | grep -e '<p>' | sed 's/<[^>]*>//g' > $@

clean:
	rm -f *.raw *.text

.SECONDARY:

XFST:=bin/xfst -f
CURL:=curl

URL:=http://www.timesofmalta.com/articles/view/20141201/local/applicants-for-malta-residence-permits-being-given-stolen-addresses.546492

all: geturl

geturl:
	$(CURL) $(URL)

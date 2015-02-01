# TOOLS
SHELL:=/bin/bash
COMPILE:=foma/foma -q -l
LOOKUP:=foma/flookup -a
LOOKDOWN:=foma/flookup -x -i
CURL:=curl

# MAKEFILE OPTIONS
DICT_ES:=HAND
DICT_EN:=AUTO

VERBOSE:=yes

INFO=@echo -e "\e[92m"$(1)"\e[0m"
ifeq ($(VERBOSE), yes)
DEBUG=@echo -e "\e[96m"$(1)"\e[0m"
.SECONDARY:
else
.SILENT:
endif
.SECONDEXPANSION:
.SUFFIXES:

# DIRECTORIES
OUT:=out
SRC:=src
DATA:=data

# TARGETS
tom_url:=www.timesofmalta.com/articles/view/20141201/local/updated-applicants-for-malta-residence-permits-being-given-stolen-addresses.546492
dollar_url:=http://www.timesofmalta.com/articles/view/20141120/business-market-analysis/Dollar-is-at-seven-year-high-vs-yen.544851
pais_url:=http://politica.elpais.com/politica/2015/01/22/actualidad/1421925009_157997.html

ENGLISH:=tom dollar
SPANISH:=pais

$(ENGLISH): L:=EN
$(SPANISH): L:=ES

all: $(ENGLISH) $(SPANISH)

$(ENGLISH): %: %.morf %.hyp
$(SPANISH): %: %.morf %.hyp

# ANALYZER SCRIPTS
$(OUT)/analyze.%.foma: $(OUT)/closed.%.foma $(SRC)/case_ignore.foma $(SRC)/morfo.%.foma $(SRC)/case_ignore.foma $(SRC)/fallback.%.foma | $(DATA)/%/OP $(OUT)
	$(call DEBUG,"Compiling analyzer pipeline $+ -> $@ ($L)")
	cat $+ >$@

# SCRIPTS AND STACKS
$(OUT)/%: $(SRC)/%.foma | $(OUT)
	$(call DEBUG,"Compiling $< to $@")
	$(COMPILE) $< <<<"save stack $@" >/dev/null

$(OUT)/%: $(OUT)/%.foma | $(OUT)
	$(call DEBUG,"Compiling $< to $@")
	$(COMPILE) $< <<<"save stack $@" >/dev/null

$(OUT)/closed.%.foma: $(DATA)/%/CC/*.txt | $(OUT)
	$(call DEBUG,"Aggregating data to $@")
	>$@
	for c in $^; do \
		b=$${c%%.txt}; \
		echo "regex @txt\"$$c\" \"+$${b##*/}\":0;" >>$@; \
	done
	echo "union net" >>$@

# PIPELINE
%.raw:
	$(call INFO,"Downloading $@")
	$(CURL) $($*_url) >$@

%.text: %.raw $(OUT)/normalise
	$(call INFO,"Making $@ from $<")
	$(LOOKDOWN) $(OUT)/normalise <$< | tr -d '\n' > $@

%.tok: %.text $(OUT)/tokenize
	$(call INFO,"Making $@ from $<")
	$(LOOKDOWN) $(OUT)/tokenize <$< | sed '/^$$/d' > $@

%.hyp: %.tok $(OUT)/hyphenate.$$L
	$(call INFO,"Making $@ from $< ($L)")
	tr '[:upper:]' '[:lower:]' <$< | $(LOOKDOWN) $(OUT)/hyphenate.$L >$@

%.morf: %.tok $(OUT)/analyze.$$L
	$(call INFO,"Making $@ from $< ($L)")
	$(LOOKUP) $(OUT)/analyze.$L <$< > $@

# FOLDERS
$(OUT):
	mkdir -p $(OUT)

$(DATA)/%/OP:
	cd $(DATA)/$* && ln -s $(DICT_$*) OP

# UTILITIES
clean:
	rm -rf $(OUT) $(DATA)/EN/OP $(DATA)/ES/OP *.morf *.text *.tok *.hyp

pristine: clean
	rm -f *.raw

.PHONY: clean pristine

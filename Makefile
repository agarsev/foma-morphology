# TOOLS
SHELL:=/bin/bash
COMPILE:=foma/foma -q -l
LOOKUP:=foma/flookup -a
LOOKDOWN:=foma/flookup -x -i
CURL:=curl

# DIRECTORIES AND DATA
OUT:=out
SRC:=src
DATA:=data

# TARGETS
tom_url:=www.timesofmalta.com/articles/view/20141201/local/updated-applicants-for-malta-residence-permits-being-given-stolen-addresses.546492
pais_url:=http://politica.elpais.com/politica/2015/01/22/actualidad/1421925009_157997.html

all: tom.EN.morf tom.EN.hyp pais.ES.hyp

# ANALYZER SCRIPTS
$(OUT)/english.foma: $(OUT)/closed.EN.foma $(SRC)/fallback.EN.foma

# SCRIPTS AND STACKS
$(OUT)/%: $(SRC)/%.foma $(OUT)
	$(COMPILE) $< <<<"save stack $@" >/dev/null

$(OUT)/%: $(OUT)/%.foma $(OUT)
	$(COMPILE) $< <<<"save stack $@" >/dev/null

$(OUT)/closed.%.foma: $(DATA)/%/cc_*.txt
	>$@
	for c in $^; do \
		b=$${c%%.txt}; \
		echo "regex @txt\"$$c\" \"+$${b##*cc_}\":0;" >>$@; \
	done
	echo "union net" >>$@

$(OUT)/%.foma:
	>$@
	for script in $^; do \
		echo "source $$script" >>$@; \
	done

# PIPELINE
%.raw:
	$(CURL) $($*_url) >$@

%.text: %.raw $(OUT)/normalise
	$(LOOKDOWN) $(OUT)/normalise <$< | tr -d '\n' > $@

%.tok: %.text $(OUT)/tokenize
	$(LOOKDOWN) $(OUT)/tokenize <$< | sed '/^$$/d' > $@

%.ES.hyp: %.tok $(OUT)/hyphenate_es
	tr '[:upper:]' '[:lower:]' <$< | $(LOOKDOWN) $(OUT)/hyphenate_es >$@

%.EN.hyp: %.tok $(OUT)/hyphenate_en
	tr '[:upper:]' '[:lower:]' <$< | $(LOOKDOWN) $(OUT)/hyphenate_en >$@

%.EN.morf: %.tok $(OUT)/english
	$(LOOKUP) $(OUT)/english <$< > $@

# UTILITIES
clean:
	rm -rf $(OUT) *.morf *.text *.tok *.hyp

pristine: clean
	rm -f *.raw

$(OUT):
	mkdir -p $(OUT)

.PHONY: clean pristine

.SECONDARY:

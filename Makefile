# Makefile
# ========
# This makefile specifies how to compile the foma scripts and how to process
# every step in the pipeline

# Targets
# -------
# Specify here short names for each article, under the corresponding language.
# Then add the url from where it is to be retrieved.
ENGLISH:=tom dollar
SPANISH:=pais

tom_url:=www.timesofmalta.com/articles/view/20141201/local/updated-applicants-for-malta-residence-permits-being-given-stolen-addresses.546492
dollar_url:=http://www.timesofmalta.com/articles/view/20141120/business-market-analysis/Dollar-is-at-seven-year-high-vs-yen.544851
pais_url:=http://politica.elpais.com/politica/2015/01/22/actualidad/1421925009_157997.html

# Options
# -------

# What dictionary to use for Spanish. This is symlinked to OP (open class).
DICT_ES:=HAND
# What dictionary to use for English. This is symlinked to OP (open class).
DICT_EN:=AUTO
# If `yes`, information on the scripts being compiled is printed, and the
# commands being executed.
VERBOSE:=yes

# Directories
# -----------

# Compiled binaries and automatically built scripts go here.
OUT:=out
# Here is the source code for the transducers.
SRC:=src
# Word lists go into this directory.
DATA:=data

# Programs
# --------
# If any of these necessary programs is installed in a different path, change it
# here.
SHELL:=/bin/bash
COMPILE:=foma/foma -q -l
LOOKUP:=foma/flookup -a
LOOKDOWN:=foma/flookup -x -i
CURL:=curl

# How much information to show. INFO and DEBUG messages are colored.
INFO=@echo -e "\e[92m"$(1)"\e[0m"
ifeq ($(VERBOSE), yes)
DEBUG=@echo -e "\e[96m"$(1)"\e[0m"
.SECONDARY:
else
.SILENT:
endif

# Other makefile specific options.
.SECONDEXPANSION:
.SUFFIXES:

# What file suffix to use for the languages.
$(ENGLISH): L:=EN
$(SPANISH): L:=ES

# We build all targets in both languages, and for each of them we build the
# morphological analysis and the hyphenation
all: $(ENGLISH) $(SPANISH)

$(ENGLISH): %: %.morf %.hyp
$(SPANISH): %: %.morf %.hyp

# Analyzer pipeline
# -----------------
# The pipeline is written as dependencies, which are concatenated into a single
# script that is theh compiled. First the closed class script, then the
# morphological analyzer, and then the fallback. Case ignoring is used in some
# points of the pipeline.
$(OUT)/analyze.%.foma: $(OUT)/closed.%.foma $(SRC)/case_ignore.foma $(SRC)/morfo.%.foma $(SRC)/case_ignore.foma $(SRC)/fallback.%.foma | $(DATA)/%/OP $(OUT)
	$(call DEBUG,"Compiling analyzer pipeline $+ -> $@ ($L)")
	cat $+ >$@

# Compiler recipes
# ----------------

# The `save stack` command is given to foma to compile a script into a binary stack.
$(OUT)/%: $(SRC)/%.foma | $(OUT)
	$(call DEBUG,"Compiling $< to $@")
	$(COMPILE) $< <<<"save stack $@" >/dev/null

$(OUT)/%: $(OUT)/%.foma | $(OUT)
	$(call DEBUG,"Compiling $< to $@")
	$(COMPILE) $< <<<"save stack $@" >/dev/null

# The closed class script is automatically built from the closed class word
# lists with a bit of shell magic.
$(OUT)/closed.%.foma: $(DATA)/%/CC/*.txt | $(OUT)
	$(call DEBUG,"Aggregating data to $@")
	>$@
	for c in $^; do \
		b=$${c%%.txt}; \
		echo "regex @txt\"$$c\" \"+$${b##*/}\":0;" >>$@; \
	done
	echo "union net" >>$@

# PIPELINE
# ========
# Each intermediate output is kept if verbose is yes, indicated by a different
# file extension. If verbose is no, intermediate results are discarded, and only
# the end result is kept.

# Files downloaded from the internet.
%.raw:
	$(call INFO,"Downloading $@")
	$(CURL) $($*_url) >$@

# Normalised text, html removed. Newlines are also removed because they mean
# something special to foma.
%.text: %.raw $(OUT)/normalise
	$(call INFO,"Making $@ from $<")
	$(LOOKDOWN) $(OUT)/normalise <$< | tr -d '\n' > $@

# List of tokens. Empty lines are removed for cleanliness.
%.tok: %.text $(OUT)/tokenize
	$(call INFO,"Making $@ from $<")
	$(LOOKDOWN) $(OUT)/tokenize <$< | sed '/^$$/d' > $@

# Hyphenated tokens, one per line. Case is completely ignored for hyphenation.
%.hyp: %.tok $(OUT)/hyphenate.$$L
	$(call INFO,"Making $@ from $< ($L)")
	tr '[:upper:]' '[:lower:]' <$< | $(LOOKDOWN) $(OUT)/hyphenate.$L >$@

# Morphologically analyzed tokens, one per line. After a tab, an optional lexeme
# and a list of tags are written.
%.morf: %.tok $(OUT)/analyze.$$L
	$(call INFO,"Making $@ from $< ($L)")
	$(LOOKUP) $(OUT)/analyze.$L <$< > $@

# Other Makefile commands
# -----------------------

# Make the out folder if it doesn't exist.
$(OUT):
	mkdir -p $(OUT)

# Link the dictionary to be used for each language to `OP` (open class).
$(DATA)/%/OP:
	cd $(DATA)/$* && ln -s $(DICT_$*) OP

# Remove compiled and processed results.
clean:
	rm -rf $(OUT) $(DATA)/EN/OP $(DATA)/ES/OP *.morf *.text *.tok *.hyp

# Remove everything, including downloaded pages.
pristine: clean
	rm -f *.raw

.PHONY: clean pristine

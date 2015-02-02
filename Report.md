# Computational Morphology Final Assignment

_Antonio F. García Sevilla <antonio@garciasevilla.com>_

## Introduction

This assignment consists in the construction of a pipeline of xfst transducers,
which make all the process from text in a webpage (html-formatted) to a
morphological analysis of its words.

Instead of xfst, the open-source [foma](https://code.google.com/p/foma/) is
used. It's syntax-compatible with xfst, and most of the functionality is the same.

The whole pipeline is implemented as an automatic process for two languages:
English and Spanish. Slightly different design decision have been made for each
of the languages in some points, so as to be able to compare the different
possibilities.

To run the code and get the results, simply issue the command

`$ make`

A POSIX-compatible shell is required, and
GNU Makefile has to be installed. `curl` and `bash` are also needed. All of this
can be found in any standard UNIX-like environment. Results can be cleaned with

`$ make clean`

## Code Structure

The code and data for this assignment is organized in the following directory
structure:
- `src`: foma scripts for each transducer in the pipeline
- `data`: word lists for the different transducers.
- `out`: automatically created, it holds compiled transducers and other intermediate code.
- `foma`: where the foma utilities are.

The foma scripts which constitute the assignment's code are in the following
list. Please click on each of them for the detailed documentation.
- [`normalise.foma`](docs/normalise.html): An html to text normaliser transducer.
- [`tokenize.foma`](docs/tokenize.html): A transducer for taking continuous text and dividing it up into tokens.
- [`morfo.EN.foma`](docs/morfo.EN.html): English morphological analyzer.
- [`fallback.EN.foma`](docs/fallback.EN.html): Transducer for tag-guessing for English.
- [`hyphenate.EN.foma`](docs/hyphenate.EN.html): A hyphenator for English.
- [`morfo.ES.foma`](docs/morfo.ES.html): Spanish morphological analyzer.
- [`verbs.ES.foma`](docs/verbs.ES.html): The Spanish morphology verbal component.
- [`fallback.ES.foma`](docs/fallback.ES.html): Transducer for tag-guessing for Spanish.
- [`hyphenate.ES.foma`](docs/hyphenate.ES.html): A hyphenator for Spanish.
- [`case_ignore.foma`](docs/case_ignore.html): A simple transducer that makes the previous one case-insensitive.

Additionally, the `Makefile` used for pipeline composition is also documented
[here](docs/Makefile.html).

## Description

### Pipeline

The gluing component that holds the pipeline together is the `Makefile`. It
specifies how to construct every different intermediate result from the previous
one, by passing it through the corresponding transducer. It is also in charge of
compiling these transducers by calling the appropriate `foma` commands, and of
applying them with `lookup`. For more details see its [page](docs/Makefile.html).

The first component of the pipeline is an url where to fetch the resource. This
is an online source that can be downloaded. When downloaded, the content is
stored in a `.raw` file. The `.raw` file is processed by the normaliser, which
outputs a `.text` file. This file is then tokenized, into a `.tok` file. These
processes are language-independent.

The next steps in the pipeline are language-dependent, and so transducers are
appended extensions of either `.EN` for English or `.ES` for Spanish. The
Makefile is told in the first section what language to use for each target.
Thus, the
tokenized file can be processed by two different components. The morphological
analyzer adds to each token a morphological tag (different for the two
languages), and outputs the result to a `.morf` file. The hyphenator divides
each token into syllables, and writes the result to a `.hyp` file.

After running the code, in the root directory should reside all these files, so
the different processes and intermediate results can be examined. This
architecture is also good for development, since it organizes the process in
steps and lets the compiler only rebuild the necessary parts.

### Design of the analyzer

The morphological analyzer in itself is also a pipeline. The first thing that is
tried are closed-class words. These words are listed in files in the
`data/LANG/CC`
directory, and a foma script that matches them is automatically compiled by the
`Makefile`. Each component of the pipeline is laid onto the stack, and `foma` is
told to try each one alternatively. This simulates a priority union, in that if
a match is found in the first transducer in the stack, no further transducers
are tried. This allows a number of fallback transducers to be appended on top of
the stack, to guess a tag if the main analyzer fails. These are described in the
_fallback_ foma scripts.

The main analyzer lies between the closed-class finder (first component) and the
fallback analyzers. The analyzers for the two languages are different, but the
main structure is the same. First, the lexemes for the different part-of-speech
tags are loaded from the word lists in `data/LANG/OP`. These are appended with
suffix information. The suffixes are themselves transducers, that match
morphological information in the upper side (tags) with the surface realization
on the lower side.

This is all compiled into a "Lexicon" transducer, and after this, a series of
ortographic rules are applied, which generate the types of morpheme boundary
phenomena that are pervasive in fusional languages such as English or Spanish.

For the actual morphological analyzer description please read the documentation for
each file, e.g. [the English main component](docs/morfo.EN.html) or [the Spanish one](docs/morfo.ES.html). The other components of the pipeline are also described in this way, and are accesible either previously in this file or through the "Jump to" menu on the top right corner in each file.

### English-Spanish differences

English and Spanish are both fusional, Indo-European languages, so
morphologically they are somewhat similar. Still, differences can be appreciated
in the code, and in a deeper analysis more differences would appear.

In this assignment, some design decisions have been made different in both
languages to showcase the options. On one hand is the question of the word lists, or
dictionaries. The English wordlist is downloaded from the internet, and thus is
very broad coverage. However, there is also a lot of extraneous ambiguity due to
the noisy nature of internet data, and the fact that many words in English can
act as different parts of speech with the same spelling. It is found in the
`data/EN/AUTO` directory.

The Spanish dictionary, though, is hand constructed for the article to be
tested. That means that it performs very well on it, but less so on additional
articles that might be tried. For these articles, the lexemes should be appended
to the corresponding list. However, this decision also makes possible to let out
a large number of words from the dictionary, to test the performance of the
fallback transducers. In fact, this is done with most nouns, which the fallback
transducers should be able to analyze (and even extract gender and number) since
they have a somewhat regular morphology. The Spanish dictionary is in the
directory `data/ES/HAND`.

Of course, for both languages closed-class word lists can be found on the
internet and then manually tweaked for an almost 100% precision.

Another difference in the two languages is the tagset. The English tagset chosen
is a subset of the well-known Penn treebank tagset. It is not exactly the same
because the PTB tags are context disambiguated with syntactical and even
semantical information, which is not available here. However, these tags encode
most morphological information in English, and even if they are not structured
(just one tag per word) they are a good and standard way for representing this.

For the Spanish data, an ad-hoc tagging scheme, similar to that used in Spanish
schools is used. The main part of speech is detected (names are in Spanish), and
then whatever extra morphological information can be deduced is added in the
form of tags. These tags often correspond to regular morphemes, and present the
main morphological information that can be extracted.

### Caveats

For both languages, only inflectional processes are studied. Derivation is also
a common process in fusional languages, and morphemes can be detected. However,
this lies out of the scope of the project, and the different tools used
summarize quite well the steps that would be necessary in order to build also a
derivational analyzer.

It is also to note that the grammatical coverage of the languages performed is
not intended to be exhaustive, but rather a display of the tools and
possibilities that transducers allow. A lot of corner cases are probably
missing, and the list of irregular forms covered is very small. However, for
regular morphology almost everything is supposed to be covered, and it is
pleasant to see that it can be done in a reasonably small amount of code.

### Note on flag diacritics

For the Spanish verbal system, an advanced feature of xfst/foma is used, that is
flag diacritics. It is a powerful system, and allows to distinguish different
inflection paradigms when they have only particular differences. It is, however,
a bit tricky to use, and not necessary, since everything can be handled by
multiplicating the transducers' paths. It may be the weakest part of the
analyzer, but it is very interesting, and makes the code smaller and more
intuitive.

Another comment on the Spanish verbal system is that, in retrospective, a two
layer transducer might be too small. After having completed the analyzer, it is
apparent that having at least one more layer would make it easier to cover some
"regular irregularities". They can be covered with the current system, though,
and it only makes it a little more involved.

For details on the Spanish verbal system see the file [verbs.ES.foma](docs/verbs.ES.html).

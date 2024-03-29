TEX = pdflatex -shell-escape -interaction nonstopmode -halt-on-error -file-line-error
CHK = chktex -shell-escape -interaction nonstopmode -halt-on-error -file-line-error
BIB = bibtex
MAIN = whitepaper
SRC = $(MAIN).tex
OUT = $(MAIN).pdf
MD = Periodically-Syncing-HyperChains
MD_SRC = $(MD).md
MD_TEX = $(MD).tex
MD_OUT = $(MD).pdf
SRCS = $(shell find . -name "*.tex")
TEXTDIR = ./
TEXT = $(shell find $(TEXTDIR) -name "*.tex")
DICT = $(TEXTDIR)/.aspell.en.pws
REPL = $(TEXTDIR)/.aspell.en.prepl

.PHONY : all clean splchk

all : $(OUT) $(MD_OUT) # check splchk

$(MD_OUT): $(MD_TEX)
	$(TEX) $(MD_TEX)

 $(MD_TEX): $(MD_SRC)
	pandoc $(MD_SRC) -s -o $(MD_TEX)

check: $(SRCS)
	! $(CHK) $(MAIN) | grep .

clean:
	-rm -f *.aux
	-rm -f *.log
	-rm -f *.pdf
	-rm -f *.toc
	-rm -f *.out
	-rm -f *.bbl
	-rm -f *.blg
	-rm -f $(MD_TEX)

$(MAIN).pdf: $(SRC)
	$(TEX) $(MAIN)
	$(BIB) $(MAIN)
	$(TEX) $(MAIN)

$(MAIN) : $(SRCS)
	$(TEX) $(SRC) && $(BIB) $(MAIN) && $(TEX) $(SRC) && $(TEX) $(SRC)

%.chk: %.tex
	aspell \
		--home-dir=./$(TEXTDIR) \
		--personal=$(DICT) \
		--repl=$(REPL) \
		--lang=en_US \
		--mode=tex \
		--add-tex-command="autoref op" \
		-x \
		check $<

splchk: $(DICT) $(REPL) $(addsuffix .chk,$(basename $(TEXT)))


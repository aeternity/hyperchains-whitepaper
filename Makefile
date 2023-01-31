TEX = pdflatex -shell-escape -interaction nonstopmode -halt-on-error -file-line-error
CHK = chktex -shell-escape -interaction nonstopmode -halt-on-error -file-line-error
BIB = bibtex
MAIN = whitepaper
SRC = $(MAIN).tex
OUT = $(MAIN).pdf
SRCS = $(shell find . -name "*.tex")
TEXTDIR = ./
TEXT = $(shell find $(TEXTDIR) -name "*.tex")
DICT = $(TEXTDIR)/.aspell.en.pws
REPL = $(TEXTDIR)/.aspell.en.prepl

.PHONY : all clean splchk

all : $(OUT) # check splchk

check: $(SRCS)
	! $(CHK) $(MAIN) | grep .

clean :
	-rm -f *.{aux,log,pdf,toc,out,bbl,blg}

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


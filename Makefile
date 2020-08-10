TEX = pdflatex -shell-escape -interaction nonstopmode -halt-on-error -file-line-error
CHK = chktex -shell-escape -interaction nonstopmode -halt-on-error -file-line-error
MAIN = whitepaper.tex
OUT = $(basename $(MAIN)).pdf
SRCS = $(shell find . -name "*.tex")
TEXTDIR = ./
TEXT = $(shell find $(TEXTDIR) -name "*.tex")
DICT = $(TEXTDIR)/.aspell.en.pws
REPL = $(TEXTDIR)/.aspell.en.prepl

.PHONY : all clean splchk

all : $(OUT) check splchk

check: $(SRCS)
	! $(CHK) $(MAIN) | grep .

clean :
	-rm -f *.{aux,log,pdf,toc,out}

$(OUT) : $(SRCS)
	$(TEX) $(MAIN) && $(TEX) $(MAIN)

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


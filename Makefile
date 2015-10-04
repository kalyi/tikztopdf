SCRIPT = tikztopdf.sh
BIN ?= tikztopdf
PREFIX ?= $(HOME)

install:
	cp $(SCRIPT) $(PREFIX)/bin/$(BIN)

uninstall:
	rm -f $(PREFIX)/bin/$(BIN)

test:
	echo -e "\node[circle,draw=red] { Hello there!};" > test.tikz.tex
	$(BIN) test.tikz.tex
	test -f test.pdf && echo "Success." || echo "Failed."

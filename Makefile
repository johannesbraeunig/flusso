PREFIX ?= /usr/local

install:
	install -d $(PREFIX)/bin
	install -m 755 flusso $(PREFIX)/bin/flusso

uninstall:
	rm -f $(PREFIX)/bin/flusso

.PHONY: install uninstall

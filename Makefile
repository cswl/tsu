.PHONY: all lint prettify

PREFIX ?= /data/data/com.termux/files/usr/local

all:

lint:
	./lint.sh

prettify:
	./prettify.sh

install:
	mkdir -p $(PREFIX)/bin/
	install -m700 tsu $(PREFIX)/bin/
	install -m700 tsudo $(PREFIX)/bin/

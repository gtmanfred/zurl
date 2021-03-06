OUT	        = zurl
VERSION	    = $(shell git describe)

DISTFILES   = Makefile README.pod zurl.zsh zurlrc

PREFIX     ?= /usr/local
MANPREFIX  ?= ${PREFIX}/share/man

all: doc

doc: zurl.1
zurl.1: README.pod
	pod2man --section=1 --center="Zurl Manual" --name "ZURL" --release="zurl ${VERSION}" $< > $@

install: zurl.1
	install -D -m755 zurl.zsh ${DESTDIR}${PREFIX}/bin/zurl
	install -D -m644 zurl.1 ${DESTDIR}${MANPREFIX}/man1/zurl.1
	install -D -m644 zurlrc ${DESTDIR}/etc/zurlrc

uninstall: 
	@echo removing executable file from ${DESTDIR}${PREFIX}/bin
	rm -f ${DESTDIR}${PREFIX}/bin/zurl
	@echo removing man page from ${DESTDIR}${MANPREFIX}/man1
	rm -f ${DESTDIR}${MANPREFIX}/man1/zurl.1
	@echo removing default config from ${DESTDIR}/etc/zurlrc
	rm -f ${DESTDIR}/etc/zurlrc

.PHONY: doc install uninstall

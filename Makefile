
PKGNAME	    = $(shell oasis query name)
PKGVERSION  = $(shell oasis query version)
PKG_TARBALL = $(PKGNAME)-$(PKGVERSION).tar.gz

DISTFILES   = LICENSE.txt AUTHORS.txt INSTALL.txt README.txt _oasis \
	_tags META Makefile ANSITerminal.mllib libANSITerminal.clib \
	ANSITerminal_unix_stubs.c ANSITerminal_win_stubs.c \
	setup.ml API.odocl \
	$(wildcard *.ml) $(wildcard *.mli) $(wildcard examples/)

WEB = shell.forge.ocamlcore.org:/home/groups/ansiterminal/htdocs

.PHONY: all byte native configure doc install uninstall reinstall upload-doc

all byte native setup.log: setup.data
	ocaml setup.ml -build

configure: setup.data
setup.data: setup.ml
	ocaml setup.ml -configure

setup.ml: _oasis
	oasis setup -setup-update dynamic

doc install uninstall reinstall: setup.log
	ocaml setup.ml -$@

upload-doc: doc
	scp -C -p -r _build/API.docdir $(WEB)


# Make a tarball
.PHONY: dist tar
dist tar: $(DISTFILES)
	@ if [ -z "$(PKGNAME)" ]; then echo "PKGNAME not defined"; exit 1; fi
	@ if [ -z "$(PKGVERSION)" ]; then \
		echo "PKGVERSION not defined"; exit 1; fi
	mkdir $(PKGNAME)-$(PKGVERSION)
	cp -ar $(DISTFILES) $(PKGNAME)-$(PKGVERSION)/
#	Make a setup.ml that does not need oasis.
	cd $(PKGNAME)-$(PKGVERSION) && oasis setup
	tar -zcvf $(PKG_TARBALL) $(PKGNAME)-$(PKGVERSION)
	rm -rf $(PKGNAME)-$(PKGVERSION)


.PHONY: clean distclean
clean::
	ocaml setup.ml -clean
	$(RM) $(PKG_TARBALL)

distclean:
	ocaml setup.ml -distclean
	$(RM) $(wildcard *.ba[0-9] *.bak *~ *.odocl)

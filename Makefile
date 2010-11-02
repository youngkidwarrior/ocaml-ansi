
PKGNAME	   = $(shell grep "name" META.in | sed -e "s/.*\"\([^\"]*\)\".*/\1/")
PKGVERSION = $(shell grep "@version" ANSITerminal.mli | \
		  sed -e "s/[ *]*@version *\([0-9.]\+\).*/\1/")

SOURCES = ANSITerminal_common.ml ANSITerminal.ml ANSITerminal.mli
EXAMPLES = showcolors.ml test.ml
OCAMLPACKS = unix

DISTFILES    = LICENSE META.in Makefile Make.bat INSTALL README \
		$(wildcard *.ml) $(wildcard *.mli) $(wildcard examples/)

PKG_TARBALL  = $(PKGNAME)-$(PKGVERSION).tar.bz2

INTERFACES = ANSITerminal.mli
DOCFILES = $(INTERFACES)
WEB = shell.forge.ocamlcore.org:/home/groups/ansiterminal/htdocs

.PHONY: all opt byte mli
all: byte opt
byte: ANSITerminal.cma
opt: ANSITerminal.cmxa

ANSITerminal.ml: ANSITerminal_unix.ml
	cp $< $@
ANSITerminal.cmo ANSITerminal.cmx: ANSITerminal.cmi

ANSITerminal.cma ANSITerminal.cmxa: ANSITerminal_common.ml ANSITerminal.ml \
  ANSITerminal_unix_stubs.o
	ocamlmklib -o $(basename $@) $^

ANSITerminal_unix_stubs.o: ANSITerminal_unix_stubs.c
	$(OCAMLC) -c $<

META: META.in
	sed -e "s/@VERSION@/$(PKGVERSION)/" $^ | \
	sed -e "s/@REQUIRES@/$(OCAMLPACKS)/" > $@

# (Un)installation
.PHONY: install uninstall
install: all META
	ocamlfind install $(PKGNAME) META $(INTERFACES) \
	  $(INTERFACES:.mli=.cmi) ANSITerminal.cma \
	  $(wildcard ANSITerminal.cmxa ANSITerminal.a ANSITerminal.cmx)

uninstall:
	ocamlfind remove $(PKGNAME)

reinstall:
	$(MAKE) uninstall
	$(MAKE) install

# Make the examples
.PHONY: ex examples
ex: examples
examples: $(EXAMPLES:.ml=.exe) $(EXAMPLES:.ml=.com)

$(EXAMPLES:.ml=.exe): ANSITerminal.cma
$(EXAMPLES:.ml=.com): ANSITerminal.cmxa
# Include the current directory to find -lANSITerminal
$(EXAMPLES:.ml=.com): OCAMLOPT_FLAGS=-I .

.PHONY: doc upload-doc
# Compile HTML documentation
doc: $(DOCFILES) $(CMI_FILES)
	@if [ -n "$(DOCFILES)" ] ; then \
	    if [ ! -x $(PKGNAME).html ] ; then mkdir $(PKGNAME).html ; fi ; \
	    $(OCAMLDOC) -v -d $(PKGNAME).html -html -stars -colorize-code \
		-I +contrib $(ODOC_OPT) $(DOCFILES) ; \
	fi

upload-doc: doc
	scp -r $(PKGNAME).html $(WEB)

# Make a tarball
.PHONY: dist
dist: $(DISTFILES)
	@ if [ -z "$(PKGNAME)" ]; then echo "PKGNAME not defined"; exit 1; fi
	@ if [ -z "$(PKGVERSION)" ]; then \
		echo "PKGVERSION not defined"; exit 1; fi
	mkdir $(PKGNAME)-$(PKGVERSION)
#	mv Make.bat $(PKGNAME)-$(PKGVERSION)
	cp -r $(DISTFILES) $(PKGNAME)-$(PKGVERSION)/
	tar --exclude "*~" --exclude "*.cm{i,x,o,xa}" --exclude "*.o" \
	   --dereference \
	  -jcvf $(PKG_TARBALL) $(PKGNAME)-$(PKGVERSION)
	rm -rf $(PKGNAME)-$(PKGVERSION)

include Makefile.ocaml


.PHONY: clean distclean
clean::
	$(RM) -f META $(PKGNAME)-$(PKGVERSION).tar.bz2 $(wildcard *.so)
	$(RM) -rf $(PKGNAME).html/
	find . -type f -perm +u=x -exec rm -f {} \;

distclean: clean
	rm -f config.status config.cache config.log .depend

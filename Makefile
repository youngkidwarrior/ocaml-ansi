
PKGNAME	   = $(shell grep "name" META.in | sed -e "s/.*\"\([^\"]*\)\".*/\1/")
PKGVERSION = $(shell grep "@version" ANSITerminal.mli | \
		  sed -e "s/[ *]*@version *\([0-9.]\+\).*/\1/")

SRC_WEB    = web
SF_WEB     = 

BYTE_OBJS    := ANSITerminal.cmo
OPT_OBJS     := $(BYTE_OBJS:.cmo=.cmx)
REQUIRES     := 
PREDICATES   :=

OCAMLC       := ocamlc -dtypes
OCAMLOPT     := ocamlopt
OCAMLDEP     := ocamldep
OCAMLLEX     := ocamllex
OCAMLYACC    := ocamlyacc
OCAMLDOC     := ocamldoc
OCAMLFIND    := ocamlfind

DISTFILES    = LICENSE META.in Makefile Make.bat INSTALL README \
		$(wildcard *.ml) $(wildcard *.mli) $(wildcard examples/)

PKG_TARBALL  = $(PKGNAME)-$(PKGVERSION).tar.bz2
ARCHIVE   = $(shell grep "archive(byte)" META.in | \
		sed -e "s/.*\"\([^\"]*\)\".*/\1/")
XARCHIVE  = $(shell grep "archive(native)" META.in | \
		sed -e "s/.*\"\([^\"]*\)\".*/\1/")

default: all

######################################################################

C_FILES   := $(wildcard *.c)
ML_FILES  := $(wildcard *.ml)
MLI_FILES := $(wildcard *.mli)
CMI_FILES := $(addsuffix .cmi,$(basename $(MLI_FILES)))

C_OBJS    := $(if $(C_FILES),$(PKGNAME).o $(C_OBJS),)
BYTE_OBJS := $(if $(ML_FILES),$(BYTE_OBJS) $(ARCHIVE:.cma=.cmo),)
OPT_OBJS  := $(if $(ML_FILES),$(OPT_OBJS) $(XARCHIVE:.cmxa=.cmx),)

DOCFILES  += $(MLI_FILES)

PKGS = $(shell grep "requires" META.in | sed -e "s/.*\"\([^\"]*\)\".*/\1/")
PKGS_CMA 	= $(addsuffix .cma, $(PKGS))
OCAML_STDLIB 	= $(shell ocamlc -where)


.PHONY: all opt byte mli
#all: $(C_OBJS) $(CMI_FILES) byte opt
all: $(CMI_FILES) byte opt
byte: $(ARCHIVE)
opt: $(XARCHIVE)

$(ARCHIVE): $(BYTE_OBJS)
	$(OCAMLC) -a -o $@ $(PREDICATE_OPTS) $^

$(XARCHIVE): $(OPT_OBJS)
	$(OCAMLOPT) -a -o $@ $(PREDICATE_OPTS) $^


.SUFFIXES: .cmi .cmo .cma .cmx .cmxa .ml .mli

%.cmi: %.mli
	$(OCAMLC) $(PKGS_CMA) -c $<

%.cmo: %.ml
	$(OCAMLC) $(PKGS_CMA) -c $<

%.cmx: %.ml
	$(OCAMLOPT) $(PKGS_CMA:.cma=.cmxa) -c $<

%.cmxa: %.cmx
	$(OCAMLOPT) -a -o $@ $^

%.o: %.c
	$(CC) -c -I. -I$(OCAML_STDLIB)/caml $<

%.exe: %.ml byte
	$(OCAMLC) -o $@ $(ARCHIVE) $<

.PHONY: dep
dep: .depend
.depend: $(ML_FILES) $(MLI_FILES)
	$(OCAMLDEP) $(SYNTAX_OPTS) $(ML_FILES) $(MLI_FILES) > $@
include .depend

META: META.in
	cp $^ $@
	echo "version = \"$(PKGVERSION)\"" >> $@

# (Un)installation
.PHONY: install uninstall
install: all META
	ocamlfind remove $(PKGNAME); \
	[ -f "$(XARCHIVE)" ] && \
	extra="$(XARCHIVE) $(basename $(XARCHIVE)).a"; \
	ocamlfind install $(PKGNAME) $(MLI_FILES) $(CMI_FILES) $(ARCHIVE) META $$extra $(C_OBJS)

uninstall:
	ocamlfind remove $(PKGNAME)

# Make the examples
.PHONY: ex examples
ex: examples
examples: byte showcolors.exe

# Compile HTML documentation
doc: $(DOCFILES) $(CMI_FILES)
	@if [ -n "$(DOCFILES)" ] ; then \
	    if [ ! -x $(PKGNAME).html ] ; then mkdir $(PKGNAME).html ; fi ; \
	    $(OCAMLDOC) -v -d $(PKGNAME).html -html -stars -colorize-code \
		-I +contrib $(ODOC_OPT) $(DOCFILES) ; \
	fi

# Make a tarball
.PHONY: dist
dist: $(DISTFILES)
	@ if [ -z "$(PKGNAME)" ]; then echo "PKGNAME not defined"; exit 1; fi
	@ if [ -z "$(PKGVERSION)" ]; then \
		echo "PKGVERSION not defined"; exit 1; fi
	mkdir $(PKGNAME)-$(PKGVERSION)
#	mv Make.bat $(PKGNAME)-$(PKGVERSION)
	cp -r $(DISTFILES) $(PKGNAME)-$(PKGVERSION)/
	tar --exclude "CVS" --exclude ".cvsignore" --exclude "*~" \
	   --exclude "*.cm{i,x,o,xa}" --exclude "*.o" \
	   --dereference \
	  -jcvf $(PKG_TARBALL) $(PKGNAME)-$(PKGVERSION)
	rm -rf $(PKGNAME)-$(PKGVERSION)

# Release a tarball and publish the HTML doc 
-include Makefile.pub


.PHONY: clean distclean
clean:
	rm -f *~ *.cm[ioxa] *.cmxa *.[ao] *.tmp *.annot *.cache
	rm -f META $(PKGNAME)-$(PKGVERSION).tar.bz2
	rm -rf $(PKGNAME).html/
	if [ -d examples/ ]; then \
		cd examples/; $(MAKE) clean ; \
	fi
	find . -type f -perm +u=x -exec rm -f {} \;


distclean: clean
	rm -f config.status config.cache config.log .depend

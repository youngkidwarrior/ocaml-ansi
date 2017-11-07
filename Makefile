PKGVERSION = $(shell git describe --always --dirty)

build:
	jbuilder build @install --dev

all: build
	jbuilder build @runtest

test: all
	CAML_LD_LIBRARY_PATH=_build/src/ ./test.byte 


clean:
	jbuilder clean

.PHONY: all build test clean

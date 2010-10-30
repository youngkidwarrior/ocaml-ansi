REM Compile the project under windows (without needing "make")

SET OCAMLC=ocamlc
SET OCAMLCFLAGS=-dtypes
SET LIBS=ANSITerminal.cma

%OCAMLC% %OCAMLCFLAGS% -c ANSITerminal.mli
%OCAMLC% %OCAMLCFLAGS% -c ANSITerminal.ml
%OCAMLC% %OCAMLCFLAGS% -a -o %LIBS%  ANSITerminal.cmo

%OCAMLC% %OCAMLCFLAGS% -o showcolors.exe %LIBS% showcolors.ml

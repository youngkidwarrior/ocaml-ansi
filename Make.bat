REM Compile the project under windows (without needing "make")

SET OCAMLC=ocamlc
SET OCAMLCFLAGS=-annot
SET OCAMLOPT=ocamlopt
SET OCAMLOPTFLAGS=-annot
SET LIB_BYTE=ANSITerminal.cma
SET LIB_OPT=ANSITerminal.cmxa

copy ANSITerminal_windows.ml ANSITerminal.ml

ocamlc -c -I +caml win.c

%OCAMLC% %OCAMLCFLAGS% -c ANSITerminal.mli
%OCAMLC% %OCAMLCFLAGS% -c ANSITerminal.ml
%OCAMLC% %OCAMLCFLAGS% -a -o %LIB_BYTE%  ANSITerminal.cmo

%OCAMLOPT% %OCAMLOPTFLAGS% -c ANSITerminal.ml
%OCAMLOPT% %OCAMLOPTFLAGS% -a -o %LIB_OPT% ANSITerminal.cmx user32.lib win.obj

%OCAMLC% %OCAMLCFLAGS% -o showcolors.exe %LIB_BYTE% showcolors.ml
%OCAMLOPT% %OCAMLOPTFLAGS% -o showcolors.com %LIB_OPT% showcolors.ml
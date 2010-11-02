REM Compile the project under windows (without needing "make")

SET OCAMLC=ocamlc
SET OCAMLCFLAGS=-annot
SET OCAMLOPT=ocamlopt
SET OCAMLOPTFLAGS=-annot
SET LIB_BYTE=ANSITerminal.cma
SET LIB_OPT=ANSITerminal.cmxa

copy ANSITerminal_win.ml ANSITerminal.ml

ocamlc -c -I +caml ANSITerminal_win_stubs.c

%OCAMLC% %OCAMLCFLAGS% -c ANSITerminal.mli
%OCAMLC% %OCAMLCFLAGS% -c ANSITerminal.ml
%OCAMLC% %OCAMLCFLAGS% -c ANSITerminal_common.ml
%OCAMLC% %OCAMLCFLAGS% -a -o %LIB_BYTE%  ANSITerminal_common.cmo ANSITerminal.cmo

%OCAMLOPT% %OCAMLOPTFLAGS% -c ANSITerminal.ml
%OCAMLOPT% %OCAMLOPTFLAGS% -c ANSITerminal_common.ml
%OCAMLOPT% %OCAMLOPTFLAGS% -a -o %LIB_OPT% ANSITerminal_common.cmx ANSITerminal.cmx user32.lib ANSITerminal_win_stubs.obj

%OCAMLC% %OCAMLCFLAGS% -o showcolors.exe %LIB_BYTE% showcolors.ml
%OCAMLOPT% %OCAMLOPTFLAGS% -o showcolors.com %LIB_OPT% showcolors.ml
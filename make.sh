
mkdir _build -p
ocamlc -c ANSITerminal_unix_stubs.c 
mv -f ANSITerminal_unix_stubs.o _build

if [ "$1" = "native" ]
then 
  ocamlbuild -lib unix -lflag ANSITerminal_unix_stubs.o showcolors.native
  ./showcolors.native
elif [ "$1" = "byte" ]
then
  ocamlbuild -lib unix -lflags ANSITerminal_unix_stubs.o,-custom showcolors.byte
  ./showcolors.byte
else
  echo "use one of 'native', 'byte'"
fi
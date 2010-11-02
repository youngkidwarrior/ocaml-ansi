
open Printf
module T = ANSITerminal

let () =
  printf "Testing ANSITerminal...\n%!";
  let x, y = T.size() in
  printf "The size of the terminal is (%i,%i).%!" x y;
  let x, y = T.pos_cursor() in
  printf "\nThe cursor position was (%i,%i).\n%!" x y;
  T.save_cursor();
  T.set_cursor 3 3;
  printf "*<---(3,3)---";
  T.restore_cursor()

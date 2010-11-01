(* File: ANSITerminal_unix.ml
   Allow colors, cursor movements, erasing,... under Unix shells.
   *********************************************************************

   Copyright 2004 by Troestler Christophe
   Christophe.Troestler(at)umons.ac.be

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public License
   version 3 as published by the Free Software Foundation, with the
   special exception on linking described in file LICENSE.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
   LICENSE for more details.
*)
(** See the file(s) ctlseqs.* (unix; in Debian package xspecs)

    CSI = "\027[" (ESC [)

    man console_codes
*)

(* man tty(4) *)

open Printf
open Scanf
include ANSITerminal_colors

(* Erasing *)

let erase loc =
  print_string(match loc with
  | Eol -> "\027[K"
  | Above -> "\027[1J"
  | Below -> "\027[0J"
  | Screen -> "\027[2J")


(* Cursor *)

let set_cursor x y =
  if x <= 0 then (if y > 0 then printf "\027[%id" y)
  else (* x > 0 *) if y <= 0 then printf "\027[%iG" x
  else printf "\027[%i;%iH" y x

let move_cursor x y =
  if x > 0 then printf "\027[%iC" x
  else if x < 0 then printf "\027[%iD" (-x);
  if y > 0 then printf "\027[%iB" y
  else if y < 0 then printf "\027[%iA" (-y)

let save_cursor () = print_string "\027[s"
let restore_cursor () = print_string "\027[u"
let move_bol () = print_string "\r"

let with_ignored_signals f =
  let old_int = Sys.signal Sys.sigint Sys.Signal_ignore
  and old_quit = Sys.signal Sys.sigquit Sys.Signal_ignore
  and old_hup = Sys.signal Sys.sighup Sys.Signal_ignore
  and old_term = Sys.signal Sys.sigterm Sys.Signal_ignore in
  try
    let x = f() in
    Sys.set_signal Sys.sigterm old_term;
    Sys.set_signal Sys.sighup old_hup;
    Sys.set_signal Sys.sigquit old_quit;
    Sys.set_signal Sys.sigint old_int;
    x
  with e ->
    Sys.set_signal Sys.sigterm old_term;
    Sys.set_signal Sys.sighup old_hup;
    Sys.set_signal Sys.sigquit old_quit;
    Sys.set_signal Sys.sigint old_int;
    raise e

(* Inpired by http://www.ohse.de/uwe/software/resize.c.html *)
let input_answer fdin =
  let alarm = ref false in
  let set_alarm (_:int) = alarm := true in
  let old_alarm = Sys.signal Sys.sigalrm (Sys.Signal_handle set_alarm) in
  ignore(Unix.alarm 1);
  let buf = String.create 127 in
  let rec get_answer pos =
    let c = input_char fdin in
    if !alarm then pos
    else if buf.[pos] = '\000' then get_answer pos
    else if pos = 126 then pos + 1
    else get_answer (pos + 1) in
  let len = get_answer 0 in
  ignore(Unix.alarm 0);
  Sys.set_signal Sys.sigalrm old_alarm;
  String.sub buf 0 len

let pos_cursor () =
  with_ignored_signals (fun () ->
    save_cursor();
    print_string "\027[r"; (* turn scroll region off *)
    (* Query Cursor Position	<ESC>[6n *)
    print_string "\027[6n";
    (* Report Cursor Position	<ESC>[{ROW};{COLUMN}R *)
    try
      Scanf.sscanf (input_answer stdin) "\027[%d;%dR"
        (fun x y -> restore_cursor();  (x,y))
    with _ -> failwith "ANSITerminal.pos_cursor"
  )

(* See also the output of 'resize -s x y' (e.g. in an Emacs shell). *)
let resize width height =
  if width <= 0 then invalid_arg "ANSITerminal.resize: width <= 0";
  if height <= 0 then invalid_arg "ANSITerminal.resize: height <= 0";
  printf "\027[8;%i;%it%!" height width

(* FIXME: what about the following recipe:
   If you run
     echo -e "\e[18t"
   then xterm will respond with a line of the form
     ESC [ 8 ; height ; width t
   It generates this line as if it were typed input, so it can then be
   read by your program on stdin. *)
let size () =
  (* http://www.splode.com/~friedman/software/emacs-lisp/src/xterm-frobs.el *)
  printf "\027[18t%!";
  sscanf (input_answer stdin) "\027[8;%d;%dt" (fun x y -> x,y)


(* Scrolling *)

let scroll lines =
  if lines > 0 then printf "\027[%iS" lines
  else if lines < 0 then printf "\027[%iT" (- lines)


let style_to_string = function
  | Reset -> "0"
  | Bold -> "1"
  | Underlined -> "4"
  | Blink -> "5"
  | Inverse -> "7"
  | Hidden -> "8"
  | Foreground Black -> "30"
  | Foreground Red -> "31"
  | Foreground Green -> "32"
  | Foreground Yellow -> "33"
  | Foreground Blue -> "34"
  | Foreground Magenta -> "35"
  | Foreground Cyan -> "36"
  | Foreground White -> "37"
  | Foreground Default -> "39"
  | Background Black -> "40"
  | Background Red -> "41"
  | Background Green -> "42"
  | Background Yellow -> "43"
  | Background Blue -> "44"
  | Background Magenta -> "45"
  | Background Cyan -> "46"
  | Background White -> "47"
  | Background Default -> "49"


let print_string style txt =
  print_string "\027[";
  let s = String.concat ";" (List.map style_to_string style) in
  print_string s;
  print_string "m";
  print_string txt;
  if !autoreset then print_string "\027[0m"

let prerr_string style txt =
  prerr_string "\027[";
  let s = String.concat ";" (List.map style_to_string style) in
  prerr_string s;
  prerr_string "m";
  prerr_string txt;
  if !autoreset then prerr_string "\027[0m"


let printf style = ksprintf (print_string style)


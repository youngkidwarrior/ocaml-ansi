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

(* Erasing *)

type loc = Eol | Above | Below | Screen

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

let pos_cursor () = failwith "FIXME: to be implemented"


(* See also the output of 'resize -s x y' (e.g. in an Emacs shell). *)
let resize width height =
  if width <= 0 then invalid_arg "ANSITerminal.resize: width <= 0";
  if height <= 0 then invalid_arg "ANSITerminal.resize: height <= 0";
  printf "\027[8;%i;%it" height width


(* Inpired by http://www.ohse.de/uwe/software/resize.c.html *)
let input_answer fhin =
  let alarm = ref false in
  let set_alarm (_:int) = alarm := true in
  let old_alarm = Sys.signal Sys.sigalrm (Sys.Signal_handle set_alarm) in
  ignore(Unix.alarm 1);
  let buf = String.create 127 in
  let rec get_answer pos =
    let i = input fhin buf pos (127 - pos) in
    if !alarm then pos + i else i in (* FIXME: correct ? *)
  let len = get_answer 0 in
  ignore(Unix.alarm 0);
  Sys.set_signal Sys.sigalrm old_alarm;
  String.sub buf 0 len

(* FIXME: what about the following recipe:
   If you run
     echo -e "\e[18t"
   then xterm will respond with a line of the form
     ESC [ 8 ; height ; width t
   It generates this line as if it were typed input, so it can then be
   read by your program on stdin. *)
let size () =
  let old_int = Sys.signal Sys.sigint Sys.Signal_ignore
  and old_quit = Sys.signal Sys.sigquit Sys.Signal_ignore
  and old_hup = Sys.signal Sys.sighup Sys.Signal_ignore
  and old_term = Sys.signal Sys.sigterm Sys.Signal_ignore in
  save_cursor();
  print_string "\027[r"; (* turn scroll region off *)
  set_cursor 998 998; (* put cursor far, far away *)
  print_string "\027[6n"; (* ask terminal: `where is the cursor?' *)
  (* get terminal answer *)
  let height, width =
    try Scanf.sscanf (input_answer stdin) "\027[%d;%dR" (fun x y -> x,y)
    with _ -> failwith "ANSITerminal.size"  in
()  ; (* FIXME: set scroll region to exactly one screen *)
  restore_cursor();
  Sys.set_signal Sys.sigterm old_term;
  Sys.set_signal Sys.sighup old_hup;
  Sys.set_signal Sys.sigquit old_quit;
  Sys.set_signal Sys.sigint old_int;
  (width, height)


(* Scrolling *)

let scroll lines =
  if lines > 0 then printf "\027[%iS" lines
  else if lines < 0 then printf "\027[%iT" (- lines)

(* Colors *)

let autoreset = ref true

let set_autoreset b = autoreset := b


type color =
    Black | Red | Green | Yellow | Blue | Magenta | Cyan | White | Default

type style =
  | Reset | Bold | Underlined | Blink | Inverse | Hidden
  | Foreground of color
  | Background of color

let black = Foreground Black
let red = Foreground Red
let green = Foreground Green
let yellow = Foreground Yellow
let blue = Foreground Blue
let magenta = Foreground Magenta
let cyan = Foreground Cyan
let white = Foreground White
let default = Foreground Default

let on_black = Background Black
let on_red = Background Red
let on_green = Background Green
let on_yellow = Background Yellow
let on_blue = Background Blue
let on_magenta = Background Magenta
let on_cyan = Background Cyan
let on_white = Background White
let on_default = Background Default

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


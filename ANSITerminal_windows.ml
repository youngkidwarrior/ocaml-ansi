(* File: ANSITerminal_unix.ml

   Copyright 2010 by Vincent Hugot
   vincent.hugot@gmail.com
   www.vincent-hugot.com

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public License
   version 3 as published by the Free Software Foundation, with the
   special exception on linking described in file LICENSE.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
   LICENSE for more details.
*)

open Printf
include ANSITerminal_colors


type rgb = R|G|B

let rgb_of_color = function
  | Red -> [R]
  | Green -> [G]
  | Blue -> [B]
  | Default -> []
  | White -> [R;G;B]
  | Cyan -> [B;G]
  | Magenta -> [B;R]
  | Yellow -> [R;G]
  | Black -> []

(* calls to SetConsoleTextAttribute replace one another, so
   foreground, background and bold must be set in the same action *)
type color_state = {
  fore : rgb list;
  back : rgb list;
  bold : bool ; (* could intensify background too, but Unix does not
                   support that so scrapped. *)
}

let empty = { fore = [R;G;B]; back = [] ; bold = false }

let state_of_styles sty =
  List.fold_left (fun sta style ->
    match style with
    | Reset -> empty (* could stop there, but does not,
                       for exact compat with ansi *)
    | Bold -> {sta with bold = true }
    | Inverse ->
        (* simulated inverse... not exact compat *)
        let oba = sta.back and ofo = sta.fore in
        {sta with fore = oba; back = ofo }
    | Foreground c -> {sta with fore = rgb_of_color c }
    | Background c -> {sta with back = rgb_of_color c }
    | _  -> sta
  ) empty sty

let int_of_state st =
  (* Quoth wincon.h
     #define FOREGROUND_BLUE 1
     #define FOREGROUND_GREEN  2
     #define FOREGROUND_RED  4
     #define FOREGROUND_INTENSITY  8
     #define BACKGROUND_BLUE 16
     #define BACKGROUND_GREEN  32
     #define BACKGROUND_RED  64
     #define BACKGROUND_INTENSITY  128 *)
  let fo = function R -> 4  | G -> 2  | B -> 1
  and ba = function R -> 64 | G -> 32 | B -> 16
  and sum mode rgb = List.fold_left (lor) 0 (List.map mode rgb) in
  sum fo st.fore lor sum ba st.back lor (if st.bold then 8 else 0)
  (*
    let win_set_style code = printf "<%d>" code
    let win_unset_style () = printf "<unset>"
  *)

external hook_set_style : int -> int = "ANSITerminal_set_style"
external hook_unset_style : unit -> int = "ANSITerminal_unset_style"
external hook_init : unit -> int = "ANSITerminal_init"

exception Win32APIerror of string

let safe msg hook x =
  let return = hook x in
  (*printf "[%s->%d]%!" msg (return);*)
  (* if return <> 0 then printf "[%s->%d]" msg (pred return) *)
  if return <> 0 then raise(Win32APIerror(sprintf "%s(%d)" msg (pred return)))

let win_set_style = safe "set_style" hook_set_style
let win_unset_style = safe "unset_style" hook_unset_style
let win_init = safe "init" hook_init

let _ = win_init()

let set_style ch styles =
  let st = int_of_state (state_of_styles styles) in
  flush ch;
  win_set_style st; (* FIXME: stderr *)
  flush ch

let unset_style () = flush stdout; win_unset_style ()


let print ch styles txt =
  set_style ch styles;
  output_string ch txt;
  flush ch;
  if !autoreset then unset_style() (* FIXME: stderr *)

let print_string = print stdout
let prerr_string = print stderr

let printf style = kprintf (print_string style)



(* Local Variables: *)
(* compile-command: "ocamlc -annot -c ANSITerminal_windows.ml" *)
(* End: *)

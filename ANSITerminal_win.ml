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
include ANSITerminal_common


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

external hook_init : unit -> int = "ANSITerminal_init"
external hook_set_style : out_channel -> int -> int = "ANSITerminal_set_style"
external hook_unset_style : out_channel -> int
  = "ANSITerminal_unset_style"

exception Win32APIerror of string

let safe msg return =
  (*printf "[%s->%d]%!" msg (return);*)
  (* if return <> 0 then printf "[%s->%d]" msg (pred return) *)
  if return <> 0 then raise(Win32APIerror(sprintf "%s(%d)" msg (pred return)))

let win_init () = safe "init" (hook_init())
let win_set_style ch s = safe "set_style" (hook_set_style ch s)
let win_unset_style ch = safe "unset_style" (hook_unset_style ch)

let _ = win_init()

let set_style ch styles =
  let st = int_of_state (state_of_styles styles) in
  flush ch;
  win_set_style ch st;
  flush ch

let unset_style ch = flush ch; win_unset_style ch


let print ch styles txt =
  set_style ch styles;
  output_string ch txt;
  flush ch;
  if !autoreset then unset_style ch

let print_string = print stdout
let prerr_string = print stderr

let printf style = kprintf (print_string style)

external set_cursor_ : int -> int -> unit = "ANSITerminal_SetCursorPosition"
external pos_cursor : unit -> int * int = "ANSITerminal_pos"
external scroll : int -> unit = "ANSITerminal_Scroll"
external size : unit -> int * int = "ANSITerminal_size"
external resize_ : int -> int -> unit = "ANSITerminal_resize"

let set_cursor x y =
  let x0, y0 = pos_cursor() in
  let x = if x <= 0 then x0 else x
  and y = if y <= 0 then y0 else y in
  set_cursor_ x y (* FIXME: (x,y) outside the console?? *)

let move_cursor dx dy =
  let x0, y0 = pos_cursor() in
  let x = x0 + dx and y = y0 + dy in
  let x = if x <= 0 then 0 else x
  and y = if y <= 0 then 0 else y in
  set_cursor_ x y (* FIXME: (x,y) outside the console?? *)

let move_bol () =
  let _, y0 = pos_cursor() in
  set_cursor_ 0 y0

let saved_x = ref 0
let saved_y = ref 0

let save_cursor () =
  let x,y = pos_cursor() in
  saved_x := x;
  saved_y := y

let restore_cursor () =
  set_cursor_ !saved_x !saved_y


let resize x y =
  (* The specified width and height cannot be less than the width and
     height of the console screen buffer's window. *)
  let xmin, ymin = size() in
  let x = if x <= xmin then xmin else x
  and y = if y <= ymin then ymin else y in
  resize_ x y


(* FIXME: implement *)
let erase loc =
  match loc with
  | Eol -> ()
  | Above -> ()
  | Below -> ()
  | Screen -> ()


(* Local Variables: *)
(* compile-command: "make ANSITerminal_windows.cmo" *)
(* End: *)

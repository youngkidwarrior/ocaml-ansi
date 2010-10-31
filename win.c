/* ANSITerminal; windows API calls

   Allow colors, cursor movements, erasing,... under Unix and DOS shells.
   *********************************************************************

   Copyright 2010 by Vincent Hugot
   vincent.hugot@gmail.com
   www.vincent-hugot.com

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public License
   version 2.1 as published by the Free Software Foundation, with the
   special exception on linking described in file LICENSE.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
   LICENSE for more details.
*/

#include <stdio.h>
#include <caml/mlvalues.h>
#include <windows.h>

/* From io.h */
extern struct channel {
  int fd;                       /* Unix file descriptor */
  file_offset offset;           /* Absolute position of fd in the file */
  char * end;                   /* Physical end of the buffer */
  char * curr;                  /* Current position in the buffer */
  char * max;                   /* Logical end of the buffer (for input) */
  void * mutex;                 /* Placeholder for mutex (for systhreads) */
  struct channel * next, * prev;/* Double chaining of channels (flush_all) */
  int revealed;                 /* For Cash only */
  int old_revealed;             /* For Cash only */
  int refcount;                 /* For flush_all and for Cash */
  int flags;                    /* Bitfield */
  char buff[IO_BUFFER_SIZE];    /* The buffer itself */
};

#define Channel(v) (*((struct channel **) (Data_custom_val(v))))

extern long _get_osfhandle(int);

#define HANDLE_OF_CHAN(vchan) _get_osfhandle(Channel(vchan)->fd)

HANDLE hStdout;
CONSOLE_SCREEN_BUFFER_INFO csbiInfo;
WORD wOldColorAttrs;
int i;

// Get handles etc. Call once before doing anything else
// returns 0 iff no problem
CAMLexport
value ANSITerminal_init(value unit)
{
  hStdout = GetStdHandle(STD_OUTPUT_HANDLE);
  if (hStdout == INVALID_HANDLE_VALUE)
  {
    //MessageBox(NULL, TEXT("GetStdHandle"), TEXT("Console Error"), MB_OK);
    return Val_int(666);
  }

  // Save the current text colors.
  if (! GetConsoleScreenBufferInfo(hStdout, &csbiInfo))
  {
    /* MessageBox(NULL, TEXT("GetConsoleScreenBufferInfo"),  */
    /*            TEXT("Console Error"), MB_OK);  */
    return Val_int(777);
  }
  wOldColorAttrs = csbiInfo.wAttributes;
  // everything is OK
  return Val_int(0);
}


CAMLexport
value ANSITerminal_set_style(value vchan, value ccode)
{
  HANDLE h = HANDLE_OF_CHAN(vchan);
  int code = Int_val(vcode);

  if (! SetConsoleTextAttribute(h, code) )
  {
    /* MessageBox(NULL, TEXT("SetConsoleTextAttribute"), */
    /*            TEXT("Console Error"), MB_OK); */
    printf("{%d}", code);
    return Val_int(1 + code);
  }
  return Val_int(0);
}


// Restore the original text colors.
CAMLexport
value ANSITerminal_unset_style(value vchan)
{
  /* noalloc */
  HANDLE h = HANDLE_OF_CHAN(vchan);

  if (! SetConsoleTextAttribute(hStdout, wOldColorAttrs) )
    {
      /* MessageBox(NULL, TEXT("SetConsoleTextAttribute"), */
      /*            TEXT("Console Error"), MB_OK); */
      return Val_int(888);
    }
  return Val_int(0);
}


CAMLexport
value ANSITerminal_pos(value vunit)
{
  CAMLparam1(vunit);
  CAMLlocal1(vpos);
  CONSOLE_SCREEN_BUFFER_INFO ConsoleScreenBufferInfo;

  GetConsoleScreenBufferInfo(hStdout, &ConsoleScreenBufferInfo);

  vpos = caml_alloc_tuple(2);
  Store_field(vpos, 0, Val_int(ConsoleScreenBufferInfo.dwCursorPosition.X));
  Store_field(vpos, 1, Val_int(ConsoleScreenBufferInfo.dwCursorPosition.Y));
  CAMLreturn(vpos);
}

CAMLexport
value ANSITerminal_size(value vunit)
{
  CAMLparam1(vunit);
  CAMLlocal1(vsize);
  CONSOLE_SCREEN_BUFFER_INFO ConsoleScreenBufferInfo;

  /* Do not use the global var as the terminal can be resized */
  GetConsoleScreenBufferInfo(hStdout, &ConsoleScreenBufferInfo);

  vsize = caml_alloc_tuple(2);
  Store_field(vsize, 0, Val_int(ConsoleScreenBufferInfo.dwSize.X));
  Store_field(vsize, 1, Val_int(ConsoleScreenBufferInfo.dwSize.Y));

  CAMLreturn(vsize);
}

CAMLexport
value ANSITerminal_resize(value vx, value vy)
{
  /* noalloc */
  COORD dwSize;
  dwSize.X = Int_val(vx);
  dwSize.Y = Int_val(vy);
  SetConsoleScreenBufferSize(hStdout, dwSize);
  return Val_unit;
}


CAMLexport
value ANSITerminal_SetCursorPosition(value vx, value vy)
{
  COORD dwCursorPosition;
  dwCursorPosition.X = Int_val(vx);
  dwCursorPosition.Y = Int_val(vy);
  SetConsoleCursorPosition(hStdout, dwCursorPosition);
  return Val_unit;
}



CAMLexport
value ANSITerminal_Scroll(value vx)
{
  /* noalloc */
  INT x = Int_val(vx);
  SMALL_RECT srctScrollRect, srctClipRect;
  CHAR_INFO chiFill;
  COORD coordDest;

  srctScrollRect.Left = 0;
  srctScrollRect.Top = 1;
  srctScrollRect.Right = csbiInfo.dwSize.X - x;
  srctScrollRect.Bottom = csbiInfo.dwSize.Y - x;

  // The destination for the scroll rectangle is one row up.
  coordDest.X = 0;
  coordDest.Y = 0;

  // The clipping rectangle is the same as the scrolling rectangle.
  // The destination row is left unchanged.
  srctClipRect = srctScrollRect;

  // Set the fill character and attributes.
  chiFill.Attributes = FOREGROUND_RED|FOREGROUND_INTENSITY;
  chiFill.Char.AsciiChar = (char) ' ';

  ScrollConsoleScreenBuffer(
    hStdout,         // screen buffer handle
    &srctScrollRect, // scrolling rectangle
    &srctClipRect,   // clipping rectangle
    coordDest,       // top left destination cell
    &chiFill);       // fill character and color
  return Val_unit;
}

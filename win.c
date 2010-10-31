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
#include <caml/io.h>
#include <windows.h> 

extern long _get_osfhandle(int);

#define HANDLE_OF_CHAN(vchan) _get_osfhandle(Channel(vchan)->fd)

CONSOLE_SCREEN_BUFFER_INFO csbiInfo; 
WORD wOldColorAttrs; 
int i;

// Get handles etc. Call once before doing anything else
// returns 0 iff no problem
CAMLexport
value ANSITerminal_init(value unit)
{
  HANDLE hStdout;  
  
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

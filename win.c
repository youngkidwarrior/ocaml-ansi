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
#ifdef _WIN32
  #include <windows.h> 
  HANDLE hStdout; 
  CONSOLE_SCREEN_BUFFER_INFO csbiInfo; 
  WORD wOldColorAttrs; 
  int i;
#endif

#include <caml/mlvalues.h> 
// Get handles etc. Call once before doing anything else
// returns 0 iff no problem
CAMLprim int init(void)
{
  #ifdef _WIN32
  // Get handle to STDOUT.
  hStdout = GetStdHandle(STD_OUTPUT_HANDLE); 
  if (hStdout == INVALID_HANDLE_VALUE) 
  {
//       MessageBox(NULL, TEXT("GetStdHandle"), TEXT("Console Error"), MB_OK);
      return 666;
  }
  
  // Save the current text colors. 
  if (! GetConsoleScreenBufferInfo(hStdout, &csbiInfo)) 
  {
//       MessageBox(NULL, TEXT("GetConsoleScreenBufferInfo"), TEXT("Console Error"), MB_OK); 
      return 777;
  }
  wOldColorAttrs = csbiInfo.wAttributes; 
  #endif
  // everything is OK
  return 0;
}

// hook for Caml
value hook_init (void)
{ return Val_int( init () ); }

int set_style(int code)
{
  #ifdef _WIN32
  if (! SetConsoleTextAttribute(hStdout, code) )
  {
//       MessageBox(NULL, TEXT("SetConsoleTextAttribute"), TEXT("Console Error"), MB_OK);
      printf("{%d}", code);
      return 1 + code;
  }
  #endif
  return 0;
}

// hook for Caml
value hook_set_style (value code)
{ return Val_int( set_style ( Int_val(code) ) ); }


// Restore the original text colors. 
int unset_style(void)
{
  #ifdef _WIN32
  if (! SetConsoleTextAttribute(hStdout, wOldColorAttrs) )
  {
//     MessageBox(NULL, TEXT("SetConsoleTextAttribute"), TEXT("Console Error"), MB_OK);
    return 888;
  }
  #endif
  return 0;
}


// hook for Caml
value hook_unset_style (void)
{ return Val_int( unset_style () ); }

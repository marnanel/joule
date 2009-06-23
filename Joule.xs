/*
    Joule - track changes in an online list over time
    Copyright (C) 2002-2009 Thomas Thurman

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/*
	This file contains the code for XS routines-- that is,
	C routines called from Perl.

	There is currently only one such routine, Joule::raisin_compare().
	It takes two strings in Raisin format (see below) and a callback.
	It then does a fast comparison of the two strings, and calls the
	callback once for each difference found.

	RAISIN FORMAT:

	The Raisin format represents a set of tokens.  Each token is
	represented by a sequence of ASCII characters not including
	characters 0 or 10.  The tokens are delimited by instances of
	character 10.  The tokens must be sorted into ascending
	ASCII order.

	WHY IT'S CALLED RAISIN:

	It replaces an earlier system called "current" which kept track
	of a user's current followers.

*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

char*
raisin_report_delta (int direction, char *line, SV *c)
{
  int charcount = 0;
  char *cursor = line;
  char *buffer, *bufptr;

  while (*cursor && *cursor!='\n')
    cursor++;

  bufptr = buffer = malloc(cursor-line);
  cursor = line;
  while (*cursor=='\n') {
    cursor++;
  }
  while (*cursor && *cursor!='\n') {
    *(bufptr++) = *(cursor++);
  }
  *bufptr = 0;

  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSViv(direction)));
  XPUSHs(sv_2mortal(newSVpv(buffer, 0)));
  PUTBACK;

  perl_call_sv(c, G_VOID) ;

  FREETMPS;
  LEAVE;


  free(buffer);
  return cursor;
}

void
raisin_main_compare (char *left, char *right, SV *c)
{
  char *left_break = left;
  char *right_break = right;

  while (*left && *right) {

    while (*left=='\n') left++;
    while (*right=='\n') right++;

    if (*left==*right) {
      ++left;
      ++right;
    } else {
      if (*left<*right) {
	left = raisin_report_delta (0, left_break, c);
	right = right_break;
      } else {
	right = raisin_report_delta (1, right_break, c);
	left = left_break;
      }
    }

    if (*left=='\n') left_break = left;
    if (*right=='\n') right_break = right;
  }

  while (*left) {
    left = raisin_report_delta (0, left, c);
  }
  while (*right) {
    right = raisin_report_delta (1, right, c);
  }
}

MODULE = Joule             PACKAGE = Joule

PROTOTYPES: ENABLE

void
raisin_compare (l,r,c)
        char *  l
        char *  r
	SV * c
	CODE:
		raisin_main_compare(l, r, c);

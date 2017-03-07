/**********************************************************************
 MIT License

 Copyright (c) 2017 Consultingwerk - Software Architecture and Development

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 **********************************************************************/
/*------------------------------------------------------------------------
    File        : ttUserStats.i
    Purpose     : Temp-Table De

    Syntax      :

    Description :

    Author(s)   : Tom Bascom / White Star Software, Mike Fechner / Consultingwerk
    Created     : Fri Mar 03 23:26:39 CET 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

DEFINE TEMP-TABLE tt_usrTblInfo NO-UNDO
  FIELD tblDatabase AS CHARACTER FORMAT "x(20)":U
  FIELD tblName     AS CHARACTER FORMAT "x(20)":U
  FIELD tblRd       AS INT64
  FIELD tblCr       AS INT64
  FIELD tblUp       AS INT64
  FIELD tblDl       AS INT64
  INDEX tblName-idx IS UNIQUE tblDatabase tblName
.

DEFINE TEMP-TABLE tt_usrIdxInfo
  FIELD idxDatabase AS CHARACTER FORMAT "x(20)":U
  FIELD idxName     AS CHARACTER FORMAT "x(40)":U
  FIELD idxRd       AS INT64
  FIELD idxCr       AS INT64
  FIELD idxDl       AS INT64
  INDEX idxName-idx IS UNIQUE idxDatabase idxName
.

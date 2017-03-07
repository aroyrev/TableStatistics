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
    File        : usage-sample.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Mike Fechner / Consultingwerk  
    Created     : Tue Mar 07 14:02:41 CET 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

USING Consultingwerk.OERA.TableStatistics.* FROM PROPATH.

{Consultingwerk/OERA/TableStatistics/ttUserStats.i}

DEFINE VARIABLE oStats AS UserTableStats EXTENT NO-UNDO .


/* ***************************  Main Block  *************************** */

LOG-MANAGER:LOGFILE-NAME = "client.log" .
LOG-MANAGER:CLEAR-LOG () .

RUN InitializeUserTableStats .

FOR EACH Customer, FIRST Salesrep OF Customer:
    /* noop */
END.

LOG-MANAGER:WRITE-MESSAGE ("Table Stats FOR EACH Customer, FIRST Salesrep OF Customer:") .
RUN DumpUserTableStats . 


FOR EACH Salesrep:
    /* noop */
END.

LOG-MANAGER:WRITE-MESSAGE ("Table Stats FOR Salesrep:") .
RUN DumpUserTableStats . 


PROCEDURE DumpUserTableStats:

    DEFINE VARIABLE i AS INTEGER NO-UNDO.

    EMPTY TEMP-TABLE tt_usrTblInfo .
    EMPTY TEMP-TABLE tt_usrIdxInfo .

    /* Fetch database request details for this AppServer request */
    DO i = 1 TO EXTENT (oStats):
        oStats[i]:GetTableIndexStats (OUTPUT TABLE tt_usrTblInfo APPEND BY-REFERENCE, OUTPUT TABLE tt_usrIdxInfo APPEND BY-REFERENCE) .
    END.

    /* No Logfile, no output */
    IF LOG-MANAGER:LOGFILE-NAME = ? AND SESSION:REMOTE = FALSE AND SESSION:CLIENT-TYPE <> "WEBSPEED":U THEN
        RETURN .

    IF NOT CAN-FIND (FIRST tt_usrTblInfo WHERE tt_usrTblInfo.tblRd > 0 OR tt_usrTblInfo.tblCr > 0 OR tt_usrTblInfo.tblDl > 0 OR tt_usrTblInfo.tblUp > 0) OR
       NOT CAN-FIND (FIRST tt_usrIdxInfo WHERE tt_usrIdxInfo.idxCr > 0 OR tt_usrIdxInfo.idxDl > 0 OR tt_usrIdxInfo.idxRd > 0) THEN

        RETURN .

    LOG-MANAGER:WRITE-MESSAGE ("########################################################################################################":U) .
    LOG-MANAGER:WRITE-MESSAGE ("Table Name                                  Record Reads         Updates         Creates         Deletes":U) .
    LOG-MANAGER:WRITE-MESSAGE ("--------------------------------------------------------------------------------------------------------":U) .

    FOR EACH tt_usrTblInfo ON ERROR UNDO, THROW:

        LOG-MANAGER:WRITE-MESSAGE (SUBSTITUTE ("&1 &2 &3 &4 &5":U,
                                               STRING (tt_usrTblInfo.tblDatabase + ".":U + tt_usrTblInfo.tblName, "x(40)":U),
                                               STRING (tt_usrTblInfo.tblRd, ">>>,>>>,>>>,>>9":U),
                                               STRING (tt_usrTblInfo.tblUp, ">>>,>>>,>>>,>>9":U),
                                               STRING (tt_usrTblInfo.tblCr, ">>>,>>>,>>>,>>9":U),
                                               STRING (tt_usrTblInfo.tblDl, ">>>,>>>,>>>,>>9":U))) .
    END.

    LOG-MANAGER:WRITE-MESSAGE ("--------------------------------------------------------------------------------------------------------":U) .
    LOG-MANAGER:WRITE-MESSAGE ("Index Name                                   Index Reads                         Creates         Deletes":U) .
    LOG-MANAGER:WRITE-MESSAGE ("--------------------------------------------------------------------------------------------------------":U) .

    FOR EACH tt_usrIdxInfo ON ERROR UNDO, THROW:

        LOG-MANAGER:WRITE-MESSAGE (SUBSTITUTE ("&1 &2                 &3 &4":U,
                                               STRING (tt_usrIdxInfo.idxDatabase + ".":U + tt_usrIdxInfo.idxName, "x(40)":U),
                                               STRING (tt_usrIdxInfo.idxRd, ">>>,>>>,>>>,>>9":U),
                                               STRING (tt_usrIdxInfo.idxCr, ">>>,>>>,>>>,>>9":U),
                                               STRING (tt_usrIdxInfo.idxDl, ">>>,>>>,>>>,>>9":U))) .
    END.

    LOG-MANAGER:WRITE-MESSAGE ("########################################################################################################":U) .

    FINALLY:
        EMPTY TEMP-TABLE tt_usrTblInfo .
        EMPTY TEMP-TABLE tt_usrIdxInfo .
    END FINALLY.       

END PROCEDURE .     

PROCEDURE InitializeUserTableStats:

    DEFINE VARIABLE i        AS INTEGER   NO-UNDO .
    DEFINE VARIABLE cDictDB  AS CHARACTER NO-UNDO .
    DEFINE VARIABLE lLogging AS LOGICAL   NO-UNDO INITIAL FALSE .

    IF NUM-DBS = 0 THEN
        RETURN .

    ASSIGN cDictDB = LDBNAME ("dictdb":U) .

    EXTENT (oStats) = ? .
    EXTENT (oStats) = NUM-DBS .

    DO i = 1 TO NUM-DBS:
        CREATE ALIAS "dictdb":U FOR DATABASE VALUE (LDBNAME (i)).

        IF lLogging THEN
            oStats [i] = NEW UserTableStats ("UserTableStats":U) .
        ELSE
        oStats [i] = NEW UserTableStats () .
    END.

    FINALLY:
        IF cDictDB > "":U THEN
            CREATE ALIAS "dictdb":U FOR DATABASE VALUE (cDictDB) .
    END FINALLY.
    
END PROCEDURE .         
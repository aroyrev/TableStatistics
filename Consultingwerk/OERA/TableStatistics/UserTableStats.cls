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
    File        : UserTableStats
    Purpose     : Collects user table and index stats from instantiation
                  until each invokation of the GetTableIndexStats method
    Syntax      :
    Description :
    Author(s)   : Tom Bascom / White Star Software, Mike Fechner / Consultingwerk
    Created     : Fri Mar 03 23:27:43 CET 2017
    Notes       : The instance works against the DICTDB alias. When monitoring
                  multiple databases, please ensure to set the DICTDB alias
                  before instantiating this class to the database that this
                  instance of class should monitor
  ----------------------------------------------------------------------*/

ROUTINE-LEVEL ON ERROR UNDO, THROW.

USING Consultingwerk.OERA.TableStatistics.* FROM PROPATH .
USING Progress.Lang.*                       FROM PROPATH .

CLASS Consultingwerk.OERA.TableStatistics.UserTableStats:

/*    DEFINE VARIABLE iUserId       AS INT64   NO-UNDO .*/
    DEFINE VARIABLE iUserNum      AS INTEGER NO-UNDO .

    DEFINE VARIABLE cDatabaseName AS CHARACTER NO-UNDO .

    DEFINE VARIABLE iFirstTblId   AS INTEGER NO-UNDO .
    DEFINE VARIABLE iLastTblId    AS INTEGER NO-UNDO .

/*    DEFINE VARIABLE iTblBase      AS INTEGER NO-UNDO .*/
    DEFINE VARIABLE iTblRange     AS INTEGER NO-UNDO .
    DEFINE VARIABLE iTblUsed      AS INTEGER NO-UNDO .

    DEFINE VARIABLE iFirstIdxId   AS INTEGER NO-UNDO .
    DEFINE VARIABLE iLastIdxId    AS INTEGER NO-UNDO .

/*    DEFINE VARIABLE iIdxBase      AS INTEGER NO-UNDO .*/
    DEFINE VARIABLE iIdxRange     AS INTEGER NO-UNDO .
    DEFINE VARIABLE iIdxUsed      AS INTEGER NO-UNDO .

    {Consultingwerk/OERA/TableStatistics/ttUserStats.i}

    /* internal temp tables
     */

    DEFINE TEMP-TABLE tt_usrTblInfoX NO-UNDO
      FIELD xId     AS INTEGER
      FIELD tblNum  AS INTEGER
      FIELD tblName AS CHARACTER FORMAT "x(40)":U
      FIELD tblRd   AS INT64 EXTENT 2      /* [1] = previous value, [2] = incremental value    */
      FIELD tblCr   AS INT64 EXTENT 2
      FIELD tblUp   AS INT64 EXTENT 2
      FIELD tblDl   AS INT64 EXTENT 2
      INDEX xId     IS UNIQUE xId  .

    DEFINE TEMP-TABLE tt_usrIdxInfoX NO-UNDO
      FIELD xId     AS INTEGER
      FIELD idxNum  AS INTEGER
      FIELD idxName AS CHARACTER FORMAT "x(40)":U
      FIELD idxRd   AS INT64 EXTENT 2
      FIELD idxCr   AS INT64 EXTENT 2
      FIELD idxDl   AS INT64 EXTENT 2
      INDEX xId     IS UNIQUE xId .

    DEFINE VARIABLE cCustomLogEntryType AS CHARACTER NO-UNDO .

    /**
     * Purpose: Constructor for the UserTableStats class
     * Notes:   Initializes the user table and index stats
     *          for the dictdb connection of the current user
     */
    CONSTRUCTOR PUBLIC UserTableStats ():

        THIS-OBJECT ("":U) .

    END CONSTRUCTOR .

    /**
     * Purpose: Constructor for the UserTableStats class
     * Notes:   Initializes the user table and index stats
     *          for the dictdb connection of the current user
     * @param pcCustomLogEntryType The custom log entry type for logging and tracing
     */
    CONSTRUCTOR PUBLIC UserTableStats (pcCustomLogEntryType AS CHARACTER):

        ASSIGN cCustomLogEntryType = pcCustomLogEntryType .

        /* VSTs are keyed by "id", userNum is userId + 1 -- or, depending on your POV,
           userId is userNum - 1 in any event efficient VST access is always by the
           "id" field so make sure to use it! */
        FIND dictdb._myConnection NO-LOCK NO-ERROR .

        ASSIGN iUserNum      = dictdb._myConnection._myConn-UserId
/*               iUserid       = dictdb._myConnection._myConn-UserId + 1*/

               cDatabaseName = LDBNAME ("dictdb":U) .

        THIS-OBJECT:Initialize() .

    END CONSTRUCTOR.

    /**
     * Purpose: Returns the current user table and index stats
     *          (since the class was instantiated)
     * Notes:
     * @param tt_usrTblInfo OUTPUT TABLE with the table stats
     * @param tt_usrIdxInfo OUTPUT TABLE with the index stats
     */
    METHOD PUBLIC VOID GetTableIndexStats (OUTPUT TABLE tt_usrTblInfo,
                                           OUTPUT TABLE tt_usrIdxInfo):

        DEFINE VARIABLE t AS INTEGER NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.

        DEFINE VARIABLE dtStart AS DATETIME-TZ INITIAL NOW NO-UNDO .

        IF cCustomLogEntryType > "":U THEN
            LOG-MANAGER:WRITE-MESSAGE (SUBSTITUTE ("GetTableIndexStats DB: &1 Calculating Statistics since last run":U, cDatabaseName),
                                       cCustomLogEntryType) .

        t  = 0.

        tblLoop:
        FOR EACH dictdb._userTableStat NO-LOCK WHERE _UserTableStat-Id >= iFirstTblId
                                                 AND _UserTableStat-Id <= iLastTblId
            ON ERROR UNDO, THROW:

          t = t + 1.
          IF t > iTblUsed THEN
              LEAVE tblLoop .

          FIND tt_usrTblInfoX WHERE tt_usrTblInfoX.xId = _userTableStat-id NO-ERROR.

          IF AVAILABLE tt_usrTblInfoX THEN
            ASSIGN

              tt_usrTblInfoX.tblRd[2] = _userTableStat-read   - tt_usrTblInfoX.tblRd[1]
              tt_usrTblInfoX.tblRd[1] = _userTableStat-read

              tt_usrTblInfoX.tblCr[2] = _userTableStat-create - tt_usrTblInfoX.tblCr[1]
              tt_usrTblInfoX.tblCr[1] = _userTableStat-create

              tt_usrTblInfoX.tblUp[2] = _userTableStat-update - tt_usrTblInfoX.tblUp[1]
              tt_usrTblInfoX.tblUp[1] = _userTableStat-update

              tt_usrTblInfoX.tblDl[2] = _userTableStat-delete - tt_usrTblInfoX.tblDl[1]
              tt_usrTblInfoX.tblDl[1] = _userTableStat-delete
            .
           ELSE
            DO:
              FIND FIRST dictdb._file NO-LOCK WHERE _file-num = _userTableStat-num NO-ERROR.
              IF NOT AVAILABLE dictdb._file THEN
                    NEXT tblLoop .

              CREATE tt_usrTblInfoX.
              ASSIGN
                tt_usrTblInfoX.xId      = _userTableStat-id
                tt_usrTblInfoX.tblNum   = _file-num
                tt_usrTblInfoX.tblName  = _file-name
                tt_usrTblInfoX.tblRd[1] = _userTableStat-read
                tt_usrTblInfoX.tblCr[1] = _userTableStat-create
                tt_usrTblInfoX.tblUp[1] = _userTableStat-update
                tt_usrTblInfoX.tblDl[1] = _userTableStat-delete
              .
            END.

        END.

        IF cCustomLogEntryType > "":U THEN
            LOG-MANAGER:WRITE-MESSAGE (SUBSTITUTE ("GetTableIndexStats DB: &1 Runtime Table Statistics: &2":U,
                                                   cDatabaseName,
                                                   INTERVAL (NOW, dtStart, "milliseconds":U)),
                                       cCustomLogEntryType) .

        dtStart = NOW .

        i = 0.

        idxLoop:
        FOR EACH dictdb._userIndexStat NO-LOCK WHERE _UserIndexStat-id >= iFirstIdxId
                                                 AND _userIndexStat-id <= iLastIdxId
            ON ERROR UNDO, THROW:

          i = i + 1.
          IF i > iIdxUsed THEN
            LEAVE idxLoop.

          FIND tt_usrIdxInfoX WHERE tt_usrIdxInfoX.xId = _UserIndexStat-id NO-ERROR.
          IF AVAILABLE tt_usrIdxInfoX THEN
              ASSIGN
                  tt_usrIdxInfoX.idxRd[2]  = _userIndexStat-read   - tt_usrIdxInfoX.idxRd[1]
                  tt_usrIdxInfoX.idxRd[1]  = _userIndexStat-read

                  tt_usrIdxInfoX.idxCr[2]  = _userIndexStat-create - tt_usrIdxInfoX.idxCr[1]
                  tt_usrIdxInfoX.idxCr[1]  = _userIndexStat-create

                  tt_usrIdxInfoX.idxDl[2]  = _userIndexStat-delete - tt_usrIdxInfoX.idxDl[1]
                  tt_usrIdxInfoX.idxDl[1]  = _userIndexStat-delete .
           ELSE
            DO:
              FIND FIRST dictdb._index NO-LOCK WHERE _idx-num = _UserIndexStat-num NO-ERROR.

              IF AVAILABLE dictdb._index THEN
                  FIND FIRST dictdb._file NO-LOCK WHERE RECID (dictdb._file) = dictdb._index._file-recid NO-ERROR.

              IF NOT AVAILABLE dictdb._index OR NOT AVAILABLE dictdb._file THEN
                    NEXT idxLoop .

              CREATE tt_usrIdxInfoX.
              ASSIGN
                tt_usrIdxInfoX.xId      = _userIndexStat-id
                tt_usrIdxInfoX.idxNum   = _UserIndexStat-num
                tt_usrIdxInfoX.idxName  = SUBSTITUTE ("&1.&2":U, _file-name, _index-name )
                tt_usrIdxInfoX.idxRd[1] = _userIndexStat-read
                tt_usrIdxInfoX.idxCr[1] = _userIndexStat-create
                tt_usrIdxInfoX.idxDl[1] = _userIndexStat-delete
              .
            END.
        END.

        IF cCustomLogEntryType > "":U THEN
            LOG-MANAGER:WRITE-MESSAGE (SUBSTITUTE ("GetTableIndexStats DB: &1 Runtime Index Statistics: &2":U,
                                                   cDatabaseName,
                                                   INTERVAL (NOW, dtStart, "milliseconds":U)),
                                       cCustomLogEntryType) .

        dtStart = NOW .

        /* translate the internal representation into something more useful
           copy the incremental values to a user friendly TT */
        FOR EACH tt_usrTblInfoX WHERE tt_usrTblInfoX.tblRd[2] > 0 OR tt_usrTblInfoX.tblCr[2] > 0 OR tt_usrTblInfoX.tblDl[2] > 0 OR tt_usrTblInfoX.tblUp[2] > 0
            ON ERROR UNDO, THROW:

            FIND tt_usrTblInfo WHERE tt_usrTblInfo.tblDatabase = cDatabaseName
                                 AND tt_usrTblInfo.tblName = tt_usrTblInfoX.tblName NO-ERROR.

          IF NOT AVAILABLE tt_usrTblInfo THEN
              CREATE tt_usrTblInfo.

          ASSIGN
              tt_usrTblInfo.tblName     = tt_usrTblInfoX.tblName
              tt_usrTblInfo.tblDatabase = cDatabaseName
              tt_usrTblInfo.tblRd       = tt_usrTblInfoX.tblRd[2]
              tt_usrTblInfo.tblCr       = tt_usrTblInfoX.tblCr[2]
              tt_usrTblInfo.tblUp       = tt_usrTblInfoX.tblUp[2]
              tt_usrTblInfo.tblDl       = tt_usrTblInfoX.tblDl[2] .
        END.

        IF cCustomLogEntryType > "":U THEN
            LOG-MANAGER:WRITE-MESSAGE (SUBSTITUTE ("GetTableIndexStats DB: &1 Runtime Copy Table Statistics: &2":U,
                                                   cDatabaseName,
                                                   INTERVAL (NOW, dtStart, "milliseconds":U)),
                                       cCustomLogEntryType) .

        dtStart = NOW .

        FOR EACH tt_usrIdxInfoX WHERE tt_usrIdxInfoX.idxCr[2] > 0 OR tt_usrIdxInfoX.idxDl[2] > 0 OR tt_usrIdxInfoX.idxRd[2] > 0
            ON ERROR UNDO, THROW:

            FIND tt_usrIdxInfo WHERE tt_usrIdxInfo.idxDatabase = cDatabaseName
                                 AND tt_usrIdxInfo.idxName = tt_usrIdxInfoX.idxName NO-ERROR.

            IF NOT AVAILABLE tt_usrIdxInfo THEN
                CREATE tt_usrIdxInfo.

            ASSIGN
                tt_usrIdxInfo.idxName     = tt_usrIdxInfoX.idxName
                tt_usrIdxInfo.idxDatabase = cDatabaseName
                tt_usrIdxInfo.idxRd       = tt_usrIdxInfoX.idxRd[2]
                tt_usrIdxInfo.idxCr       = tt_usrIdxInfoX.idxCr[2]
                tt_usrIdxInfo.idxDl       = tt_usrIdxInfoX.idxDl[2] .
        END.

        IF cCustomLogEntryType > "":U THEN
            LOG-MANAGER:WRITE-MESSAGE (SUBSTITUTE ("GetTableIndexStats DB: &1 Runtime Copy Index Statistics: &2":U,
                                                   cDatabaseName,
                                                   INTERVAL (NOW, dtStart, "milliseconds":U)),
                                       cCustomLogEntryType) .

    END METHOD.

    /**
     * Purpose: Initializes the internal temp-tables with the current value
     * Notes:
     */
    METHOD PROTECTED VOID Initialize ():

        /* how many tables are there and what are the starting and ending offsets?
         *
         * -tablerangesize and -indexrangesize both default to 50, if you have more
         * than 50 tables or indexes the appropriate *rangesize parameter will need
         * to be increased
         *
         */

/*        FIND FIRST dictdb._tableStat NO-LOCK NO-ERROR .*/
/*        iTblBase = RECID (dictdb._tableStat).          */

        FIND LAST dictdb._tableStat NO-LOCK NO-ERROR .
        iTblRange = RECID (dictdb._tableStat).

        ASSIGN iTblUsed = 0.

        FOR EACH dictdb._tablestat NO-LOCK
            ON ERROR UNDO, THROW:

            FIND FIRST dictdb._file NO-LOCK WHERE _file-num = _tablestat-id NO-ERROR.
            IF AVAILABLE (dictdb._file) THEN
                iTblUsed = iTblUsed + 1.
        END.

        ASSIGN
          iFirstTblId = iUserNum * iTblRange
          iLastTblId  = iFirstTblId + MINIMUM (iTblRange, iTblUsed)
          iFirstTblId = iFirstTblId + 1
        .

        /* how many indexes are there?  what are the starting and ending offsets?
         */

/*        FIND FIRST dictdb._indexStat NO-LOCK NO-ERROR .*/
/*        iIdxBase = RECID (dictdb._indexStat).          */

        FIND LAST dictdb._indexStat NO-LOCK NO-ERROR .
        iIdxRange = RECID (dictdb._indexStat).

        iIdxUsed = 0.

        FOR EACH dictdb._indexStat NO-LOCK
            ON ERROR UNDO, THROW:

            FIND FIRST dictdb._index NO-LOCK WHERE _idx-num = _indexStat-id NO-ERROR.
            IF AVAILABLE( dictdb._index ) THEN
                iIdxUsed = iIdxUsed + 1.
        END.

        ASSIGN
            iFirstIdxId = iUserNum * iIdxRange
            iLastIdxId  = iFirstIdxId + MINIMUM (iIdxRange, iIdxUsed)
            iFirstIdxId = iFirstIdxId + 1 .

        /* initialize user stats */
        THIS-OBJECT:GetTableIndexStats (OUTPUT TABLE tt_usrTblInfo,
                                        OUTPUT TABLE tt_usrIdxInfo).

    END METHOD.

END CLASS.

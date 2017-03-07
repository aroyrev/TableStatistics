# Inspecting User Table and Index Statistics

## Introduction

The number of records accessed (read, update, create and delete) during a backend operation is one significant factor that a software developer can influence during development time. The number of records accessed very often provides more constant insight into the final system performance than looking at a stop watch. Developers can influence the number of records read for instance through database queries and the resulting index selection or by extensive aggregation of database records into Business Entity result sets, e.g. in calculated fields.

The total number of database records read during a Business Entity Fetch Data operation should stand in a reasonable relation to the resulting temp-table records made available to the consumer.
The SmartComponent Library supports developers with providing insight into the number of records and index nodes accessed during development and testing. Those utilities are based on the _userTableStat and _userIndexStat VST’s (virtual system tables).

See
http://knowledgebase.progress.com/articles/Article/19450
http://knowledgebase.progress.com/articles/Article/000048306

for details.

## UserTableStats

The class Consultingwerk.OERA.TableStatistics.UserTableStats provides a simple way of returning the number of accessed database records and index blocks. Once instantiated the class will return the record and index statstics of the current AVM session since its initialization or the last call into the GetTableIndexStats method. Results are returned in two temp-tables. The usage-sample.p showcases using the class for two queries against the sports2000 demo database. 

## Initialization

The code initializes and array of UserTableStats instances, with one instance per connected database:

```
USING Consultingwerk.OERA.TableStatistics.* FROM PROPATH.

{Consultingwerk/OERA/TableStatistics/ttUserStats.i}

DEFINE VARIABLE oStats AS UserTableStats EXTENT NO-UNDO .
```

```
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
```

After each query executed, we can output the table access and index access statistics by executing the DumpUserTableStats procedure:

```
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
```

### Sample output

```
Table Stats FOR EACH Customer, FIRST Salesrep OF Customer:
########################################################################################################
Table Name                                  Record Reads         Updates         Creates         Deletes
--------------------------------------------------------------------------------------------------------
sports2000.Customer                              201.132               0               0               0
sports2000.Salesrep                              201.118               0               0               0
--------------------------------------------------------------------------------------------------------
Index Name                                   Index Reads                         Creates         Deletes
--------------------------------------------------------------------------------------------------------
sports2000.Customer.CustNum                      201.139                               0               0
sports2000.Salesrep.SalesRep                     201.132                               0               0
########################################################################################################

Table Stats FOR Salesrep:
########################################################################################################
Table Name                                  Record Reads         Updates         Creates         Deletes
--------------------------------------------------------------------------------------------------------
sports2000.Salesrep                                    9               0               0               0
--------------------------------------------------------------------------------------------------------
Index Name                                   Index Reads                         Creates         Deletes
--------------------------------------------------------------------------------------------------------
sports2000.Salesrep.SalesRep                          13                               0               0
########################################################################################################
```

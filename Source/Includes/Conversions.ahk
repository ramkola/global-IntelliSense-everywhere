; Indentation_style: https://de.wikipedia.org/wiki/Einrückungsstil#SL5small-Stil
; these functions handle database conversion
; always set the SetDbVersion default argument to the current highest version

SetDbVersion(dBVersion = 7){
	global g_WordListDB
	g_WordListDB.Query("INSERT OR REPLACE INTO LastState VALUES ('databaseVersion', '" . dBVersion . "', NULL);")
}

;<<<<<<<< MaybeConvertDatabase <<<< 180223091829 <<<< 23.02.2018 09:18:29 <<<<
; returns true if we need to rebuild the whole database
MaybeConvertDatabase(){
	ToolTip5sec("MaybeConvertDatabase() return false " A_LineNumber . " " . A_LineFile )
	return false

	global g_WordListDB
	databaseVersionRows := g_WordListDB.Query("SELECT lastStateNumber FROM LastState WHERE lastStateItem = 'databaseVersion';")
	if (databaseVersionRows){
		for each, row in databaseVersionRows.Rows
		{
			databaseVersion := row[1]
		}
	}
	
	if (!databaseVersion){
		   tableConverted := g_WordListDB.Query("SELECT tableconverted FROM LastState;")
	} else {
		tableConverted := g_WordListDB.Query("SELECT lastStateNumber FROM LastState WHERE lastStateItem = 'tableConverted';")
	}
   
	if (tableConverted){
		for each, row in tableConverted.Rows
		{
			WordlistConverted := row[1]
		}
	}
	
	IfNotEqual, WordlistConverted, 1
	{
		Msgbox,RebuildDatabase()`n RebuildDatabase= %RebuildDatabase%`n `n `n (%A_LineFile%~%A_LineNumber%)
		RebuildDatabase()
		return, true
	}
	
	if (!databaseVersion)
	{
		RunConversionOne(WordlistConverted)
	}
	
	if (databaseVersion < 2)
	{
		RunConversionTwo()
	}
	
	if (databaseVersion < 3)
	{
		RunConversionThree()
	}
	
	if (databaseVersion < 4)
	{
		RunConversionFour()
	}
	
	if (databaseVersion < 5)
	{
		RunConversionFive()
	}
	
	if (databaseVersion < 6)
	{
		RunConversionSix()
	}
	
	if (databaseVersion < 7)
	{
		RunConversionSeven()
	}
	
	return, false
}


; Rebuilds the Database from scratch as we have to redo the wordlist anyway.
RebuildDatabase(){
	if(0){
		tip := "FALSE NOOO RebuildDatabase `n " A_LineNumber . " " . A_LineFile
		ToolTip5sec(tip)
		MsgBox,4 ,% tip,% tip, 5
		return false
	}
;
	global g_WordListDB
	g_WordListDB.BeginTransaction()
	g_WordListDB.Query("DROP TABLE Words;")
	g_WordListDB.Query("DROP INDEX WordIndex;")
	g_WordListDB.Query("DROP TABLE LastState;")
	g_WordListDB.Query("DROP TABLE Wordlists;")
	
	CreateWordsTable()
	CreateWordIndex()

	CreateLastStateTable()
	CREATE_TABLE_Wordlists()
	
	SetDbVersion()
	g_WordListDB.EndTransaction()
}

;Runs the first conversion
RunConversionOne(WordlistConverted)
{
	global g_WordListDB
	g_WordListDB.BeginTransaction()
	
	g_WordListDB.Query("ALTER TABLE LastState RENAME TO OldLastState;")
	
	CreateLastStateTable()
	
	g_WordListDB.Query("DROP TABLE OldLastState;")
	g_WordListDB.Query("INSERT OR REPLACE INTO LastState VALUES ('tableConverted', '" . WordlistConverted . "', NULL);")
	
	;superseded by conversion 3
	;g_WordListDB.Query("ALTER TABLE Words ADD COLUMN worddescription TEXT;")
	
	SetDbVersion(1)
	g_WordListDB.EndTransaction()
	
}

RunConversionTwo()
{
	global g_WordListDB
	
	;superseded by conversion 3
	;g_WordListDB.Query("ALTER TABLE Words ADD COLUMN wordreplacement TEXT;")
	
	;SetDbVersion(2)
}

RunConversionThree()
{
	global g_WordListDB
	g_WordListDB.BeginTransaction()
	
	CreateWordsTable("Words2")
	
	g_WordListDB.Query("UPDATE Words SET wordreplacement = '' WHERE wordreplacement IS NULL;")
	
	g_WordListDB.Query("INSERT INTO Words2 SELECT * FROM Words;")
	
	g_WordListDB.Query("DROP TABLE Words;")
	
	g_WordListDB.Query("ALTER TABLE Words2 RENAME TO Words;")
	
	CreateWordIndex()
	
	SetDbVersion(3)
	g_WordListDB.EndTransaction()
}

; normalize accented characters
RunConversionFour()
{
	global g_WordListDB
	;superseded by conversion 6
	/*g_WordListDB.BeginTransaction()
	
	Words := g_WordListDB.Query("SELECT word, wordindexed, wordreplacement FROM Words;")
   
	for each, row in Words.Rows
	{
		Word := row[1]
		WordIndexed := row[2]
		WordReplacement := row[3]		
		
		WordIndexedTransformed := StrUnmark(WordIndexed)
		
		StringReplace, WordIndexedTransformedEscaped, WordIndexedTransformed, ', '', All		
		StringReplace, WordEscaped, Word, ', '', All
		StringReplace, WordIndexEscaped, WordIndexed, ', '', All
		StringReplace, WordReplacementEscaped, WordReplacement, ', '', All
		
		g_WordListDB.Query("UPDATE Words SET wordindexed = '" . WordIndexedTransformedEscaped . "' WHERE word = '" . WordEscaped . "' AND wordindexed = '" . WordIndexEscaped . "' AND wordreplacement = '" . WordReplacementEscaped . "';")
	}
	; Yes, wordindexed is the transformed word that is actually searched upon.

	SetDbVersion(4)
	g_WordListDB.EndTransaction()
	*/
}

;Creates the Wordlists table
RunConversionFive()
{
	global g_WordListDB
	g_WordListDB.BeginTransaction()
	
	CREATE_TABLE_Wordlists()
	
	SetDbVersion(5)
	g_WordListDB.EndTransaction()
}

; normalize accented characters
RunConversionSix()
{
	; superseded by conversion 7
}

; normalize accented characters
RunConversionSeven()
{
	global g_WordListDB
	g_WordListDB.BeginTransaction()
	
	Words := g_WordListDB.Query("SELECT word, wordindexed, wordreplacement FROM Words;")
	WordDescription = 
   
	for each, row in Words.Rows
	{
		Word := row[1]
		WordIndexed := row[2]
		WordReplacement := row[3]
		
		TransformWord(Word, WordReplacement, WordDescription, WordTransformed, WordIndexedTransformed, WordReplacementTransformed, WordDescriptionTransformed)
		
		StringReplace, OldWordIndexedTransformed, WordIndexed, ', '', All
		
		g_WordListDB.Query("UPDATE Words SET wordindexed = '" . WordIndexedTransformed . "' WHERE word = '" . WordTransformed . "' AND wordindexed = '" . OldWordIndexedTransformed . "' AND wordreplacement = '" . WordReplacementTransformed . "';")
	}
	
	SetDbVersion(7)
	g_WordListDB.EndTransaction()
}

CreateLastStateTable()
{
	global g_WordListDB

	IF not g_WordListDB.Query("CREATE TABLE LastState (lastStateItem TEXT PRIMARY KEY, lastStateNumber INTEGER, otherInfo TEXT) WITHOUT ROWID;")
	{
		ErrMsg := g_WordListDB.ErrMsg()
		ErrCode := g_WordListDB.ErrCode()
		MsgBox Cannot Create LastState Table - fatal error: %ErrCode% - %ErrMsg%
		ExitApp
	}
}

CreateWordsTable(WordsTableName:="Words"){
lll(A_LineNumber, A_LineFile, "lin1 at CREATE_TABLE_wordS")
	global g_WordListDB
	if(!g_WordListDB)
    	g_WordListDB := DBA.DataBaseFactory.OpenDataBase("SQLite", A_ScriptDir . "\WordlistLearned.db" ) ;
;
sql =
(
CREATE TABLE IF NOT EXISTS %WordsTableName%  (
wordListID INTEGER NOT NULL
, wordindexed TEXT NOT NULL
, word TEXT NOT NULL
, count INTEGER
, worddescription TEXT
, wordreplacement TEXT NOT NULL
, PRIMARY KEY `(wordListID, word, wordreplacement) );
)
; wordListID,
;clipboard := sql
tooltip, % sql
	IF not g_WordListDB.Query(sql)
	{
		ErrMsg := g_WordListDB.ErrMsg() . "`n" . sql . "`n"
		ErrCode := g_WordListDB.ErrCode()
		clipboard := sql
		msgbox Cannot Create %WordsTableName% Table - fatal error: %ErrCode% - %ErrMsg%
		ExitApp
	}
}

CreateWordIndex(){
	global g_WordListDB

	IF not g_WordListDB.Query("CREATE INDEX WordIndex ON Words (wordListID, wordindexed);")
	{
		ErrMsg := g_WordListDB.ErrMsg()
		ErrCode := g_WordListDB.ErrCode()
		msgbox Cannot Create WordIndex Index - fatal error: %ErrCode% - %ErrMsg%
		ExitApp
	}
}
;

;<<<<<<<< CREATE_TABLE_Wordlists <<<< 180218062159 <<<< 18.02.2018 06:21:59 <<<<
CREATE_TABLE_Wordlists(){
    lll(A_LineNumber, A_LineFile, "lin1 at CREATE_TABLE_Wordlists")
	global g_WordListDB
	if(!g_WordListDB)
    	g_WordListDB := DBA.DataBaseFactory.OpenDataBase("SQLite", A_ScriptDir . "\WordlistLearned.db" ) ;

	sql := "CREATE TABLE IF NOT EXISTS Wordlists (id INTEGER PRIMARY KEY AUTOINCREMENT, wordlist TEXT, wordlistmodified DATETIME, wordlistsize INTEGER)"
	IF not g_WordListDB.Query(sql)
	{
		ErrMsg := g_WordListDB.ErrMsg()
		ErrCode := g_WordListDB.ErrCode()
		clipboard := sql
		msgbox, Cannot Create Wordlists Table - fatal error: %ErrCode% - %ErrMsg%  `n sql= %sql% `n  (%A_LineFile%~%A_LineNumber%)
		ExitApp
	}
}
;>>>>>>>> CREATE_TABLE_Wordlists >>>> 180218062205 >>>> 18.02.2018 06:22:05 >>>>

CreateWordlistsTable()
{
	Msgbox,deprecated ==> return `n (%A_LineFile%~%A_LineNumber%)
	return

	global g_WordListDB
	
	IF not g_WordListDB.Query("CREATE TABLE Wordlists (wordlist TEXT PRIMARY KEY, wordlistmodified DATETIME, wordlistsize INTEGER) WITHOUT ROWID;")
	{
		ErrMsg := g_WordListDB.ErrMsg()
		ErrCode := g_WordListDB.ErrCode()
		msgbox Cannot Create Wordlists Table - fatal error: %ErrCode% - %ErrMsg%
		ExitApp
	}
}
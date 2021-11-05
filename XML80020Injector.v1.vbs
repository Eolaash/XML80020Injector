'Проект "XML80020Injector" v001 от 03.11.2021
'
'ОПИСАНИЕ:
'

'instructions
Option Explicit

'global constants
Const cCurrentVersion = 1
Const cVersionDate = "05-11-2021"
Const cCurrentScript = "XML80020Injector"

'command_name constants (vbs does not support enum)
Const cmdSeparator = "#"
Const cmdInternalSeparator = ":"
Const cmd_ADDFILL = "ADDFILL"

'global variables
Dim gScriptFileName, gFSO, gWSO, gRExp, gScriptPath, gLog
'Dim gLogFilePath, gLogString, gLogFileName, gLogInversiveWritting

' CLogger - logger class
Class CLogger
	Private pLogFileName
	Private pLogFilePath
	Private pLogString
	Private pInverseWriting
	Private pAppendLog
	Private pFSO
	Private pWorkFolder
	Private pHeaderEchoText
	Private pSilent
	'read-only
	Private pIsLoggerActive
	Private pLoggerStatus

	Public Property Get StatusText()
    	Set StatusText = pLoggerStatus
   	End Property

	Public Property Get Active()
    	Set Active = pIsLoggerActive
   	End Property

	Public Sub Init(inFolder, inFileName, inInverseWriting, inAppendLog, inEchoHeaderText, inSilent)
		pIsLoggerActive = False

		If Not pFSO.FolderExists(inFolder) Then
			pLoggerStatus = "Init failed. Folder not exists: " & inFolder
			Exit Sub
		End If

		pLogFilePath = inFolder
		If Right(pLogFilePath, 1) <> "\" Then: pLogFilePath = pLogFilePath & "\"

		If inFileName = vbNullString Then
			pLoggerStatus = "Init failed. File name cannot be empty!"
			Exit Sub
		End If

		pLogFilePath = pLogFilePath & inFileName

		If TypeName(inInverseWriting) <> "Boolean" Then
			pInverseWriting = False
		Else
			pInverseWriting = inInverseWriting
		End If

		If TypeName(inAppendLog) <> "Boolean" Then
			pAppendLog = False
		Else
			pAppendLog = inAppendLog
		End If

		If TypeName(inSilent) <> "Boolean" Then
			pSilent = False
		Else
			pSilent = inSilent
		End If

		pHeaderEchoText = inEchoHeaderText
		pLogString = vbNullString
		pIsLoggerActive = True

		LogLine "LOG", False, "Session start"
	End Sub

	Private Function NZeroAdd(inValue, inDigiCount)
		Dim tHighStack, tIndex
		NZeroAdd = inValue	
		tHighStack = inDigiCount - Len(inValue)
		If tHighStack > 0 Then
			For tIndex = 1 To tHighStack
				NZeroAdd = "0" & NZeroAdd
			Next
		End If
	End Function

	Private Function GetTimeStamp()
		GetTimeStamp = Now() 'to fixate time
		GetTimeStamp = NZeroAdd(Month(GetTimeStamp), 2) & "." & NZeroAdd(Day(GetTimeStamp), 2) & " " & NZeroAdd(Hour(GetTimeStamp), 2) & ":" & NZeroAdd(Minute(GetTimeStamp), 2) & ":" & NZeroAdd(Second(GetTimeStamp), 2)
	End Function

	Public Sub LogLine(inBlockLabel, inUseEcho, inText)
		Dim tTimeStamp

		If Not pIsLoggerActive Then: Exit Sub

		tTimeStamp = GetTimeStamp()

		If pLogString <> vbNullString Then
			If pInverseWriting Then
				pLogString = tTimeStamp & " > " & vbTab & "[" & inBlockLabel & "] " & inText & vbCrLf & pLogString
			Else
				pLogString = pLogString & vbCrLf & tTimeStamp & " > " & vbTab & "[" & inBlockLabel & "] " & inText
			End If
		Else
			pLogString = tTimeStamp & " > " & vbTab & "[" & inBlockLabel & "] " & inText
		End If

		
		If inUseEcho Then: Echo inBlockLabel & " >> " & vbCrLf & inText, 64, pHeaderEchoText
	End Sub

	Private Sub Class_Initialize()
		pIsLoggerActive = False
		pLoggerStatus = "Just created. Init me!"
		Set pFSO = CreateObject("Scripting.FileSystemObject")		
	End Sub

	Private Function GetOldLogString()
		Dim tTextFile

		GetOldLogString = vbNullString
		
		If pAppendLog Then
			If pFSO.FileExists(pLogFilePath) Then
				On Error Resume Next
					Set tTextFile = pFSO.OpenTextFile(pLogFilePath, 1)
					tOldLogString = tTextFile.ReadAll
					tTextFile.Close
					Set tTextFile = Nothing
					If Err.Number <> 0 Then: tOldLogString = vbNullString
				On Error GoTo 0
			End If
		End If
	End Function

	Private Sub Echo(inText, inStyle, inHeader)
		Dim tHeader, tStyle
		If Not pSilent Then
			tStyle = 64			
			tHeader = pHeaderEchoText

			If inStyle > -1 Then: tStyle = inStyle
			If inHeader <> vbNullString Then: tHeader = inHeader

			MsgBox inText, tStyle, tHeader
		End If
	End Sub

	Public Sub LogSave()
		Dim tTextFile, tOldLogString
		
		If Not pIsLoggerActive Then: Exit Sub

		pLoggerStatus = "Saving log"
		tOldLogString = GetOldLogString()

		'error control
		On Error Resume Next
			Set tTextFile = pFSO.OpenTextFile(pLogFilePath, 2, True)			

			If Err.Number <> 0 Then 
				Echo "Can't create LOG file with path: " & vbCrLf & pLogFilePath & vbCrLf & vbCrLf & "Reason: " & Err.Description, -1, vbNullString
				Set tTextFile = Nothing
				On Error GoTo 0
				Exit Sub
			End If

		On Error GoTo 0

		'writing block
		If tOldLogString <> vbNullString Then
			tTextFile.WriteLine pLogString
			tTextFile.Write tOldLogString
		Else
			tTextFile.Write pLogString
		End If

		'close file
		tTextFile.Close
		Set tTextFile = Nothing
	End Sub

	Private Sub Class_Terminate()
		LogLine "LOG", False, "Session end"
		LogSave()
		pIsLoggerActive = False
		Set pFSO = Nothing
	End Sub
End Class

Private Function fGetProjectName()
	fGetProjectName = cCurrentScript & " " & " v" & cCurrentVersion & " (" & cVersionDate & ")"
End Function

Private Function fGetLogTag(inLogTag)
	fGetLogTag = cCurrentScript & "." & inLogTag
End Function

'fInit - main script init sub
Private Sub fInit()
	'objects
	Set gFSO = CreateObject("Scripting.FileSystemObject")
	Set gWSO = CreateObject("WScript.Shell")
	Set gRExp = WScript.CreateObject("VBScript.RegExp")
	Set gLog = New CLogger
	
	'main path routines
	gScriptFileName = Wscript.ScriptName
	gScriptPath = gFSO.GetParentFolderName(WScript.ScriptFullName)

	'logger activation
	gLog.Init gScriptPath, "Log.txt", False, False, fGetProjectName, False
End Sub

'fQuit - main quiting script sub (with object releasing)
Private Sub fQuit()
	'fLogClose False
	Set gLog = Nothing	
	Set gFSO = Nothing
	Set gWSO = Nothing
	Set gRExp = Nothing
	
	WScript.Quit
End Sub

'fMain - main work function
Private Sub fMain()
	Dim tFilePath, tFile, tLogTag, tIndex, tCommand

	tLogTag = fGetLogTag("fMain")
	'gLog.LogLine tLogTag, False, "Argument count - " & WScript.Arguments.Length
	gLog.LogLine tLogTag, False, "Argument count - " & WScript.Arguments.Length
	tCommand = "ADDFILL:80020:5600010901:564130032113101:01:03:1:AUTO:-2133"
	gLog.LogLine tLogTag, False, "Command: " & tCommand

	If WScript.Arguments.Length = 0 Then: fQuit

	tIndex = 0
	For Each tFilePath in WScript.Arguments
		
		tIndex = tIndex + 1
		gLog.LogLine tLogTag, False, "-------------------" 'just log separator
		gLog.LogLine tLogTag, False, "Argument #" & tIndex & ": " & WScript.Arguments.Length

		'processing argument value
		If gFSO.FileExists(tFilePath) Then
			Set tFile = gFSO.GetFile(tFilePath)
			fXML80020Injection tFile, tCommand
		Else
			gLog.LogLine tLogTag, False, "File not exists!"
		End If
	Next
End Sub

'fCheckTimeStamp - quick check timestamp
Private Function fCheckTimeStamp(inValue)
	Dim tValue, tYear, tMonth, tDay
    'PREP
    fCheckTimeStamp = False
    'GET
    If Len(inValue) <> 14 or Not IsNumeric(inValue) Then: Exit Function	
    'sec
    tValue = Fix(Right(inValue, 2))    
    If tValue < 0 Or tValue > 59 Then: Exit Function
    'min
    tValue = Fix(Mid(inValue, 11, 2))    
    If tValue < 0 Or tValue > 59 Then: Exit Function
    'hour
    tValue = Fix(Mid(inValue, 9, 2))    
    If tValue < 0 Or tValue > 24 Then: Exit Function
    'day
    tValue = Fix(Mid(inValue, 7, 2))    
    If tValue < 1 Or tValue > 31 Then: Exit Function
    tDay = tValue
    'month
    tValue = Fix(Mid(inValue, 5, 2))    
    If tValue < 1 Or tValue > 12 Then: Exit Function
    tMonth = tValue
    'year
    tValue = Fix(Left(inValue, 4))
    If tValue < 2010 Or tValue > 2025 Then: Exit Function
    tYear = tValue
    'logic check
    If fDaysPerMonth(tMonth, tYear) < tDay Then: Exit Function
    'over
    fCheckTimeStamp = True
End Function

'fReadTimeStamp - read timestamp
Private Function fReadTimeStamp(inValue, outDate)
	Dim tValue, tYear, tMonth, tDay, tHour, tMinute, tSecond, tLongStamp, tShortStamp, tDate
    'PREP
    fReadTimeStamp = False
	outDate = 0
	tShortStamp = (Len(inValue) = 8)
	tLongStamp = (Len(inValue) = 14)
    'GET
    If Not((tLongStamp Or tShortStamp) And IsNumeric(inValue)) Then: Exit Function	
	
    'day
    tValue = Fix(Mid(inValue, 7, 2))    
    If tValue < 1 Or tValue > 31 Then: Exit Function
    tDay = tValue
    'month
    tValue = Fix(Mid(inValue, 5, 2))    
    If tValue < 1 Or tValue > 12 Then: Exit Function
    tMonth = tValue
    'year
    tValue = Fix(Left(inValue, 4))
    If tValue < 2000 Or tValue > 2100 Then: Exit Function
    tYear = tValue
    'logic check
    If fDaysPerMonth(tMonth, tYear) < tDay Then: Exit Function

	tDate = DateSerial(tYear, tMonth, tDay)

	If tLongStamp Then
		'sec
		tValue = Fix(Right(inValue, 2))    
		If tValue < 0 Or tValue > 59 Then: Exit Function
		tSecond = tValue
		'min
		tValue = Fix(Mid(inValue, 11, 2))    
		If tValue < 0 Or tValue > 59 Then: Exit Function
		tMinute = tValue
		'hour
		tValue = Fix(Mid(inValue, 9, 2))    
		If tValue < 0 Or tValue > 24 Then: Exit Function
		tHour = tValue

		tDate = tDate + TimeSerial(tHour, tMinute, tSecond)
	End If

	If Not IsDate(tDate) Then: Exit Function

    'over
	outDate = tDate
    fReadTimeStamp = True
End Function

'fGetTimeStamp - generate timestamp by current time
Private Function fGetTimeStamp()
	Dim tNow, tResult, tTemp
	
	tNow = Now() '20171017000000
	'year
	tResult = Year(tNow)
	'month
	tTemp = Month(tNow)
	If tTemp < 10 Then: tTemp = "0" & tTemp
	tResult = tResult & tTemp
	'day
	tTemp = Day(tNow)
	If tTemp < 10 Then: tTemp = "0" & tTemp
	tResult = tResult & tTemp
	'hour
	tTemp = Hour(tNow)
	If tTemp < 10 Then: tTemp = "0" & tTemp
	tResult = tResult & tTemp
	'min
	tTemp = Minute(tNow)
	If tTemp < 10 Then: tTemp = "0" & tTemp
	tResult = tResult & tTemp
	'sec
	tTemp = Second(tNow)
	If tTemp < 10 Then: tTemp = "0" & tTemp
	tResult = tResult & tTemp
	'fin
	fGetTimeStamp = tResult
End Function

'fDaysPerMonth - return DAYS count in targeted date by inMonth and inYear; default - 0
Private Function fDaysPerMonth(inMonth, inYear)
    fDaysPerMonth = 0
    Select Case LCase(inMonth)
        Case "январь", "1",1:		fDaysPerMonth = 31
        Case "февраль", "2", 2:
            If (inYear Mod 4) = 0 Then
				fDaysPerMonth = 29
            Else
            	fDaysPerMonth = 28
            End If
        Case "март", "3", 3:		fDaysPerMonth = 31
        Case "апрель", "4", 4:		fDaysPerMonth = 30
        Case "май", "5", 5:			fDaysPerMonth = 31
        Case "июнь", "6", 6:		fDaysPerMonth = 30
        Case "июль", "7", 7:		fDaysPerMonth = 31
        Case "август", "8", 8:		fDaysPerMonth = 31
        Case "сентябрь", "9", 9:	fDaysPerMonth = 30
        Case "октябрь", "10", 10:	fDaysPerMonth = 31
        Case "ноябрь", "11", 11:	fDaysPerMonth = 30
        Case "декабрь", "12", 12:	fDaysPerMonth = 31
    End Select
    If inYear <= 0 Then: fDaysPerMonth = 0
End Function

'func 1
Private Function fGetFileExtension(inFileName)
	Dim tPos
	fGetFileExtension = vbNullString
	tPos = InStrRev(inFileName, ".")
	If tPos > 0 Then
		fGetFileExtension = UCase(Right(inFileName, Len(inFileName) - tPos))
	End If
End Function

'func 2
Private Function fGetFileName(inFileName)
	Dim tPos
	fGetFileName = vbNullString
	tPos = InStrRev(inFileName, ".")
	If tPos > 1 Then
		fGetFileName = Left(inFileName, tPos - 1)
	End If
End Function

'fNZeroAdd - INT to STRING formating to 0000 type ()
Private Function fNZeroAdd(inValue, inDigiCount)
	Dim tHighStack, tIndex
	fNZeroAdd = inValue	
	tHighStack = inDigiCount - Len(inValue)
	If tHighStack > 0 Then
		For tIndex = 1 To tHighStack
			fNZeroAdd = "0" & fNZeroAdd
		Next
	End If
End Function

'fSaveXMLChanges - save XML object as file (with rebuilding)
Private Sub fSaveXMLChanges(inFilePath, inXMLObject, inRebuild)
	Dim tTextFile, tXMLText, tXMLBufText
	
	'save it
	inXMLObject.Save (inFilePath)
	
	If Not inRebuild Then: Exit Sub

	'rebuild if needed
	'read as text
	Set tTextFile = gFSO.OpenTextFile(inFilePath, 1)		
	tXMLText = tTextFile.ReadAll	
	tTextFile.Close
	
	'replacing and save as text
	Set tTextFile = gFSO.OpenTextFile(inFilePath, 2, True)	
	tXMLText = Replace(tXMLText,"><","> <")
	tTextFile.Write tXMLText
	tTextFile.Close
	
	'rebuild through load and save
	inXMLObject.Load(inFilePath)
	inXMLObject.Save(inFilePath)
End Sub

'tSelectedVersion = InputBox("ВНИМАНИЕ! Было найдено несколько версий для данного кода AREA " & tAreaText & "! " & vbCrLf & "Выберите версию перетока " & tResultString, "Задайте номер версии из списка", tSelectedVersion)


' fCheckXML80020 - Check if is IN file is XML 80020 and return boolean (also return xml80020 version + xml object with preloaded xml80020)
' External GLOBAL: gRExp
Private Function fCheckXML80020(inFile, outClass, outVersion, outDate, outXML80020)
	Dim tLogTag, tMaskTestResult, tTempXML, tNode
	Dim tTraderINN, tAISSCode, tNameElements, tClassCode, tDate, tNumber, tDateProcessed
	Dim tClass, tVersion
	Dim tValue, tErrorText, tAttributeName
	
	'predefines
	tLogTag = "fCheckXML80020"
	fCheckXML80020 = False
	outVersion = 0
	outClass = vbNullString
	outDate = 0
	Set outXML80020 = Nothing
	gLog.LogLine tLogTag, False, "File: " & inFile.Name

	' 01 // NAME CHECK
	'regexp for quick namecheck // EXAMPLE: 80020_1834024515_20211031_1_5600010900.xml
	'no name content checks
	gRExp.IgnoreCase = True
	gRExp.Global = True
	gRExp.Pattern = "^800(2|4)0_\d{10}_\d{8}_\d*_\d{10}.xml$"

	'test in safe mode
	On Error Resume Next
		tMaskTestResult = gRExp.Test(inFile.Name)
		If Err.Number <> 0 Then
			gLog.LogLine tLogTag, False, "Mask check error by pattern <" & gRExp.Pattern & ">!"
			gLog.LogLine tLogTag, False, "Details: error #" & Err.Number & " by source <" & Err.Source & ">: " & Err.Description
			On Error GoTo 0
			Exit Function
		End If
	On Error GoTo 0
	
	'test results
	If Not tMaskTestResult Then
		gLog.LogLine tLogTag, False, "File name check: FAIL"
		Exit Function
	End If
	

	'extracting name data
	tNameElements = fGetFileName(inFile.Name) 'Left(inFile.Name, InStr(inFile.Name, ".") - 1) 'removing extension
	tNameElements = Split(tNameElements, "_")

	tClassCode = tNameElements(0)
	tTraderINN = tNameElements(1)
	tDate = tNameElements(2)
	tNumber = tNameElements(3)
	tAISSCode = tNameElements(4)

	If Not fReadTimeStamp(tDate, tDateProcessed) Then
		gLog.LogLine tLogTag, False, "File name check: FAIL (<" & tDate & "> is not DATE)"
		Exit Function
	End If

	gLog.LogLine tLogTag, False, "File name check: OK"

	' 02 // LOADING as XML
	On Error Resume Next
		Set tTempXML = CreateObject("Msxml2.DOMDocument.6.0")
		tTempXML.ASync = False
		tTempXML.Load inFile.Path
		If Err.Number <> 0 Then
			gLog.LogLine tLogTag, False, "File loading as XML failed!"
			gLog.LogLine tLogTag, False, "Details: error #" & Err.Number & " by source <" & Err.Source & ">: " & Err.Description
			On Error GoTo 0
			Exit Function
		End If
	On Error GoTo 0

	'parsing check
	If tTempXML.parseError.ErrorCode <> 0 Then
		gLog.LogLine tLogTag, False, "File parsing failed!"
		gLog.LogLine tLogTag, False, "ErrorCode (" & tTempXML.parseError.ErrorCode & ") at line [" & tTempXML.parseError.Line & ":" & tTempXML.parseError.LinePos & "] with reason: " & tTempXML.parseError.Reason
		Exit Function
	End If

	'quick content check (header only:: no XSD -- XSD will remove most of those stupid checks)
	Set tNode = tTempXML.DocumentElement
	If tNode.NodeName <> "message" Then
		gLog.LogLine tLogTag, False, "Root node name not <message>! Parsing failed."
		Exit Function
	End If

	'header attributes check
	tAttributeName = "class"
	If Not fGetAttr(tNode, tAttributeName, tValue, vbNullString, tErrorText) Then
		gLog.LogLine tLogTag, False, "Root node attributes read error @" & tAttributeName & "!"
		gLog.LogLine tLogTag, False, tErrorText
		Exit Function
	End If

	If tClassCode <> tValue Then
		gLog.LogLine tLogTag, False, "Class in filename (" & tClassCode & ") and attr (@" & tAttributeName & "=" & tValue & ") mismatch!"
		Exit Function
	End If

	tAttributeName = "version"
	If Not fGetAttr(tNode, tAttributeName, tValue, vbNullString, tErrorText) Then
		gLog.LogLine tLogTag, False, "Root node attributes read error @" & tAttributeName & "!"
		gLog.LogLine tLogTag, False, tErrorText
		Exit Function
	End If

	'finalyze
	gLog.LogLine tLogTag, False, "File internal header: OK (Class=" & tClassCode & "; Version=" & tValue & "; Date=" & tDate & ")"
	outVersion = tValue
	outClass = tClassCode
	outDate = tDateProcessed
	Set outXML80020 = tTempXML
	Set tTempXML = Nothing	
	fCheckXML80020 = True	
End Function

' fGetAttr - safe attribute reader
Private Function fGetAttr(inXML, inAttributeName, outValue, inDefaultValue, outErrorText)
	Dim tValue, tTypeName

	'prepare
	fGetAttr = False
	outErrorText = vbNullString
	outValue = inDefaultValue

	'check #1
	tTypeName = TypeName(inXML)
	If Not (tTypeName = "IXMLDOMSelection" Or tTypeName = "IXMLDOMElement" Or tTypeName = "DOMDocument60") Then
		outErrorText = "inXML type error: " & tTypeName
		Exit Function
	End If

	On Error Resume Next
		tValue = inXML.GetAttribute(inAttributeName)

        If IsNull(tValue) Then
			outErrorText = "inAttributeName (" & inAttributeName & ") empty!"
			On Error GoTo 0
			Exit Function
		End If

        If Err.Number <> 0 Then
			outErrorText = "inAttributeName (" & inAttributeName & ") read error: " & fGetErrTextView(Err)
			On Error GoTo 0
			Exit Function
		End If
	On Error GoTo 0

	outValue = tValue
	fGetAttr = True
End Function

Private Function fGetErrTextView(inErr)
	If inErr.Number <> 0 Then
		fGetErrTextView = "Details: error #" & inErr.Number & " by source <" & inErr.Source & ">: " & inErr.Description
	Else
		fGetErrTextView = vbNullString
	End If
End Function

Private Function fCheckClassVersionReference(inClass, inVersion)
	Dim tVersion

	fCheckClassVersionReference = False

	If Not IsNumeric(inVersion) Then: Exit Function
	tVersion = Fix(inVersion)
	If tVersion - inVersion <> 0 Then: Exit Function

	Select Case inClass
		Case "80020":
			if tVersion < 1 Or tVersion > 2 Then: Exit Function
		Case "80040":
			if tVersion < 1 Or tVersion > 2 Then: Exit Function
		Case Else:
			Exit Function
	End Select
	fCheckClassVersionReference = True
End Function

Private Sub fHourStringConvertToIntArray(inHourString, outHoursArray, inSize, outErrorText)
	Dim tIndex, tValue, tDefaultValue, tExtendArray, tLogTag, tSize

	tLogTag = "fHourStringConvertToIntArray"
	tDefaultValue = 1
	outErrorText = vbNullString

	If inSize = 24 Or inSize = 48 Then
		tSize = inSize
	Else
		tSize = 24
		outErrorText = tLogTag & " > Size failed [inSize=" & inSize & "] -> autofix applied!"
	End If

	ReDim outHoursArray(tSize - 1)

	tExtendArray = (Len(inHourString) = 24 And tSize = 48)
	If tExtendArray Then: outErrorText = tLogTag & " > Autoextending from 24 to 48 applied!"

	If Not (Len(inHourString) = 24 Or Len(inHourString) = 48) Then
		outErrorText = tLogTag & " > Length failed [Len=" & Len(inHourString) & "] -> autofix applied!"
		For tIndex = 0 To tSize - 1
			outHoursArray(tIndex) = tDefaultValue
		Next
	Else
		For tIndex = 1 To Len(inHourString)
			tValue = Mid(inHourString, tIndex, 1)
			If IsNumeric(tValue) Then
				tValue = Fix(tValue)
				If tValue <> 0 Then: tValue = tDefaultValue 'autofix
			Else
				tValue = tDefaultValue 'autofix
			End If

			If tExtendArray Then
				outHoursArray((tIndex - 1) * 2) = tValue
				outHoursArray((tIndex - 1) * 2 + 1) = tValue
			Else
    			outHoursArray(tIndex - 1) = tValue
			End If
		Next
	End If
End Sub

'fGetSOHours - return array(len=24) of INTs with 0 or 1
Private Function fGetSOHours(inYear, inMonth, inZoneCode, outHours)
	Dim tDateIndex, tHourString

	fGetSOHours = False

	outHours = "111111111111111111111111" 'default
	
	tDateIndex = fNZeroAdd(inYear, 4) & "-" & fNZeroAdd(inMonth, 2) & "-" & inZoneCode
	Select Case tDateIndex
		Case "2021-10-1": outHours = "111111100000000000000111"
		Case Else: Exit Function
	End Select

	fGetSOHours = True
End Function

Private Sub fChannelCodeAutoFix(ioChannelCode)
	Dim tChannelCode
	If Not IsNumeric(ioChannelCode) Then
		ioChannelCode = vbNullString
		Exit Sub
	End If
	tChannelCode = Fix(ioChannelCode)
	If tChannelCode < 1 Or tChannelCode > 4 Then
		ioChannelCode = vbNullString
		Exit Sub
	End If
	ioChannelCode = fNZeroAdd(tChannelCode, 2)
End Sub

' fAddFillCommandResolve - reading ADDFILL command from setted string
'	SYNTAX
'	ADDFILL:CLASS:AREACode:MPCode:CHCode:LCHCode:TZCode:HOUR_FILTER(or AUTO):VALUE
'
'	EXAMPLE
'	ADDFILL:80020:5600010901:564130032113101:01:03:1:AUTO:-100	
'
Private Function fAddFillCommandResolve(inCommandElements, outOperation, outToClass, outAreaCode, outMPointCode, outMainChannelCode, outLinkedChannelCode, outZoneIndex, outAffectHourArray, inDate, outValue, outErrorText, outWarning)
	Dim tElementsCount, tHourString, tHalfHourString, tOperationName, tElementIndex

	fAddFillCommandResolve = False
	outErrorText = vbNullString
	outWarning = vbNullString
	tOperationName = cmd_ADDFILL
	tElementsCount = 9
	tElementIndex = 0

	If UBound(inCommandElements) <> tElementsCount - 1 Then
		inErrorText = "Command check failed by common element counting for operation [" & tOperationName & "][Found=" & UBound(inCommandElements)+1 & " // Need=" & tElementsCount & "]"
		Exit Function
	End If

	'01 // CLASS FILTER :: 80020 or 80040 (or empty)
	tElementIndex = tElementIndex + 1
	outToClass = inCommandElements(tElementIndex)
	If Not (outToClass = "80020" or outToClass = "80040") Then
		outToClass = vbNullString 'autofix on missread
		outWarning = "Class filter has wrong value [" & outToClass & "] and will be setted to default."
	End If

	'02 // AREA FILTER :: Using AREA code (no check - soft apply)
	tElementIndex = tElementIndex + 1
	outAreaCode = inCommandElements(tElementIndex)

	'03 // MEASURING POINT (MP) FILTER :: cannot be empty
	tElementIndex = tElementIndex + 1
	outMPointCode = inCommandElements(tElementIndex)
	If outMPointCode = vbNullString Then
		inErrorText = "Error in resolve [" & tOperationName & "]: MPointCode cannot be empty!"
		Exit Function
	End If

	'04 // MP CHANNEL FILTER :: cannot be empty
	tElementIndex = tElementIndex + 1
	outMainChannelCode = inCommandElements(tElementIndex)
	fChannelCodeAutoFix outMainChannelCode 'autofix values to format DD
	If outMainChannelCode = vbNullString Then
		inErrorText = "Error in resolve [" & tOperationName & "]: MainChannelCode cannot be empty!"
		Exit Function
	End If	
	
	'05 // MP CHANNEL linked FILTER :: it'll adjust this linked channel by rules of command
	tElementIndex = tElementIndex + 1
	outLinkedChannelCode = inCommandElements(tElementIndex)
	fChannelCodeAutoFix outLinkedChannelCode

	'06 // TRADE ZONE FILTER :: using trade zone index to apply some calculations by it
	tElementIndex = tElementIndex + 1
	outZoneIndex = inCommandElements(tElementIndex)
	If Len(outZoneIndex) <> 1 Then
		inErrorText = "Error in resolve [" & tOperationName & "]: ZoneIndex cannot be empty!"
		Exit Function
	ElseIf Not IsNumeric(outZoneIndex) Then
		inErrorText = "Error in resolve [" & tOperationName & "]: ZoneIndex not numeric value!"
		Exit Function
	Else
		outZoneIndex = Fix(outZoneIndex)
		If outZoneIndex < 1 Or outZoneIndex > 9 Then
			inErrorText = "Error in resolve [" & tOperationName & "]: ZoneIndex not in [1..9]!"
			Exit Function
		End If
	End If

	'07 // APPLY SEQ FILTER :: used to set hours(halfhours) which are used to apply command
	tElementIndex = tElementIndex + 1
	tHalfHourString = inCommandElements(tElementIndex)
	If tHalfHourString = "AUTO" Then 'auto mode will try to get hours which are not in SOPeaks range
		If Not fGetSOHours(Year(inDate), Month(inDate), outZoneIndex, tHourString) Then
			outWarning = "fGetSOHours failed. Default string: " & tHourString
		Else
			outWarning = "AUTO hours set: " & tHalfHourString
		End If
		tHalfHourString = tHourString		
	End If

	'will convert STRING of hours(halfhours) to INT array (and will fix issues if occured)
	fHourStringConvertToIntArray tHalfHourString, outAffectHourArray, 48, outWarning

	'08 // VALUE :: set value to apply by command
	tElementIndex = tElementIndex + 1
	outValue = inCommandElements(tElementIndex)
	If Not IsNumeric(outValue) Then
		inErrorText = "Error in resolve [" & tOperationName & "]: Value not is numeric!"
		Exit Function
	End If

	fAddFillCommandResolve = True
End Function

Private Function fResolveCommand(inCommand, outOperation, outToClass, outAreaCode, outMPointCode, outMainChannelCode, outLinkedChannelCode, outZoneIndex, outAffectHourArray, inDate, outValue)
	Dim tLogTag
	Dim tCommandElements, tErrorText, tWarningText

	tLogTag = "fResolveCommand"
	fResolveCommand = False

	'defaults
	outOperation = vbNullString
	outToClass = 0
	outAreaCode = 0
	outMPointCode = 0
	outMainChannelCode = 0
	outLinkedChannelCode = 0
	outZoneIndex = 0
	outAffectHourArray = 0
	outValue = 0

	'check 1
	tCommandElements = Split(UCase(inCommand), cmdInternalSeparator)
	If UBound(tCommandElements) < 1 Then
		gLog.LogLine tLogTag, False, "Command check failed by common element counting"
		Exit Function
	End If

	outOperation = tCommandElements(0)
	Select Case outOperation
		Case cmd_ADDFILL: 
			gLog.LogLine tLogTag, False, "Operation [" & outOperation & "] by command: [" & UCase(inCommand) & "]"
			If Not fAddFillCommandResolve(tCommandElements, outOperation, outToClass, outAreaCode, outMPointCode, outMainChannelCode, outLinkedChannelCode, outZoneIndex, outAffectHourArray, inDate, outValue, tErrorText, tWarningText) Then
				fWarningLog tLogTag, tWarningText
				gLog.LogLine tLogTag, False, "Operation [" & outOperation & "] resolve error: " & tErrorText
				Exit Function
			End If
			fWarningLog tLogTag, tWarningText
		Case Else:
			gLog.LogLine tLogTag, False, "Operation [" & outOperation & "] unknown!"
			Exit Function
	End Select

	fResolveCommand = True
End Function

Private Sub fWarningLog(inLogTag, inText)
	Dim tDefaultTag

	If inText = vbNullString Then: Exit Sub
	
	tDefaultTag = "fWarningLog"
	If inLogTag <> vbNullString Then: tDefaultTag = inLogTag
	
	gLog.LogLine tDefaultTag, False, inText
End Sub

' fXML80020Injection - will apply commands in inCommandList to inFile data (on command fail will rollback filedata to previuos state)
Private Sub fXML80020Injection(inFile, inCommandList)
	Dim tLogTag
	Dim tXML80020, tVersion, tClass, tDate, tCommandList, tCommand, tRollBackNeeded

	tLogTag = "fXML80020Injection"
	gLog.LogLine tLogTag, False, "File: " & inFile.Name

	' 01 \\ Check (quick header scan) target file on structure (need XSD for best check)
	If Not fCheckXML80020(inFile, tClass, tVersion, tDate, tXML80020) Then
		gLog.LogLine tLogTag, False, "Injection aborted: filecheck filed"
		WScript.Echo "Файл не удалось открыть (подробности в лог-файле):" & vbCrLf & vbCrLf & inFile.Name
		Exit Sub
	End If
	
	' 02 \\ Check version and class to be
	If Not fCheckClassVersionReference(tClass, tVersion) Then
		gLog.LogLine tLogTag, False, "Injection aborted: version or class not acceptable to process"
		WScript.Echo "Файл не соотвествует форматам КЛАССА или ВЕРСИИ (подробности в лог-файле):" & vbCrLf & vbCrLf & inFile.Name
		Exit Sub
	End If

	' 03 \\
	tCommandList = Split(UCase(inCommandList), cmdSeparator)

	For Each tCommand In tCommandList
		If Not fExecuteCommand(tCommand, inFile, tXML80020, tClass, tVersion, tDate, tRollBackNeeded) Then
			gLog.LogLine tLogTag, False, "Injection failed: COMMAND = [" & tCommand & "]"
		Else
			gLog.LogLine tLogTag, False, "Injection done!"
			fSaveXMLChanges inFile.Path, tXML80020, True
		End If
	Next
	
End Sub

' fAddFillCommandApply - main ADDFILL modifier
Private Function fAddFillCommandApply(inHalfHourArray, inValue, outErrorText, outInfoLine, inLogDetails)
	Dim tUBoundIndex, tIndex, tCounter, tAverageValue, tAccumulateValue, tCheckValue, tIsNegative, tSuffixValue
	Dim tShowList

	fAddFillCommandApply = False
	outErrorText = vbNullString
	outInfoLine = "Injection:"

	tUBoundIndex = UBound(inHalfHourArray)

	' get values to apply count
	tCounter = 0
	For tIndex = 0 To tUBoundIndex
		tCounter = tCounter + inHalfHourArray(tIndex)
	Next

	If tCounter = 0 Then
		outErrorText = "Array of apply is EMPTY! [tCounter=0]"
		Exit Function
	End If

	tIsNegative = (inValue < 0)
	tAccumulateValue = Abs(inValue)
	tAverageValue = tAccumulateValue / tCounter
	tSuffixValue = 0
	tCheckValue = 0

	For tIndex = 0 To tUBoundIndex
		If inHalfHourArray(tIndex) = 1 Then
			inHalfHourArray(tIndex) = Round(tAverageValue + tSuffixValue, 0)
			tSuffixValue = tSuffixValue + tAverageValue - inHalfHourArray(tIndex)
			'debug comment
			If inLogDetails Then: gLog.LogLine "CALC", False, "tIndex=" & tIndex & " > VAL=" & inHalfHourArray(tIndex) & " SUFF=" & tSuffixValue & " AVG=" & tAverageValue
			If tIsNegative Then: inHalfHourArray(tIndex) = -inHalfHourArray(tIndex)
		End If
		outInfoLine = outInfoLine & " " & inHalfHourArray(tIndex)
		tCheckValue = tCheckValue + inHalfHourArray(tIndex)
	Next

	tCheckValue = Round(tCheckValue, 0)

	outInfoLine = outInfoLine & " // SUM=" & tCheckValue & " (DIFF=" & tCheckValue - inValue & ")"

	If tCheckValue - inValue <> 0 Then
		outErrorText = "Math error. SUM check failed!"
		Exit Function
	End If

	fAddFillCommandApply = True
End Function

' fPrepareInjectValues - prepare inject values by operations select
Private Function fPrepareInjectValues(inOperation, inHalfHourArray, inValue)
	Dim tLogTag, tErrorText, tInfoText

	tLogTag = "fPrepareInjectValues"
	fPrepareInjectValues = False

	Select Case inOperation
		Case cmd_ADDFILL: 
			If Not fAddFillCommandApply(inHalfHourArray, inValue, tErrorText, tInfoText, False) Then
				fWarningLog tLogTag, tInfoText
				gLog.LogLine tLogTag, False, "Operation [" & inOperation & "]: " & tErrorText
				Exit Function
			End If
			fWarningLog tLogTag, tInfoText
		Case Else:
			gLog.LogLine tLogTag, False, "Operation [" & inOperation & "] unknown!"
	End Select

	fPrepareInjectValues = True
End Function

' fGetWorkNodes - node extractor
Private Function fGetWorkNodes(inXML, inAreaCode, inMPointCode, inMainChannelCode, inLinkedChannelCode, outMainNode, outLinkedNode)
	Dim tLogTag, tXPathReqBase, tXPathReq, tTypeName

	tLogTag = "fGetWorkNodes"
	fGetWorkNodes = False
	Set outMainNode = Nothing
	Set outLinkedNode = Nothing

	'inXML CHECK
	If inXML Is Nothing Then
		gLog.LogLine tLogTag, False, "inXML not defined!"
		Exit Function
	End If

	tTypeName = TypeName(inXML)
	If Not (tTypeName = "IXMLDOMSelection" Or tTypeName = "IXMLDOMElement" Or tTypeName = "DOMDocument60") Then
		gLog.LogLine tLogTag, False, "inXML type error: " & tTypeName
		Exit Function
	End If

	'AREA
	tXPathReqBase = "//area"
	If inAreaCode <> vbNullString Then: tXPathReqBase = tXPathReqBase & "[inn='" & inAreaCode & "']"

	'MPoint
	tXPathReqBase = tXPathReqBase & "/measuringpoint[@code='" & inMPointCode & "']"

	'MainLock /measuringchannel[@code='" & inMainChannelCode & "']"
	tXPathReq = tXPathReqBase & "/measuringchannel[@code='" & inMainChannelCode & "']"
	Set outMainNode = inXML.SelectSingleNode(tXPathReq)
	If outMainNode is Nothing Then
		gLog.LogLine tLogTag, False, "Failed to lock main channel node: <" & tXPathReq & ">"
		Exit Function
	Else
		gLog.LogLine tLogTag, False, "Locked main channel node: <" & tXPathReq & ">"
	End If

	If inLinkedChannelCode <> vbNullString Then
		tXPathReq = tXPathReqBase & "/measuringchannel[@code='" & inLinkedChannelCode & "']"
		Set outLinkedNode = inXML.SelectSingleNode(tXPathReq)
		If outLinkedNode is Nothing Then
			gLog.LogLine tLogTag, False, "[WARN] Failed to lock licked channel node: <" & tXPathReq & ">"
		Else
			gLog.LogLine tLogTag, False, "Locked linked channel node: <" & tXPathReq & ">"
		End If
	End If
	
	fGetWorkNodes = True
End Function

Private Function fGetHourSuffixByIndex(inIndex)
	If inIndex mod 2 = 0 Then
		fGetHourSuffixByIndex = "00"
	Else
		fGetHourSuffixByIndex = "30"
	End If
End Function

' fGetPeriodAttributeValuesByIndex
Private Function fGetPeriodAttributeValuesByIndex(inIndex)
	Dim tStartHour, tEndHour, tStartHourSuffix, tEndHourSuffix

	fGetPeriodAttributeValuesByIndex = vbNullString
	
	If Not IsNumeric(inIndex) Then: Exit Function
	If inIndex < 0 Or inIndex > 47 Then: Exit Function

	tStartHour = fNZeroAdd(inIndex \ 2, 2)
	
	tEndHour = (inIndex + 1) \ 2	
	If tEndHour = 24 Then: tEndHour = 0
	tEndHour = fNZeroAdd(tEndHour, 2)

	tStartHourSuffix = fGetHourSuffixByIndex(inIndex)
	tEndHourSuffix = fGetHourSuffixByIndex(inIndex + 1)
	
	fGetPeriodAttributeValuesByIndex = "[(@start='" & tStartHour & tStartHourSuffix & "' and @end='" & tEndHour & tEndHourSuffix & "')]"
End Function

Private Function fIsCommercical(inValue, outErrorText)
	Dim tValue

	fIsCommercical = False
	outErrorText = vbNullString

	tValue = inValue
	If Not IsNumeric(tValue) Then
		outErrorText = "Value IS NOT NUMERIC [tValue=" & tValue & "]"
		Exit Function
	End If
	
	If (tValue - Fix(tValue)) <> 0 Then
		outErrorText = "Value IS FLOAT [tValue=" & tValue & "]"
		Exit Function
	End If

	tValue = Fix(tValue)
	If tValue < 0 Then
		outErrorText = "Value IS NEGATIVE [tValue=" & tValue & "]"
		Exit Function
	End If

	fIsCommercical = True
End Function

' fApplyAjustingByMode - adjust logic applier
' mode 0 - default 				// X = X + A
' mode 1 - adjust shrinker 		// X = X + X * A
' mode 2 - direct shrinker 		// X = X * A
' mode 3 - replacer 			// X = A
Private Sub fApplyAjustingByMode(inCurrentValue, ioNewValue, ioAdjustValue, inAdjustMode, inRoundIndex)
	Select Case inAdjustMode
		Case 0: 
			ioNewValue = inCurrentValue + ioAdjustValue
		Case 1:
			ioNewValue = inCurrentValue + inCurrentValue * ioAdjustValue
		Case 2:
			ioNewValue = inCurrentValue * ioAdjustValue
		Case 3:
			ioNewValue = ioAdjustValue
		Case Else: 
			ioNewValue = inCurrentValue + ioAdjustValue
	End Select

	ioNewValue = Round(ioNewValue, inRoundIndex)
	ioAdjustValue = ioNewValue - inCurrentValue
End Sub

' fApplyInjectionToValue - check value in .text by xpath request and adjust it with new value (XML80020 by ATS def values must be INT and 0...MAXINT)
' inAdjustMode - will apply adjust by selected mode (defalult - addiction)
Private Function fApplyInjectionToValue(ioRootNode, inXPathRequest, inAdjustValue, inAdjustMode, outOldValue, outNewValue, outWasChanged, inNodeDescription, inLogDetails)
	Dim tNode, tLogTag, tErrorText
	Dim tCurrentValue, tNewValue, tAdjustValue

	fApplyInjectionToValue = False
	outOldValue = -1
	outNewValue = -1
	outWasChanged = False
	tLogTag = "fApplyInjectionToValue"

	'Trottling
	tAdjustValue = inAdjustValue
	If tAdjustValue = 0 Then
		fApplyInjectionToValue = True
		Exit Function
	End If

	Set tNode = ioRootNode.SelectSingleNode(inXPathRequest)
	If tNode Is Nothing Then
		gLog.LogLine tLogTag, False, "Node select failed [node: " & inNodeDescription & "] by request XPath [" & inXPathRequest & "]"
		Exit Function
	End If

	' READ node VALUE from .Text
	tCurrentValue = tNode.Text
	If Not fIsCommercical(tCurrentValue, tErrorText) Then
		gLog.LogLine tLogTag, False, "Value read-check failed [node: " & inNodeDescription & "]: " & tErrorText & " // XPath [" & inXPathRequest & "]"
	End If
	tCurrentValue = Fix(tCurrentValue)

	fApplyAjustingByMode tCurrentValue, tNewValue, tAdjustValue, inAdjustMode, 0

	If tNewValue < 0 Then
		gLog.LogLine tLogTag, False, "Failed to set value [node: " & inNodeDescription & "] (NEGATIVE RESULT [tCurrentValue=" & tCurrentValue & "; tNewValue=" & tNewValue & "; tAdjustValue=" & tAdjustValue & "]). XPath [" & inXPathRequest & "]"
		Exit Function
	End If
	
	' APPLY NEW VALUE
	tNode.Text = tNewValue
	outWasChanged = True
	outOldValue = tCurrentValue
	outNewValue = tNewValue

	If inLogDetails Then: gLog.LogLine tLogTag, False, "Set value [node: " & inNodeDescription & "] ([tCurrentValue=" & tCurrentValue & "; tNewValue=" & tNewValue & "; tAdjustValue=" & tAdjustValue & "]). XPath [" & inXPathRequest & "]"

	Set tNode = Nothing
	fApplyInjectionToValue = True
End Function

Private Function fApplyInjectionToWorkNode(ioMainNode, ioLinkedNode, inAffectArray, ioRollBackNeeded, inLogDetails)
	Dim tLogTag, tHasLink, tMainWorkNode, tLinkedWorkNode, tXPathReq, tLinkedValueModifier, tWasChanged, tIndex, tMainInjectionSum, tLinkedInjectionSum
	Dim tAdjustValue, tOldMainValue, tNewMainValue, tOldLinkedValue, tNewLinkedValue, tAdjustMainValue

	tLogTag = "fApplyInjectionToWorkNode"
	fApplyInjectionToWorkNode = False
	tWasChanged = False
	tMainInjectionSum = 0
	tLinkedInjectionSum = 0

	tHasLink = (Not ioLinkedNode is Nothing)

	For tIndex = 0 To UBound(inAffectArray)
		
		tAdjustMainValue = inAffectArray(tIndex)
		
		If tAdjustMainValue <> 0 Then
			
			tXPathReq = "child::period" & fGetPeriodAttributeValuesByIndex(tIndex) & "/value"

			If Not fApplyInjectionToValue(ioMainNode, tXPathReq, tAdjustMainValue, 0, tOldMainValue, tNewMainValue, tWasChanged, "MAIN", inLogDetails) Then
				gLog.LogLine tLogTag, "Failed to APPLY ADJUST INJECTION!"
				Exit Function
			End If

			tMainInjectionSum = tMainInjectionSum + tNewMainValue - tOldMainValue

			If tHasLink Then
				tLinkedValueModifier = tAdjustMainValue / tOldMainValue

				If Not fApplyInjectionToValue(ioLinkedNode, tXPathReq, tLinkedValueModifier, 1, tOldLinkedValue, tNewLinkedValue, tWasChanged, "LINKED", inLogDetails) Then
					gLog.LogLine tLogTag, "Failed to APPLY ADJUST INJECTION!"
					Exit Function
				End If

				tLinkedInjectionSum = tLinkedInjectionSum + tNewLinkedValue - tOldLinkedValue				
			End If
		End If
	Next

	gLog.LogLine tLogTag, False, "Main injection = " & tMainInjectionSum & "; Linked injection = " & tLinkedInjectionSum
	fApplyInjectionToWorkNode = True
End Function

' fExecuteCommand - command executor
Private Function fExecuteCommand(inCommand, inFile, inXML, inClass, inVersion, inDate, outRollBackChanges)
	Dim tOperation, tClass, tAreaCode, tMPointCode, tMainChannelCode, tLinkedChannelCode, tZoneIndex, tAffectHourArray, tValue, tCommand, tCommandList
	Dim tMainNode, tLinkedNode
	Dim tLogTag

	tLogTag = "fExecuteCommand"
	fExecuteCommand = False
	outRollBackChanges = False

	' 01 \\
	If Not fResolveCommand(inCommand, tOperation, tClass, tAreaCode, tMPointCode, tMainChannelCode, tLinkedChannelCode, tZoneIndex, tAffectHourArray, inDate, tValue) Then
		gLog.LogLine tLogTag, False, "Injection aborted: Command syntax ERROR = " & inCommand
		Exit Function
	End If

	' 02 \\
	If tClass <> vbNullString Then
		If tClass <> inClass Then
			gLog.LogLine tLogTag, False, "Command class not equal to Command class! [CommandClass=" & tClass & " // FileClass=" & inClass & "]"
			Exit Function
		End If
	End If

	' 03 \\ Prepare inject values
	If Not fPrepareInjectValues(tOperation, tAffectHourArray, tValue) Then
		gLog.LogLine tLogTag, False, "Operation [" & tOperation & "] data preapare failed!"
		Exit Function
	End If

	' 04 \\ Select work node
	If Not fGetWorkNodes(inXML, tAreaCode, tMPointCode, tMainChannelCode, tLinkedChannelCode, tMainNode, tLinkedNode) Then
		gLog.LogLine tLogTag, False, "Work node not locked!"
		Exit Function
	End If

	If Not fApplyInjectionToWorkNode(tMainNode, tLinkedNode, tAffectHourArray, outRollBackChanges, False) Then
		gLog.LogLine tLogTag, False, "Injection failed! [RollBackChanges=" & outRollBackChanges & "]"
		Exit Function
	End If

	fExecuteCommand = True
End Function

fInit
fMain
fQuit
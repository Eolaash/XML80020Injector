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
Const cmdFileName = "CommandList.txt"
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

Class CContext
	Private pIsActive
	Private pXML
	Private pRootNode
	Private pStatus
	Private pSplitter
	Private pLimitElements
	Private pEmptyFiller

	Public Property Get Active()
    	Set Active = pIsActive
   	End Property

	Public Property Get Status()
    	Set Status = pStatus
   	End Property

	Public Function GetContextAsText()
		GetContextAsText = vbNullString
		If Not pIsActive Then: Exit Function
		GetContextAsText = pRootNode.xml
	End Function

	Private Sub Class_Initialize()
		pIsActive = False
		pSplitter = ":#:"
		pEmptyFiller = ":#E:"
		pLimitElements = 500

		'On Error Resume Next

		Set pXML = CreateObject("Msxml2.DOMDocument.6.0")
		Set pRootNode = pXML.AppendChild(pXML.CreateElement("context"))

		If Err.Number <> 0 Then
			pStatus = "Init failed! Details: error #" & Err.Number & " by source <" & Err.Source & ">: " & Err.Description
			Set pXML = Nothing
			Set pRootNode = Nothing
			Exit Sub
		End If

		'On Error Goto 0
		pIsActive = True
	End Sub

	Private Sub Class_Terminate()
		Set pXML = Nothing
		Set pRootNode = Nothing
		pIsActive = False
	End Sub

	Private Function IsAcceptable(inVarID)
		' vbEmpty	0	uninitialized data type
		' vbNull	1	contains no valid data
		' vbBoolean	11	Boolean data type
		' vbByte	17	Byte data type
		' vbInteger	2	Integer data type
		' vbLong	3	Long data type
		' vbSingle	4	Single data type
		' vbDouble	5	Double data type
		' vbDate	7	Date data type
		' vbString	8	String data type
		' vbObject	9	Object data type
		' vbVariant	12	Variant data type
		' vbArray	8192	Array data type
		IsAcceptable = False

		Select Case inVarID
			Case "2", "3", "4", "5", "7", "8", "11", "12", "17":
			Case Else: Exit Function
		End Select

		IsAcceptable = True
	End Function

	Private Function SafeUBound(inArray)
		SafeUBound = -2
		On Error Resume Next		
			SafeUBound = UBound(inArray)
			If IsArray(inArray) And Err.Number <> 0 Then: SafeUBound = -1
		On Error Goto 0
	End Function

	Public Function SetParam(inParamName, inParamValue)
		Dim tNode, tRootNode, tXPathReq
		Dim inParentNode, tParamName, tParamValueType, tParamValue, tIsArray, tUBound, tElement

		SetParam = False

		If inParamName = vbNullString Then: Exit Function
		'If inParamValue = vbNullString Then: Exit Function

		'VAR CHECK
		tIsArray = 0		
		tParamValueType = VarType(inParamValue)

		If IsArray(inParamValue) Then
			tIsArray = 1
			tParamValueType = tParamValueType - 8192 'array id
		End If
		
		If Not IsAcceptable(tParamValueType)  Then
			pStatus = "Param type error! tParamValueType=[" & tParamValueType & "] inParamName=[" & inParamName & "]"
			Exit Function
		End If

		tUBound = -2
		If tIsArray = 1 Then
			tUBound = SafeUBound(inParamValue)
			If tUBound < -1 Or tUBound > pLimitElements Then
				pStatus = "Param type error! tUBound=[" & tUBound & "] overload pLimitElements=[" & pLimitElements & "]! tParamValueType=[" & tParamValueType & "] inParamName=[" & inParamName & "]"
				Exit Function
			End If
		End If

		'PARENT SELECT
		inParentNode = vbNullString 'for future update
		If inParentNode = vbNullString Then
			Set tRootNode = pRootNode
		End If

		'PARAM SELECT
		tParamName = inParamName

		'On Error Resume Next
		tXPathReq = "child::param[@name='" & tParamName & "']"
		Set tNode = tRootNode.SelectSingleNode(tXPathReq)
		If tNode Is Nothing Then: Set tNode = pRootNode.AppendChild(pXML.CreateElement("param"))
		If tNode Is Nothing Then
			pStatus = "Param creation error XPath[" & tXPathReq & "]: inParamName=[" & inParamName & "]"
			Exit Function
		End If

		tNode.SetAttribute "name", tParamName
		tNode.SetAttribute "array", tIsArray
		tNode.SetAttribute "varid", tParamValueType

		If tIsArray = 1 Then
			tParamValue = vbNullString
			For Each tElement In inParamValue
				If IsEmpty(tElement) Then: tElement = pEmptyFiller
				If tParamValue = vbNullString Then 
					tParamValue = tElement					
				Else
					tParamValue = tParamValue & pSplitter & tElement
				End If
				'WScript.Echo TypeName(tElement) & "::" & tElement & " >> [" & tParamValue & "]"
			Next
		Else
			tParamValue = inParamValue
		End If

		' WRITE IT
		tNode.Text = tParamValue

		Set tNode = Nothing
		
		SetParam = True
	End Function

	Private Function GetTypeValue(inRawValue, inVarID)
		' vbEmpty	0	uninitialized data type
		' vbNull	1	contains no valid data
		' vbBoolean	11	Boolean data type
		' vbByte	17	Byte data type
		' vbInteger	2	Integer data type
		' vbLong	3	Long data type
		' vbSingle	4	Single data type
		' vbDouble	5	Double data type
		' vbDate	7	Date data type
		' vbString	8	String data type
		' vbObject	9	Object data type
		' vbVariant	12	Variant data type
		' vbArray	8192	Array data type
		' CBool, CByte, CInt, CLng, CSng, CDbl, CDate, CStr.
		GetTypeValue = Empty 'default

		Select Case inVarID
			Case "12": GetTypeValue = inRawValue
			Case "2": GetTypeValue = CInt(inRawValue)
			Case "3": GetTypeValue = CLng(inRawValue)
			Case "4": GetTypeValue = CSng(inRawValue)
			Case "5": GetTypeValue = CDbl(inRawValue)
			Case "7": GetTypeValue = CDate(inRawValue)
			Case "8": GetTypeValue = CStr(inRawValue)
			Case "11": GetTypeValue = CBool(inRawValue)
			Case "17": GetTypeValue = CByte(inRawValue)
			Case Else: Exit Function
		End Select

	End Function

	Public Function GetParam(inParamName, outValue)
		Dim tNode, tValue, tIsArray, tVarType, tRawValue, tIndex

		GetParam = False
		outValue = Empty
		If inParamName = vbNullString Then: Exit Function

		Set tNode = pRootNode.SelectSingleNode("child::param[@name='" & inParamName & "']")
		If tNode Is Nothing Then
			WScript.Echo "No param:" & inParamName
			Exit Function
		End If
		tIsArray = tNode.GetAttribute("array")
		tVarType = tNode.GetAttribute("varid")		

		If tIsArray = "1" Then 
			tRawValue = Split(tNode.Text, pSplitter)
			ReDim tValue(UBound(tRawValue))
			For tIndex = 0 To UBound(tRawValue)
				If tRawValue(tIndex) <> pEmptyFiller Then
					tValue(tIndex) = GetTypeValue(tRawValue(tIndex), tVarType)
				End If
			Next
		Else
			tRawValue = tNode.Text
			tValue = GetTypeValue(tRawValue, tVarType)
		End If

		outValue = tValue
		GetParam = True
	End Function

	Public Sub DeleteParam(inParamName)
		Dim tNode
		If inParamName = vbNullString Then: Exit Sub
		For Each tNode In pRootNode.SelectNodes("child::param[@name='" & inParamName & "']")
    		tNode.ParentNode.RemoveChild(tNode)
		Next
	End Sub

	Public Sub DeleteAllParam()
		Dim tNode
		For Each tNode In pRootNode.ChildNodes
    		tNode.ParentNode.RemoveChild(tNode)
		Next
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
	Dim tFilePath, tFile, tLogTag, tIndex, tCommandList
	Dim tCommandListContext
	Dim tCommandListCount

	tLogTag = fGetLogTag("fMain")

	gLog.LogLine tLogTag, False, "Argument count - " & WScript.Arguments.Length

	fReadCommandListFile gScriptPath, cmdFileName, tCommandList
	fResolveCommandListToContext tCommandList, tCommandListContext, tCommandListCount
	If tCommandListCount = -1 Then
		gLog.LogLine tLogTag, False, "Nothing was resolved. CommandList empty!"
		Exit Sub
	End If

	'WScript.Echo tCommandListCount
	'WScript.Echo 0 & "::" & tCommandListContext(0).GetContextAsText()
	'WScript.Echo 1 & "::" & tCommandListContext(1).GetContextAsText()

	'tCommand = "ADDFILL:80020:5600010901:564130032113101:01:03:1:AUTO:-2133"
	'gLog.LogLine tLogTag, False, "Commands: " & tCommandList

	If WScript.Arguments.Length = 0 Then: Exit Sub

	tIndex = 0
	For Each tFilePath in WScript.Arguments
		
		tIndex = tIndex + 1
		gLog.LogLine tLogTag, False, "###########################################" 'just log separator
		gLog.LogLine tLogTag, False, "Argument #" & tIndex & ": " & WScript.Arguments.Length

		'processing argument value
		If gFSO.FileExists(tFilePath) Then
			Set tFile = gFSO.GetFile(tFilePath)
			fXML80020Injection tFile, tCommandListContext
		Else
			gLog.LogLine tLogTag, False, "File not exists!"
		End If
	Next
End Sub

' fReadCommandListFile - read commands from file stream type
Private Sub fReadCommandListFile(inFolder, inFileName, outCommandListString)
	Dim tTextFile, tLogTag, tFilePath, tCommandLine

	tLogTag = fGetLogTag("fReadCommandListFile")
	outCommandListString = vbNullString
	
	' FOLDER
	If Not gFSO.FolderExists(inFolder) Then
		gLog.LogLine tLogTag, True, "Folder not exists! inFolder=[" & inFolder & "]"
		Exit Sub
	End If

	tFilePath = inFolder
	If Right(tFilePath, 1) <> "\" Then: tFilePath = tFilePath & "\"

	' FILE COMMANDLIST
	tFilePath = tFilePath & inFileName

	If Not gFSO.FileExists(tFilePath) Then
		gLog.LogLine tLogTag, True, "CommandList file not exists! tFilePath=[" & tFilePath & "]"
		Exit Sub
	End If

	' READ COMMANDS
	On Error Resume Next

		'OPENING
		Set tTextFile = gFSO.OpenTextFile(tFilePath)

		If Err.Number <> 0 Then
			gLog.LogLine tLogTag, True, "Reading file error (details in log file)! tFilePath=[" & tFilePath & "]"
			gLog.LogLine tLogTag, False, fGetErrTextView(Err)
			Set tTextFile = Nothing
			On Error Goto 0
			Exit Sub
		End If
		
		'READING
		Do Until tTextFile.AtEndOfStream
			tCommandLine = Trim(tTextFile.ReadLine)
			If tCommandLine <> vbNullString Then
				If outCommandListString = vbNullString Then
					outCommandListString = tCommandLine
				Else
					outCommandListString = outCommandListString & cmdSeparator & tCommandLine
				End If
			End If

			If Err.Number <> 0 Then
				gLog.LogLine tLogTag, True, "Reading file error (details in log file)! tFilePath=[" & tFilePath & "]"
				gLog.LogLine tLogTag, False, fGetErrTextView(Err)
				tTextFile.Close
				Set tTextFile = Nothing
				On Error Goto 0
				Exit Sub
			End If
		Loop		

		tTextFile.Close
		Set tTextFile = Nothing
	On Error Goto 0
End Sub

' fResolveCommandListToContext - main reprocessor text commands to context
Private Sub fResolveCommandListToContext(inCommandList, outCommandListContext, outCommandListCount)
	Dim tLogTag
	Dim tTempContext, tCommandList, tCommand

	tLogTag = "fResolveCommandListToContext"

	outCommandListCount = -1
	ReDim outCommandListContext(outCommandListCount)

	tCommandList = Split(UCase(inCommandList), cmdSeparator)	
	
	For Each tCommand In tCommandList		
		
		'add temporary
		outCommandListCount = outCommandListCount + 1
		ReDim Preserve outCommandListContext(outCommandListCount)
		Set outCommandListContext(outCommandListCount) = New CContext

		outCommandListContext(outCommandListCount).SetParam "commandLine", tCommand
		If fResolveCommand(outCommandListContext(outCommandListCount)) Then
			
			'Set outCommandListContext(outCommandListCount) = tTempContext 'copy temp context to command context list
			gLog.LogLine tLogTag, False, "[#" & outCommandListCount + 1 & "] Command accepted: " & tCommand

		Else
			gLog.LogLine tLogTag, False, "[#" & outCommandListCount + 1 & "] Command denied: " & tCommand
			
			'remove
			outCommandListCount = outCommandListCount - 1
			ReDim Preserve outCommandListContext(outCommandListCount)
		End If

		'Set tTempContext = Nothing
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
		Case "2021-12-1": outHours = "111111100000110000000111"
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
'Private Function fAddFillCommandResolve(inCommandElements, outOperation, outToClass, outAreaCode, outMPointCode, outMainChannelCode, outLinkedChannelCode, outZoneIndex, outAffectHourArray, inDate, outValue, outErrorText, outWarning)
Private Function fAddFillCommandResolve(inContext)
	Dim tElementsCount, tHourString, tHalfHourString, tOperationName, tElementIndex
	Dim tCommandElements, tWarningText, tHalfHourAffectArray
	Dim tClass, tMPCode, tMainChannelCode, tLinkedChannelCode, tZoneIndex, tAreaCode, tAffectValue

	fAddFillCommandResolve = False
	inContext.SetParam "warningText", vbNullString
	inContext.SetParam "errorText", vbNullString
	tOperationName = cmd_ADDFILL
	tElementsCount = 9
	tElementIndex = 0
	inContext.GetParam "commandElements", tCommandElements

	If UBound(tCommandElements) <> tElementsCount - 1 Then
		inContext.SetParam "errorText", "Command check failed by common element counting for operation [" & tOperationName & "][Found=" & UBound(tCommandElements)+1 & " // Need=" & tElementsCount & "]"
		Exit Function
	End If

	'01 // CLASS FILTER :: 80020 or 80040 (or empty)
	tElementIndex = tElementIndex + 1
	tClass = tCommandElements(tElementIndex)
	If Not (tClass = "80020" or tClass = "80040") Then
		tClass = vbNullString 'autofix on missread
		inContext.SetParam "warningText", "Class filter has wrong value [" & tClass & "] and will be setted to default."
	End If
	inContext.SetParam "class", tClass

	'02 // AREA FILTER :: Using AREA code (no check - soft apply)
	tElementIndex = tElementIndex + 1
	tAreaCode = tCommandElements(tElementIndex)
	inContext.SetParam "area", tAreaCode

	'03 // MEASURING POINT (MP) FILTER :: cannot be empty
	tElementIndex = tElementIndex + 1
	tMPCode = tCommandElements(tElementIndex)
	If tMPCode = vbNullString Then
		inContext.SetParam "errorText", "Error in resolve [" & tOperationName & "]: MPointCode cannot be empty!"
		Exit Function
	End If
	inContext.SetParam "mpcode", tMPCode

	'04 // MP CHANNEL FILTER :: cannot be empty
	tElementIndex = tElementIndex + 1
	tMainChannelCode = tCommandElements(tElementIndex)
	fChannelCodeAutoFix tMainChannelCode 'autofix values to format DD
	If tMainChannelCode = vbNullString Then
		inContext.SetParam "errorText", "Error in resolve [" & tOperationName & "]: MainChannelCode cannot be empty!"
		Exit Function
	End If
	inContext.SetParam "mainChannelCode", tMainChannelCode

	'05 // MP CHANNEL linked FILTER :: it'll adjust this linked channel by rules of command
	tElementIndex = tElementIndex + 1
	tLinkedChannelCode = tCommandElements(tElementIndex)
	fChannelCodeAutoFix tLinkedChannelCode
	inContext.SetParam "linkedChannelCode", tLinkedChannelCode

	'06 // TRADE ZONE FILTER :: using trade zone index to apply some calculations by it
	tElementIndex = tElementIndex + 1
	tZoneIndex = tCommandElements(tElementIndex)
	If Len(tZoneIndex) <> 1 Then
		inContext.SetParam "errorText", "Error in resolve [" & tOperationName & "]: ZoneIndex cannot be empty!"
		Exit Function
	ElseIf Not IsNumeric(tZoneIndex) Then
		inContext.SetParam "errorText", "Error in resolve [" & tOperationName & "]: ZoneIndex not numeric value!"
		Exit Function
	Else
		tZoneIndex = Fix(tZoneIndex)
		If tZoneIndex < 1 Or tZoneIndex > 9 Then
			inContext.SetParam "errorText", "Error in resolve [" & tOperationName & "]: ZoneIndex not in [1..9]!"
			Exit Function
		End If
	End If
	inContext.SetParam "zoneIndex", tZoneIndex

	'07 // APPLY SEQ FILTER :: used to set hours(halfhours) which are used to apply command
	tElementIndex = tElementIndex + 1
	tHalfHourString = tCommandElements(tElementIndex)
	' If tHalfHourString = "AUTO" Then 'auto mode will try to get hours which are not in SOPeaks range
	' 	If Not fGetSOHours(Year(inDate), Month(inDate), outZoneIndex, tHourString) Then
	' 		inContext.SetParam "warningText", "fGetSOHours failed. Default string: " & tHourString
	' 	Else
	'		inContext.SetParam "warningText", "AUTO hours set: " & tHalfHourString
	'	End If
	'	tHalfHourString = tHourString		
	'End If

	'will convert STRING of hours(halfhours) to INT array (and will fix issues if occured)
	'fHourStringConvertToIntArray tHalfHourString, tHalfHourAffectArray, 48, tWarningText
	'inContext.SetParam "warningText", tWarningText
	'inContext.SetParam "affectString48", tHalfHourString
	'inContext.SetParam "affectArray48", tHalfHourAffectArray
	inContext.SetParam "affectString", tHalfHourString

	'08 // VALUE :: set value to apply by command
	tElementIndex = tElementIndex + 1
	tAffectValue = tCommandElements(tElementIndex)
	If Not IsNumeric(tAffectValue) Then
		inContext.SetParam "errorText", "Error in resolve [" & tOperationName & "]: Value not is numeric!"
		Exit Function
	End If
	inContext.SetParam "injectValue", tAffectValue

	fAddFillCommandResolve = True
End Function

'Private Function fResolveCommand(inCommand, outOperation, outToClass, outAreaCode, outMPointCode, outMainChannelCode, outLinkedChannelCode, outZoneIndex, outAffectHourArray, inDate, outValue)
Private Function fResolveCommand(inContext)
	Dim tLogTag, tOperationName, tCommandLine
	Dim tCommandElements, tErrorText, tWarningText

	tLogTag = "fResolveCommand"
	fResolveCommand = False

	'check 1
	inContext.GetParam "commandLine", tCommandLine
	tCommandElements = Split(tCommandLine, cmdInternalSeparator)
	If UBound(tCommandElements) < 1 Then
		gLog.LogLine tLogTag, False, "Command check failed by common element counting"
		Exit Function
	End If

	tOperationName = tCommandElements(0)
	inContext.SetParam "operation", tOperationName
	inContext.SetParam "commandElements", tCommandElements

	Select Case tOperationName
		Case cmd_ADDFILL: 
			gLog.LogLine tLogTag, False, "Operation [" & tOperationName & "] by command: [" & tCommandLine & "]"
			'If Not fAddFillCommandResolve(tCommandElements, tOperationName, outToClass, outAreaCode, outMPointCode, outMainChannelCode, outLinkedChannelCode, outZoneIndex, outAffectHourArray, inDate, outValue, tErrorText, tWarningText) Then
			If Not fAddFillCommandResolve(inContext) Then
				inContext.GetParam "warningText", tWarningText
				inContext.GetParam "errorText", tErrorText
				fWarningLog tLogTag, tWarningText
				gLog.LogLine tLogTag, False, "Operation [" & tOperationName & "] resolve error: " & tErrorText
				Exit Function
			End If
			inContext.GetParam "warningText", tWarningText
			fWarningLog tLogTag, tWarningText
		Case Else:
			gLog.LogLine tLogTag, False, "Operation [" & tOperationName & "] unknown!"
			Exit Function
	End Select

	inContext.DeleteParam "commandElements"
	inContext.SetParam "warningText", vbNullString
	inContext.SetParam "errorText", vbNullString
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
Private Sub fXML80020Injection(inFile, inCommandListContext)
	Dim tLogTag, tCommandIndex
	Dim tXML80020, tVersion, tClass, tDate, tCommandList, tCommand, tRollBackNeeded, tCommandContext

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
	tCommandIndex = 0
	For Each tCommandContext In inCommandListContext
		tCommandIndex = tCommandIndex + 1
		gLog.LogLine tLogTag, False, "-------------------------------------------"
		gLog.LogLine tLogTag, False, "Command #" & tCommandIndex & " executing..."
		If Not fExecuteCommand(tCommandContext, inFile, tXML80020, tClass, tVersion, tDate, tRollBackNeeded) Then
			gLog.LogLine tLogTag, False, "Injection failed: COMMAND = [" & tCommand & "]"
		Else
			gLog.LogLine tLogTag, False, "Injection done!"
			fSaveXMLChanges inFile.Path, tXML80020, True
		End If
		gLog.LogLine tLogTag, False, "Command #" & tCommandIndex & " finished."
	Next
	
End Sub

' fGenerateHalfHourArray - mask generator
Private Sub fGenerateHalfHourArray(inContext)
	Dim tDate, tAffectString, tZoneIndex, tAffectHourString, tHalfHourAffectArray, tWarningText
	Dim tLogTag 

	tLogTag = "fGenerateHalfHourArray"
	inContext.GetParam "affectString", tAffectString
	inContext.GetParam "date", tDate
	inContext.GetParam "zoneIndex", tZoneIndex

	'auto mode will try to get hours which are not in SOPeaks range
	fWarningLog tLogTag, "Settings: tAffectString=[" & tAffectString & "] tDate=[" & tDate & "]" 
	If tAffectString = "AUTO" Then
	 	If Not fGetSOHours(Year(tDate), Month(tDate), tZoneIndex, tAffectHourString) Then
			fWarningLog tLogTag, "fGetSOHours failed. Default string: " & tAffectHourString
		Else
			fWarningLog tLogTag, "AUTO hours set (by SOPeaks): " & tAffectHourString
		End If
		tAffectString = tAffectHourString		
	End If

	'will convert STRING of hours(halfhours) to INT array (and will fix issues if occured)
	fHourStringConvertToIntArray tAffectString, tHalfHourAffectArray, 48, tWarningText
	fWarningLog tLogTag, tWarningText
	inContext.SetParam "affectMaskString", tAffectString
	inContext.SetParam "affectMaskArray48", tHalfHourAffectArray
	'inContext.DeleteParam "affectString"
End Sub

' fAddFillCommandApply - main ADDFILL modifier
'Private Function fAddFillCommandApply(inHalfHourArray, inValue, outErrorText, outInfoLine, inLogDetails)
Private Function fAddFillCommandApply(inContext, inLogDetails)
	Dim tUBoundIndex, tIndex, tCounter, tAverageValue, tAccumulateValue, tCheckValue, tIsNegative, tSuffixValue
	Dim tShowList, tInfoText, tHalfHourArray, tValue

	fAddFillCommandApply = False
	inContext.SetParam "errorText", vbNullString
	inContext.SetParam "warningText", vbNullString
	inContext.SetParam "infoText", vbNullString	
	tInfoText = "Injection: "

	fGenerateHalfHourArray inContext
	inContext.GetParam "affectMaskArray48", tHalfHourArray

	If Not IsArray(tHalfHourArray) Then
		inContext.SetParam "errorText", "affectMaskArray48 is not ARRAY! Mask generation failed!"
		Exit Function
	End If

	tUBoundIndex = UBound(tHalfHourArray)

	' get values to apply count
	tCounter = 0
	For tIndex = 0 To tUBoundIndex
		tCounter = tCounter + tHalfHourArray(tIndex)
	Next

	If tCounter = 0 Then
		inContext.SetParam "errorText", "Array of apply is EMPTY! [tCounter=0]"
		Exit Function
	End If

	inContext.GetParam "injectValue", tValue

	tIsNegative = (tValue < 0)
	tAccumulateValue = Abs(tValue)
	tAverageValue = tAccumulateValue / tCounter
	tSuffixValue = 0
	tCheckValue = 0

	For tIndex = 0 To tUBoundIndex
		If tHalfHourArray(tIndex) = 1 Then
			tHalfHourArray(tIndex) = Round(tAverageValue + tSuffixValue, 0)
			tSuffixValue = tSuffixValue + tAverageValue - tHalfHourArray(tIndex)
			'debug comment
			If inLogDetails Then: gLog.LogLine "CALC", False, "tIndex=" & tIndex & " > VAL=" & tHalfHourArray(tIndex) & " SUFF=" & tSuffixValue & " AVG=" & tAverageValue
			If tIsNegative Then: tHalfHourArray(tIndex) = -tHalfHourArray(tIndex)
		End If
		tInfoText = tInfoText & " " & tHalfHourArray(tIndex)
		tCheckValue = tCheckValue + tHalfHourArray(tIndex)
	Next

	tCheckValue = Round(tCheckValue, 0)

	tInfoText = tInfoText & " // SUM=" & tCheckValue & " (DIFF=" & tCheckValue - tValue & ")"
	inContext.SetParam "infoText", tInfoText

	If tCheckValue - tValue <> 0 Then
		inContext.SetParam "errorText", "Math error. SUM check failed!"
		Exit Function
	End If

	inContext.SetParam "injectArray48", tHalfHourArray
	fAddFillCommandApply = True
End Function

' fPrepareInjectValues - prepare inject values by operations select
Private Function fPrepareInjectValues(inContext)
	Dim tLogTag, tErrorText, tInfoText
	Dim tOpertaion

	tLogTag = "fPrepareInjectValues"
	fPrepareInjectValues = False	
	inContext.GetParam "operation", tOpertaion

	Select Case tOpertaion
		Case cmd_ADDFILL: 
			If Not fAddFillCommandApply(inContext, False) Then
				inContext.GetParam "errorText", tErrorText
				inContext.GetParam "infoText", tInfoText
				fWarningLog tLogTag, tInfoText
				gLog.LogLine tLogTag, False, "Operation [" & tOpertaion & "]: " & tErrorText
				Exit Function
			End If
			inContext.GetParam "infoText", tInfoText
			fWarningLog tLogTag, tInfoText
		Case Else:
			gLog.LogLine tLogTag, False, "Operation [" & tOpertaion & "] unknown!"
	End Select

	inContext.DeleteParam "infoText"
	inContext.SetParam "errorText", vbNullString
	inContext.SetParam "warningText", vbNullString
	fPrepareInjectValues = True
End Function

' fGetWorkNodes - node extractor
Private Function fGetWorkNodes(inXML, outMainNode, outLinkedNode, inContext)
	Dim tLogTag, tXPathReqBase, tXPathReq, tTypeName
	Dim tAreaCode, tMPointCode, tMainChannelCode, tLinkedChannelCode

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

	inContext.GetParam "area", tAreaCode
	inContext.GetParam "mpcode", tMPointCode
	inContext.GetParam "mainChannelCode", tMainChannelCode
	inContext.GetParam "linkedChannelCode", tLinkedChannelCode

	'AREA
	tXPathReqBase = "//area"
	If tAreaCode <> vbNullString Then: tXPathReqBase = tXPathReqBase & "[inn='" & tAreaCode & "']"

	'MPoint
	tXPathReqBase = tXPathReqBase & "/measuringpoint[@code='" & tMPointCode & "']"

	'MainLock /measuringchannel[@code='" & tMainChannelCode & "']"
	tXPathReq = tXPathReqBase & "/measuringchannel[@code='" & tMainChannelCode & "']"
	Set outMainNode = inXML.SelectSingleNode(tXPathReq)
	If outMainNode is Nothing Then
		gLog.LogLine tLogTag, False, "Failed to lock main channel node: <" & tXPathReq & ">"
		Exit Function
	Else
		gLog.LogLine tLogTag, False, "Locked main channel node: <" & tXPathReq & ">"
	End If

	If tLinkedChannelCode <> vbNullString Then
		tXPathReq = tXPathReqBase & "/measuringchannel[@code='" & tLinkedChannelCode & "']"
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
				gLog.LogLine tLogTag, False, "Failed to APPLY ADJUST INJECTION!"
				Exit Function
			End If

			tMainInjectionSum = tMainInjectionSum + tNewMainValue - tOldMainValue

			If tHasLink Then
				tLinkedValueModifier = tAdjustMainValue / tOldMainValue

				If Not fApplyInjectionToValue(ioLinkedNode, tXPathReq, tLinkedValueModifier, 1, tOldLinkedValue, tNewLinkedValue, tWasChanged, "LINKED", inLogDetails) Then
					gLog.LogLine tLogTag, False, "Failed to APPLY ADJUST INJECTION!"
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
Private Function fExecuteCommand(inCommandContext, inFile, inXML, inClass, inVersion, inDate, outRollBackChanges)
	Dim tOperation, tClass, tAffectHourArray
	Dim tMainNode, tLinkedNode
	Dim tLogTag

	tLogTag = "fExecuteCommand"
	fExecuteCommand = False
	outRollBackChanges = False

	' 01 \\
	'If Not fResolveCommand(inCommand, tOperation, tClass, tAreaCode, tMPointCode, tMainChannelCode, tLinkedChannelCode, tZoneIndex, tAffectHourArray, inDate, tValue) Then
	'	gLog.LogLine tLogTag, False, "Injection aborted: Command syntax ERROR = " & inCommand
	'	Exit Function
	'End If
	inCommandContext.GetParam "operation", tOperation
	inCommandContext.GetParam "class", tClass
	inCommandContext.SetParam "date", inDate

	' 02 \\
	If tClass <> vbNullString Then
		If tClass <> inClass Then
			gLog.LogLine tLogTag, False, "Command class not equal to Command class! [CommandClass=" & tClass & " // FileClass=" & inClass & "]"
			Exit Function
		End If
	End If

	' 03 \\ Prepare inject values
	If Not fPrepareInjectValues(inCommandContext) Then
		gLog.LogLine tLogTag, False, "Operation [" & tOperation & "] data preapare failed!"
		Exit Function
	End If

	' 04 \\ Select work node
	If Not fGetWorkNodes(inXML, tMainNode, tLinkedNode, inCommandContext) Then
		gLog.LogLine tLogTag, False, "Work node not locked!"
		Exit Function
	End If

	inCommandContext.GetParam "injectArray48", tAffectHourArray
	If Not fApplyInjectionToWorkNode(tMainNode, tLinkedNode, tAffectHourArray, outRollBackChanges, False) Then
		gLog.LogLine tLogTag, False, "Injection failed! [RollBackChanges=" & outRollBackChanges & "]"
		Exit Function
	End If

	fExecuteCommand = True
End Function

fInit
fMain
fQuit
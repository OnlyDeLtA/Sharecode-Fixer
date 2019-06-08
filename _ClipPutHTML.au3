#include-once
#include <Clipboard.au3>
#include <Memory.au3>		; (for _Mem..() funcs) [actually included in <ClipBoard.au3>, but here for clarity]
; ===============================================================================================================================
; <_ClipPutHTML.au3>
;
; Function to put HTML formatted text, or simple Hyperlinks into the Clipboard.
;
; Functions:
;	_ClipPutHTML()			; Simple function to paste HTML code (in UTF-8 format) into the clipboard,
;							;	along with a Plain-Text version
;	_ClipPutHyperlink()		; Sends an HTML-style Hyperlink to the ClipBoard
;	_ClipBoard_FormatHTML()	; Helper function used to apply a CF_HTML header to a piece of HTML code
;							;	*REQUIRED part of calling _ClipBoard_SendHTML
;	_ClipBoard_SendHTML()	; Basically a modified version of _ClipBoard_SetData() for sending HTML + PlainText
;							;	variants to the Clipboard
;
; Dependencies: <Clipboard.au3>
;
; See also:
;	<_ClipGetHTML.au3>
;	<TestClipPutHTML.au3>
;	<_ClipPutHTML_w_History.au3>
;	<_ClipGetRTF.au3>
;	<TestHTMLClipBoardMonitor.au3>	; Monitors & Reports on HTML-formatted ClipBoard data
;	<TestRTFClipBoardMonitor.au3>
;	<_RTF_PullHyperlinks.au3>
;	<TestClipBoardHyperlinkReSorter.au3>; On a HotKey, will pull Hyperlinks from HTML-formatted Clipboard data, sort
;										; 	and resubmit them to the Clipboard (in isolated, sorted format)
;
; Resources:
;	CF_HTML (# 49342) Format @ MSDN: http://msdn.microsoft.com/en-us/library/ms649015(VS.85).aspx
;	Clipboard Formats @ MSDN: http://msdn.microsoft.com/en-us/library/ms649013(VS.85).aspx
;
; Additional Notes:
;	One way to convert Unicode strings to UTF-8 format:
;		$sUTF8String=BinaryToString(StringToBinary($sUnicodeString,4),1)
;
; Author: Ascend4nt, Original _ClipBoard_SetData() function: Paul Campbell (PaulIA)
; ===============================================================================================================================

; ===============================================================================================================================
; Func _ClipPutHTML($sHTML,$sPlainText)
;
; Simple method of placing HTML data, and PlainText equivalent (if available), on the clipboard.
;
; $sHTML = HTML code in UTF-8 format.
;	NOTE: this will paste the *entire* piece of HTML code in the Clipboard.
;		For finer control, see _ClipBoard_FormatHTML() and _ClipBoard_SendHTML()
;		(_ClipPutHyperlink() also uses this customized method of pasting HTML data)
;	One way to convert Unicode strings to UTF-8 format:
;		$sUTF8String=BinaryToString(StringToBinary($sUnicodeString,4),1)
; $sPlainText = (optional, but recommended) The text as it would appear in a non-rich-text based edit control
;	(for example, Notepad). If left blank, pasting will not work in those controls.
;
; Returns:
;	Success: a handle to the HTML Global memory object, with @extended = handle to PlainText memory object
;		NOTE: if @error = -8, the function *partially* succeeded,
;			and the HTML Global memory object is returned. (The setting of the PlainText variant failed)
;	Failure: 0 returned with @error set:
;		@error = 1 = invalid parameter(s)
;		@error = -1 = error allocating global memory object, @extended = 1 if occurred on PlainText object
;		@error = -2 = error locking global memory object, @extended = 1 if occurred on PlainText object
;		@error = -5 = error opening clipboard
;		@error = -6 = error emptying clipboard
;		@error = -7 = error setting clipboard with HTML data
;		@error = -8 = error setting clipboard with PlainText data
;		@error = -9 = error registering HTML Data Clipboard format (no attempt to set Clipboard data is made);
;
; Author: Ascend4nt
; ===============================================================================================================================

Func _ClipPutHTML($sHTMLStr,$sPlainText="")
	Local $sCF_HTMLStr=_ClipBoard_FormatHTML($sHTMLStr)
	If @error Then Return SetError(@error,0,0)
	Local $vRet=_ClipBoard_SendHTML($sCF_HTMLStr,$sPlainText)
	SetError(@error,@extended)
	Return $vRet
EndFunc

; ===============================================================================================================================
; Func _ClipPutHyperlink($sURL,$sLabel="",$sSourceURL="")
;
; Puts a simple Hyperlink into the clipboard, in HTML format.
;
; $sURL = the URL web address (ANSI)
; $sLabel = the Label to put on the Hyperlink. If left as "", it will use the $sURL string
; $sSourceURL = the URL web address that contained the link (useful in downloads?)
;
; Returns:
;	Success: a handle to the HTML Global memory object, with @extended = handle to PlainText memory object
;		NOTE: if @error = -8, the function *partially* succeeded,
;			and the HTML Global memory object is returned. (The setting of the PlainText variant failed)
;	Failure: 0 returned with @error set:
;		@error = 1 = invalid parameter(s)
;		@error = -1 = error allocating global memory object, @extended = 1 if occurred on PlainText object
;		@error = -2 = error locking global memory object, @extended = 1 if occurred on PlainText object
;		@error = -5 = error opening clipboard
;		@error = -6 = error emptying clipboard
;		@error = -7 = error setting clipboard with HTML data
;		@error = -8 = error setting clipboard with PlainText data
;		@error = -9 = error registering HTML Data Clipboard format (no attempt to set Clipboard data is made);
;
; Author: Ascend4nt
; ===============================================================================================================================

Func _ClipPutHyperlink($sURL,$sLabel="",$sSourceURL="")

	; Test parameters. (Label can be converted to a string if something else)
	If Not IsString($sURL) Or Not IsString($sSourceURL) Then Return SetError(1,0,0)

	; Convert Label to a string if it wasn't already (allows passing #'s etc)
	If Not IsString($sLabel) Then $sLabel=String($sLabel)

	; If no Label is specified, use the URL name as the label
	If $sLabel="" Then $sLabel=$sURL

	; 'Sneaky' method of converting regular little-endian 16-bit Unicode to UTF-8 Unicode
	;	(first convert it to UTF-8 *BINARY*, then convert it to a string (pretending its regular ANSI data))
	Local $sUTF8Label=BinaryToString(StringToBinary($sLabel,4),1)

	Local $sHTMLStr="<html><body>" & @CRLF & _
		'<a href="' & $sURL & '">' & $sUTF8Label & '</a>' & @CRLF & _
		"</body>" & @CRLF & "</html>"

	$sHTMLClipStr=_ClipBoard_FormatHTML($sHTMLStr,15,15+StringLen($sURL)+15+StringLen($sUTF8Label)-1,1,-1,$sSourceURL)

	Local $vRet=_ClipBoard_SendHTML($sHTMLClipStr,$sLabel)
	SetError(@error,@extended)
	Return $vRet
EndFunc


; ===============================================================================================================================
; Func _ClipBoard_FormatHTML($sHTMLStr,$iFragmentStart=1,$iFragmentEnd=-1,$iHTMLStart=1,$iHTMLEnd=-1,$sSourceURL="")
;
; Function to apply a CF_HTML header to an HTML string & return the combined string result
;	For use in calling _ClipBoard_SendHTML()
;
; $sHTMLStr = HTML string. (UTF-8 encoding please)
; $iFragmentStart = (optional, defaults to 1): Location in HTML string where the actual data to copy STARTS
; $iFragmentEnd = (optional, defaults to -1): Location in HTML string where the actual data to copy ENDS
;		(if you only know the length, use the formula $iFragmentStart+$iFragmentLen-1 )
;		-1 means end of HTML string
; $iHTMLStart = (optional, defaults to 1): Location where the HTML code starts (typically at top, or at "<html>")
; $iHTMLEnd = (optional, defaults to -1): Location where the HTML code ends (typically at the end, or at right of "</html>")
;		-1 means end of HTML string
; $sSourceURL = (optional): If present, will add a "SourceURL:" line to CF_HTML header. Possibly useful for 'referrer' info
;
; Returns:
;	Success: CF_HTML-Formatted string
;	Failure: "" with @error set to 1 (invalid parameter(s))
;
; Author: Ascend4nt
; ===============================================================================================================================

Func _ClipBoard_FormatHTML($sHTMLStr,$iFragmentStart=1,$iFragmentEnd=-1,$iHTMLStart=1,$iHTMLEnd=-1,$sSourceURL="")

	; Paramater checks
	If Not IsString($sHTMLStr) Then Return SetError(1,0,"")

	Local $iHTMLLen=StringLen($sHTMLStr)

	; Handle defaults
	If $iHTMLEnd=-1 Then $iHTMLEnd=$iHTMLLen
	If $iFragmentEnd=-1 Then $iFragmentEnd=$iHTMLLen

	; Bounds checking
	If $iHTMLStart<1 Or $iHTMLStart>$iHTMLEnd Or $iHTMLEnd>$iHTMLLen Then Return SetError(1,0,"")
	If $iFragmentStart<$iHTMLStart Or $iFragmentStart>$iFragmentEnd Or $iFragmentEnd>$iHTMLEnd Then Return SetError(1,0,"")

	; Size of standard header = 97 (padded offsets):
	;	Version:0.9 & @CRLF
	;	StartHTML:00000000 & @CRLF
	;	EndHTML:00000000 & @CRLF
	;	StartFragment:00000000 & @CRLF
	;	EndFragment:00000000 & @CRLF
	Local $iCF_HTMLLen=97

	; Source URL passed?
	If $sSourceURL<>"" Then
		; Add length of "SourceURL:" + $sSourceURL + 2 (@CRLF) to header size
		$iCF_HTMLLen+=12+StringLen($sSourceURL)
		$sSourceURL="SourceURL:"&$sSourceURL&@CRLF
	EndIf

	; Return Final String
	Return ("Version:0.9" & @CRLF & _
		"StartHTML:"& StringRight("0000000"&($iHTMLStart+$iCF_HTMLLen-1),8) & @CRLF & _
		"EndHTML:"& StringRight("0000000"&($iHTMLEnd+$iCF_HTMLLen),8) & @CRLF & _
		"StartFragment:"& StringRight("0000000"&($iFragmentStart+$iCF_HTMLLen-1),8) & @CRLF & _
		"EndFragment:"& StringRight("0000000"&($iFragmentEnd+$iCF_HTMLLen),8) & @CRLF & _
		$sSourceURL & $sHTMLStr)
EndFunc


; ===============================================================================================================================
; Func _ClipBoard_SendHTML(Const ByRef $sHTMLData,Const ByRef $sPlainText)
;
; Basically a modified version of _ClipBoard_SetData() for sending HTML + PlainText variants to the Clipboard
;	NOTE: CF_HTML format is in UTF-8 encoding. For typical ANSI text, nothing needs to be done,
;		but for Unicode characters, do a conversion like such:
;			$sUTF8String=BinaryToString(StringToBinary($sUnicodeString,4),1)
;	$sPlainText is handled by default as Unicode text
;
; $sHTMLData = the HTML data string WITH the CF_HTML header applied! (UTF-8 encoding!)
;	** Use _ClipBoard_FormatHTML() to apply the header to the string before calling this!!
; $sPlainText = the (Unicode) plain text variant of the HTML data (no rich-text/HTML formatting, just the text)
;
; Returns:
;	Success: a handle to the HTML Global memory object, with @extended = handle to PlainText memory object
;		NOTE: if @error = -8, the function *partially* succeeded,
;			and the HTML Global memory object is returned. (The setting of the PlainText variant failed)
;	Failure: 0 returned with @error set:
;		@error = -1 = error allocating global memory object, @extended = 1 if occurred on PlainText object
;		@error = -2 = error locking global memory object, @extended = 1 if occurred on PlainText object
;		@error = -5 = error opening clipboard
;		@error = -6 = error emptying clipboard
;		@error = -7 = error setting clipboard with HTML data
;		@error = -8 = error setting clipboard with PlainText data
;		@error = -9 = error registering HTML Data Clipboard format (no attempt to set Clipboard data is made);
;
; Author: Original _ClipBoard_SetData() function: Paul Campbell (PaulIA),
;	HTML & Unicode modifications by Ascend4nt
; ===============================================================================================================================

Func  _ClipBoard_SendHTML(Const ByRef $sHTMLData, Const ByRef $sPlainText)
	Local $tData, $hLock, $hMemory, $hPTMemory, $iSize, $iCF_HTMLFormat, $iClipErr=0

	; Allocate *Global* system memory for the HTML data & initialize it
	$iSize = StringLen($sHTMLData) + 1
	$hMemory = _MemGlobalAlloc($iSize, $GHND)
	If $hMemory = 0 Then Return SetError(-1, 0, 0)
	$hLock = _MemGlobalLock($hMemory)
	If $hLock = 0 Then Return SetError(-2, 0, 0)
	$tData = DllStructCreate("char[" & $iSize & "]", $hLock)
	DllStructSetData($tData,1,$sHTMLData)
	_MemGlobalUnlock($hMemory)

	If $sPlainText<>"" Then
		; Allocate *Global* system memory for the PlainText variant of HTML data & initialize it
		$iSize = StringLen($sPlainText) + 1
		$hPTMemory = _MemGlobalAlloc($iSize*2, $GHND)	; *2 for Unicode character size
		If $hPTMemory = 0 Then Return SetError(-1, 1, 0)
		$hLock = _MemGlobalLock($hPTMemory)
		If $hLock = 0 Then Return SetError(-2, 1, 0)
		$tData = DllStructCreate("wchar[" & $iSize & "]", $hLock)	; wide (UNICODE) characters
		DllStructSetData($tData,1,$sPlainText)
		_MemGlobalUnlock($hPTMemory)
	Else
		$hPTMemory=0
	EndIf

	If Not _ClipBoard_Open(0) Then Return SetError(-5, 0, 0)
	If Not _ClipBoard_Empty() Then Return SetError(-6, 0, 0)

	;  CF_HTML in experimentation is generally 49342
	$iCF_HTMLFormat=_ClipBoard_RegisterFormat("HTML Format")

	If $iCF_HTMLFormat=0 Then
		$iClipErr=-9
	ElseIf Not _ClipBoard_SetDataEx($hMemory,$iCF_HTMLFormat) Then
		$iClipErr=-7
	ElseIf $sPlainText<>"" And Not _ClipBoard_SetDataEx($hPTMemory,13) Then	; $CF_UNICODETEXT = 13  ($CF_TEXT is 1)
		$iClipErr=-8
	EndIf

	_ClipBoard_Close()

	If $iClipErr Then
		; Total failure to place anything on the clipboard?
		If $iClipErr<>-8 Then Return SetError($iClipErr,0,0)
		; Since the HTML format was successfuly placed on the clipboard,
		;	we'll set the error, clear @extended, and allow return of the Global HTML memory handle
		SetError($iClipErr,0)
	Else
		; Put Global PlainText memory handle into @extended
		SetError(0,$hPTMemory)
	EndIf
	; Return Global HTML memory handle
	Return $hMemory
EndFunc


#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Nsane.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Comment=Sharecode Fixer - DeLtA
#AutoIt3Wrapper_Res_Description=Sharecode Fixer - DeLtA
#AutoIt3Wrapper_Res_Fileversion=1.3.0.0
#AutoIt3Wrapper_Res_LegalCopyright=DeLtA - NSANEFORUM
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <Clipboard.au3>
#include <TrayConstants.au3>
#include <Misc.au3>
#include <_ClipPutHTML.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <GUIHotkey.au3>
#include <Inet.au3>
#include <WinAPIDiag.au3>

Global $loop = 1
Global $ver_curr = 1.3

Global $dir=IniWrite(@ScriptDir & "\portable.ini", "SETTINGS", "portable", "1")

If $dir Then
	Global $config_dir = @ScriptDir

Else
	Global $config_dir = @LocalAppDataDir & "\Sharecode Fixer"
EndIf


If Not FileExists($config_dir & "\config.ini") Then
	iniwrity()
EndIf
iniready()

Func iniready()
	Global $sExit_HotKey = IniRead($config_dir & "\config.ini", "HOTKEYS", "exit", "+!x")
	Global $sReset_HotKey = IniRead($config_dir & "\config.ini", "HOTKEYS", "reset", "+!c")
	Global $trayicon = IniRead($config_dir & "\config.ini", "SETTINGS", "trayiconhide", "0")
	Global $sMode_HotKey = IniRead($config_dir & "\config.ini", "HOTKEYS", "switchmode", "!m")
	Global $sGen_HotKey = IniRead($config_dir & "\config.ini", "HOTKEYS", "gensharecode", "+g")
	Global $auto = IniRead($config_dir & "\config.ini", "SETTINGS", "auto", "0")
	Global $sharecoder = IniRead($config_dir & "\config.ini", "SETTINGS", "disablesharecoder", "0")
EndFunc   ;==>iniready

Func _ReduceMemory($i_PID = -1)

	If $i_PID <> -1 Then
		Local $ai_Handle = DllCall("kernel32.dll", 'int', 'OpenProcess', 'int', 0x1f0fff, 'int', False, 'int', $i_PID)
		Local $ai_Return = DllCall("psapi.dll", 'int', 'EmptyWorkingSet', 'long', $ai_Handle[0])
		DllCall('kernel32.dll', 'int', 'CloseHandle', 'int', $ai_Handle[0])
	Else
		Local $ai_Return = DllCall("psapi.dll", 'int', 'EmptyWorkingSet', 'long', -1)
	EndIf

	Return $ai_Return[0]
EndFunc   ;==>_ReduceMemory
_ReduceMemory()


Opt("TrayOnEventMode", 1)
Opt("TrayMenuMode", 3)

Local $idsetting = TrayCreateItem("Settings")
TrayItemSetOnEvent($idsetting, "CSetting")

Local $update = TrayCreateItem("Check Updates")
TrayItemSetOnEvent($update, "CheckUpdate")

Local $readme = TrayCreateItem("ReadME/Help")
TrayItemSetOnEvent($readme, "Readme")

Local $idAbout = TrayCreateItem("About")
TrayItemSetOnEvent($idAbout, "About")

Local $idExit = TrayCreateItem("Exit")
TrayItemSetOnEvent($idExit, "EXITButton")


Func EXITButton()
	Exit
EndFunc   ;==>EXITButton

Func About()
$habout_GUI = GUICreate("About/Credits", 313, 162, -1, -1, -1, BitOR($WS_EX_TOOLWINDOW,$WS_EX_WINDOWEDGE, $WS_EX_APPWINDOW))
GUICtrlCreateGroup("", 20, 10, 272, 132)
$Label1 = GUICtrlCreateLabel("Sharecode Fixer", 67, 24, 182, 33)
GUICtrlSetFont(-1, 18, 400, 4, "MS Sans Serif")
$Label2 = GUICtrlCreateLabel("Author: DeLtA/nsaneforums", 62, 64, 191, 20)
GUICtrlSetFont(-1, 10, 800, 0, "MS Sans Serif")
$Label3 = GUICtrlCreateLabel("Feedback/Testing: -=[4lfre1re]=-, GlacialMan, m345, ", 34, 96, 254, 17)
$Label4 = GUICtrlCreateLabel("teodz1984, Togijak, Wilenty.", 34, 112, 141, 17)
GUICtrlCreateGroup("", -99, -99, 1, 1)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			GUIDelete($habout_GUI)
				ExitLoop

	EndSwitch
WEnd

EndFunc   ;==>About

Opt("TrayIconHide", $trayicon)
TraySetToolTip("Sharecode Fixer By DeLtA")
Opt("TrayAutoPause", 0)
OnAutoItExitRegister("Onexit")
If _Singleton("Sharecode Fixer V1.2 - DeLtA", 1) = 0 Then
	MsgBox(48, "Warning", "An occurrence of Sharecode Fixer is already running")
	Exit
EndIf

Global $Pause = False
Global $Pause1 = False
Fixer()
Func Clear()
	ClipPut("")
	Opt("TrayIconHide", 0)
	TraySetToolTip("Sharecode Fixer By DeLtA")
	TrayTip("Sharecode Fixer - DeLtA", "All Fixed :)", 0, $TIP_ICONASTERISK)
	If $trayicon = 1 Then
		Sleep(2000)
		Opt("TrayIconHide", $trayicon)
	EndIf
EndFunc   ;==>Clear

Func Generate()

	$sText = ClipGet()
	Global $key1 = StringInStr($sText, "sharecode")
	Global $key2 = StringInStr($sText, "Sharecode")
	If $key1 = 0 And $key2 = 0 Then
		$sText = StringStripWS($sText, $STR_STRIPALL)
		$sText = StringReplace($sText, ChrW(0x200E), "")
		Global $check1 = StringInStr($sText, "//")
		If Not $check1 = 0 Then
			$iIndex = StringInStr($sText, "/", 0, 3)
		Else
			$iIndex = StringInStr($sText, "/", 0, 1)
		EndIf
		; Look for third /

		; Split string at that point
		$sSplit_1 = StringMid($sText, 1, $iIndex - 1)
		$sSplit_2 = StringMid($sText, $iIndex)
		$final = "Site : " & $sSplit_1 & @CRLF & "Sharecode : " & $sSplit_2 & @CRLF


		Local $sHTMLStr, $sPlainTextStr

		$sHTMLStr = '<html>' & _
				'  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">' & @CRLF & _
				"<p><strong>Site: </strong>" & @CRLF & _
				"<a href=" & $sSplit_1 & ">" & $sSplit_1 & "</a><br>" & @CRLF & _
				"<strong>Sharecode: </strong>" & @CRLF & _
				"" & $sSplit_2 & "</p>" & @CRLF & "</html>"

		$sPlainTextStr = "Site : " & $sSplit_1 & @CRLF & "Sharecode : " & $sSplit_2 & @CRLF
		$sHTMLStr = BinaryToString(StringToBinary($sHTMLStr, 4), 1)
		Sleep(200)
		_ClipPutHTML($sHTMLStr, $sPlainTextStr)
		Opt("TrayIconHide", 0)
		TraySetToolTip("Sharecode Generator By DeLtA")
		TrayTip("Sharecode Generator - DeLtA", "Link Sharecoded :)", 0, BitOR($TIP_ICONASTERISK, $TIP_NOSOUND))
		If $trayicon = 1 Then
			Sleep(2000)
			Opt("TrayIconHide", $trayicon)
		EndIf
	EndIf
EndFunc   ;==>Generate


Func Sharecode()
	$loop = 2
	$Pause1 = True
	HotKeySet($sGen_HotKey, "Generate")
	HotKeySet($sMode_HotKey, "switch1")
	Local $ram = 0
	While $Pause1
		$ram = $ram + 1
		If $ram = 40 Then
			_ReduceMemory()
			$ram = 0
		EndIf
		Sleep(500)
	WEnd
EndFunc   ;==>Sharecode

Func switch1()
	$Pause1 = False
	$Pause = False
	Opt("TrayIconHide", 0)
	TraySetToolTip("Sharecode Fixer By DeLtA")
	TrayTip("Sharecode Generator - DeLtA", "GENERATOR MODE IS OFF", 0, $TIP_ICONASTERISK)
	If $trayicon = 1 Then
		Sleep(2000)
		Opt("TrayIconHide", $trayicon)
	EndIf
	Fixer()
EndFunc   ;==>switch1
Func switch2()
	$Pause1 = False
	$Pause = False
	Opt("TrayIconHide", 0)
	TraySetToolTip("Sharecode Generator By DeLtA")
	TrayTip("Sharecode Generator - DeLtA", "GENERATOR MODE IS ON", 0, $TIP_ICONASTERISK)
	If $trayicon = 1 Then
		Sleep(2000)
		Opt("TrayIconHide", $trayicon)
	EndIf
	Sharecode()
EndFunc   ;==>switch2
Func Fixer()
	$loop = 1
	HotKeySet($sGen_HotKey)
	ClipPut("")
	$Pause = True
	Local $ram = 0
	While $Pause
		Global $open = 0
		HotKeySet($sExit_HotKey, "Terminate")
		HotKeySet($sReset_HotKey, "Clear")
		If $sharecoder = 0 Then
			HotKeySet($sMode_HotKey, "switch2")
		ElseIf $sharecoder = 1 Then
			HotKeySet($sMode_HotKey)
		EndIf
		$ram = $ram + 1
		If $ram = 40 Then
			_ReduceMemory()
			$ram = 0
		EndIf
		Sleep(500)
		Local $text = ClipGet()
		$text = StringReplace($text, ChrW(0x200E), "")
		$text = StringRegExpReplace($text, "\h+", "")
		Local $check1 = StringRegExp($text, "(?i)share\s*code(?-i)\s*(\[\?\])*\s*[:]*\s*", 0)
		Local $check2 = StringRegExp($text, "(?i)site(?-i)\s*[:]*\s*", 0)
		Local $check3 = StringRegExp($text, "\s*http(s)?://", 0)
		If ($check1 = 1 And $check2 = 1) Or ($check1 = 1 And $check3 = 1) Then
			$text = StringStripWS($text, $STR_STRIPALL)
			Local $test = String($text)
			$test = StringRegExpReplace($test, "\s*(?i)share\s*code(?-i)\s*(\[\?\])*\s*[:]*\s*|^\s*(?i)site(?-i)\s*[:]*\s*|﻿h﻿tt﻿ps://", "")
			$data = StringStripWS($test, $STR_STRIPALL)
			Sleep(100)
			ClipPut($data)
			If $auto = 1 Then
				$open = ShellExecute($data)
			EndIf
			If $open = 0 Then
				Opt("TrayIconHide", 0)
				TraySetToolTip("Sharecode Fixer By DeLtA")
				TrayTip("Sharecode Fixer - DeLtA", "Link Fixed :)", 0, BitOR($TIP_ICONASTERISK, $TIP_NOSOUND))
			EndIf
			If $trayicon = 1 Then
				Sleep(2000)
				Opt("TrayIconHide", $trayicon)
			EndIf

		EndIf
	WEnd
EndFunc   ;==>Fixer

Func CSetting()
	HotKeySet($sGen_HotKey)
	HotKeySet($sExit_HotKey)
	HotKeySet($sReset_HotKey)
	HotKeySet($sMode_HotKey)

	#Region ### START Koda GUI section ### Form=g:\sharecode_gui\hsettings_gui.kxf
	$hSettings_GUI = GUICreate("Settings", 401, 344, -1, -1, -1, BitOR($WS_EX_TOOLWINDOW, $WS_EX_WINDOWEDGE, $WS_EX_APPWINDOW))
	GUICtrlCreateGroup("General", 20, 10, 360, 132)
	$Checkbox1 = GUICtrlCreateCheckbox("Hide Tray Icon", 48, 48, 97, 17)
	If $trayicon = 1 Then
		GUICtrlSetState($Checkbox1, $GUI_CHECKED)
	EndIf
	$Checkbox2 = GUICtrlCreateCheckbox("Disable Sharecode Generator", 48, 72, 161, 17)
	If $sharecoder = 1 Then
		GUICtrlSetState($Checkbox2, $GUI_CHECKED)
	EndIf
	$Checkbox3 = GUICtrlCreateCheckbox("Enable Auto Mode ", 48, 96, 161, 17)
	If $auto = 1 Then
		GUICtrlSetState($Checkbox3, $GUI_CHECKED)
	EndIf
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	GUICtrlCreateGroup("Hotkeys", 20, 152, 360, 150)
	$Label1 = GUICtrlCreateLabel("Switch Mode Hotkey", 52, 192, 103, 17)
	$hMode_Hotkey = _GUICtrlHotkey_Create($hSettings_GUI, 212, 189, 137, 21)
	_GUICtrlHotkey_SetHotkey($hMode_Hotkey, $sMode_HotKey)
	_GUICtrlHotkey_SetRules($hMode_Hotkey, $HKCOMB_NONE, BitOR($HOTKEYF_CONTROL, $HOTKEYF_SHIFT))
	$Label2 = GUICtrlCreateLabel("Generate Sharecode Hotkey", 52, 216, 140, 17)
	$hGen_Hotkey = _GUICtrlHotkey_Create($hSettings_GUI, 212, 213, 137, 21)
	_GUICtrlHotkey_SetHotkey($hGen_Hotkey, $sGen_HotKey)
	_GUICtrlHotkey_SetRules($hGen_Hotkey, $HKCOMB_NONE, BitOR($HOTKEYF_CONTROL, $HOTKEYF_SHIFT))
	$Label3 = GUICtrlCreateLabel("Exit Program Hotkey", 52, 240, 100, 17)
	$hExit_Hotkey = _GUICtrlHotkey_Create($hSettings_GUI, 212, 237, 137, 21)
	_GUICtrlHotkey_SetHotkey($hExit_Hotkey, $sExit_HotKey)
	_GUICtrlHotkey_SetRules($hExit_Hotkey, $HKCOMB_NONE, BitOR($HOTKEYF_CONTROL, $HOTKEYF_SHIFT))
	$Label4 = GUICtrlCreateLabel("Reset Program Hotkey", 52, 264, 111, 17)
	$hReset_Hotkey = _GUICtrlHotkey_Create($hSettings_GUI, 212, 261, 137, 21)
	_GUICtrlHotkey_SetHotkey($hReset_Hotkey, $sReset_HotKey)
	_GUICtrlHotkey_SetRules($hReset_Hotkey, $HKCOMB_NONE, BitOR($HOTKEYF_CONTROL, $HOTKEYF_SHIFT))
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$iOK_Bttn = GUICtrlCreateButton("OK", 20, 312, 70, 20)
	$iCancel_Bttn = GUICtrlCreateButton("Cancel", 100, 312, 70, 20)
	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				Sleep(100)
				sethotkey()
				GUIDelete($hSettings_GUI)
				ExitLoop
			Case $iOK_Bttn
				$sMode_HotKey = StringLower(_GUICtrlHotkey_GetHotkey($hMode_Hotkey))
				$sGen_HotKey = StringLower(_GUICtrlHotkey_GetHotkey($hGen_Hotkey))
				$sExit_HotKey = StringLower(_GUICtrlHotkey_GetHotkey($hExit_Hotkey))
				$sReset_HotKey = StringLower(_GUICtrlHotkey_GetHotkey($hReset_Hotkey))

				IniWrite($config_dir & "\config.ini", "HOTKEYS", "exit", $sExit_HotKey)
				IniWrite($config_dir & "\config.ini", "HOTKEYS", "reset", $sReset_HotKey)
				IniWrite($config_dir & "\config.ini", "HOTKEYS", "switchmode", $sMode_HotKey)
				IniWrite($config_dir & "\config.ini", "HOTKEYS", "gensharecode", $sGen_HotKey)
				IniWrite($config_dir & "\config.ini", "SETTINGS", "trayiconhide", $trayicon)
				IniWrite($config_dir & "\config.ini", "SETTINGS", "auto", $auto)
				IniWrite($config_dir & "\config.ini", "SETTINGS", "disablesharecoder", $sharecoder)
				iniready()
				sethotkey()
				Opt("TrayIconHide", $trayicon)
				Sleep(100)
				GUIDelete($hSettings_GUI)
				ExitLoop
			Case $iCancel_Bttn
				Sleep(100)
				sethotkey()
				GUIDelete($hSettings_GUI)
				ExitLoop
			Case $Checkbox1
				If $trayicon = 0 Then
					$trayicon = 1
					MsgBox(64, "Settings", "Once you disabled Trayicon, you Won't Be Able to Access Settings." & @CRLF & 'To Access Settings you need to Unhide Trayicon Manually By Editing config.ini file, Stored At "AppData\Local\Sharecode Fixer"')
				ElseIf $trayicon = 1 Then
					$trayicon = 0
				EndIf
			Case $Checkbox2
				If $sharecoder = 0 Then
					$sharecoder = 1
				ElseIf $sharecoder = 1 Then
					$sharecoder = 0
				EndIf
			Case $Checkbox3
				If $auto = 0 Then
					$auto = 1
					MsgBox(64, "Settings", 'When "Auto Mode" Is Enabled Make Sure you Use Default Browser to Browse Web' & @CRLF & 'Or Set Browser you Prefer to Use As Default')
				ElseIf $auto = 1 Then
					$auto = 0
				EndIf
		EndSwitch
	WEnd
EndFunc   ;==>CSetting

Func iniwrity()
	If Not $dir Then
	DirCreate($config_dir & "\Sharecode Fixer")
	EndIf
	IniWrite($config_dir & "\config.ini", "HOTKEYS", "exit", "+!x")
	IniWrite($config_dir & "\config.ini", "HOTKEYS", "reset", "+!c")
	IniWrite($config_dir & "\config.ini", "HOTKEYS", "switchmode", "!m")
	IniWrite($config_dir & "\config.ini", "HOTKEYS", "gensharecode", "+g")
	IniWrite($config_dir & "\config.ini", "SETTINGS", "trayiconhide", "0")
	IniWrite($config_dir & "\config.ini", "SETTINGS", "auto", "0")
	IniWrite($config_dir & "\config.ini", "SETTINGS", "disablesharecoder", "0")
EndFunc   ;==>iniwrity


Func Terminate()
	$Pause = False
	$Pause1 = False
	Opt("TrayIconHide", 0)
	TraySetToolTip("Sharecode Fixer By DeLtA")
	TrayTip("Sharecode Fixer - DeLtA", "Program Closed", 0, $TIP_ICONASTERISK)
	If $trayicon = 1 Then
		Sleep(2000)
		Opt("TrayIconHide", $trayicon)
	EndIf
	Sleep(1000)
	Exit
EndFunc   ;==>Terminate

Func Onexit()
	$Pause = False
	$Pause1 = False
	Sleep(1000)
EndFunc   ;==>Onexit
Func CheckUpdate()
	If _WinAPI_IsInternetConnected() Then
		$ver = _INetGetSource('https://quadxtech.net/sharecode/version.txt')
		If $ver > $ver_curr Then
			$down = _INetGetSource('https://quadxtech.net/sharecode/link.txt')
			ShellExecute($down)
		Else
			MsgBox(64, "Quick Update", "You are using latest version of Sharecode Fixer")
		EndIf
	Else
		MsgBox(48, "Quick Update", "You are Offline :|")
	EndIf
EndFunc   ;==>CheckUpdate

Func sethotkey()

	HotKeySet($sExit_HotKey, "Terminate")
	HotKeySet($sReset_HotKey, "Clear")
	If $loop = 2 Then
		HotKeySet($sGen_HotKey, "Generate")
		HotKeySet($sMode_HotKey, "switch1")
	ElseIf $loop = 1 Then
		HotKeySet($sGen_HotKey)
		HotKeySet($sMode_HotKey, "switch2")
	EndIf
EndFunc   ;==>sethotkey

Func Readme()
	If FileExists(@ScriptDir & "\readme.txt") Then
		ShellExecute(@ScriptDir & "\readme.txt")
	Else
		MsgBox(48,"Sharecode Fixer","Unable to Locate ReadME File :(")
	EndIf

EndFunc



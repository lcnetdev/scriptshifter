﻿#include <ButtonConstants.au3>
#include <Date.au3>
#include <Excel.au3>
#include <Functions_KoreanHancha.au3>
#include <GUIConstants.au3>
#include <GUIConstantsEx.au3>
#include <Misc.au3>
#include <String.au3>
#include <StringConstants.au3>
#include <TrayConstants.au3>

   Global $ConvertHancha="On" ; <-- 일반 한자변환 기능 -->
   Global $ConvertNameHancha="On"; <-- 이름 한자변환 기능 -->
   Global $NameInitial="On" ; <-- 이름 두음법칙 적용 -->
   Global $HanchaDisplay = "On" ; <-- On : 漢字 => 漢字(한자), Off : 漢字 => 한자 -->
   Global $ForeignNameConversion = "On" ; <-- 외국이름 변환 -->
   Global $ConvertR2L = "On" ; <-- L로 시작하는 외래어 변환 -->
   Global $CapitalizeAll = "Off"
   Global $IsKoreanLName = 0
   Global $NoOCLCBreve = "Off"
   Global $PersonalEdition="On"

   If $PersonalEdition="Off" Then
	  Global $TT_Title1="PROCESSING"
   Else
	  Global $TT_Title1="변환 중"
   EndIf
   If $PersonalEdition="Off" Then
	  Global $TT_Title2="ERROR"
   Else
	  Global $TT_Title2="오류"
   EndIf
   If $PersonalEdition="Off" Then
	  Global $TT_Title3="COMPLETE"
   Else
	  Global $TT_Title3="변환 완료"
   EndIf
   If $PersonalEdition="Off" Then
	  Global $TT_Text1="Please wait."
   Else
	  Global $TT_Text1="잠시 기다려 주세요."
   EndIf
   If $PersonalEdition="Off" Then
	  Global $TT_Text2="Check the original string."
   Else
	  Global $TT_Text2="변환 전 한글이 맞는지 확인해 주세요."
   EndIf
   If $PersonalEdition="Off" Then
	  Global $TT_Text3="Please proofread the result."
   Else
	  Global $TT_Text3="결과를 확인해 주세요."
   EndIf
   If $PersonalEdition="Off" Then
	  Global $TT_Text4="Please do not move or click the cursor."
   Else
	  Global $TT_Text4="마우스 클릭 금지"
   EndIf

;~    If @OSVersion="WIN_10" OR @OSVersion="WIN_81" OR @OSVersion="WIN_8" Then
;~ 	   Global $TrayTip="OFF"
;~    Else
;~ 	   Global $TrayTip="ON"
;~    EndIf
$TrayTip = "OFF"

;Func RomanizerAllCap()
;   Global $CapitalizeAll = "On" ; <-- 모든 첫글자 대문자 -->
;   Global $Capitalize = "Off"
;   Romanizer()
;EndFunc

;Func RomanizerCap()
;   Global $CapitalizeAll = "Off"
;   Global $Capitalize = "On"; <-- 첫글자만 대문자 -->
;   Romanizer()
;EndFunc

;Func RomanizerNoCap()
;   Global $CapitalizeAll = "Off"
;   Global $Capitalize = "Off"; <-- 모든 첫글자 소문자 -->
;   Romanizer()
;EndFunc

;Func CapitalizeAll()
;   Sleep(50+20)
;   $Source = ClipGet()
;   Local $sArray=StringSplit($Source," ")
;   $AllCapOutput = ""
;   For $i = 1 To Ubound($sArray, 1)-1
;	  ClipPut(StringUpper(StringLeft($sArray[$i],1)) & StringTrimLeft($sArray[$i],1))
;	  $AllCapOutput=$AllCapOutput & " " & ClipGet()
;   Next
;   ClipPut(StringStripWS($AllCapOutput,1+4))
;EndFunc

;Func RomanizerAuth()
;   Global $Auth="Yes"
;   KorNameRom20()
;EndFunc

;Func KorNameRomOCLC()
;   $KorNameRom = ""
;   Sleep(50+50)
;   $NClipB = ClipGet()
;   $ClipB = StringStripWS($NClipB,1+2+4)
;   Sleep(50+50)
;   ClipPut($ClipB)
;   Sleep(50+50)
;   ParseKorName()
;   Sleep(50+50)
;   If StringInStr(ClipGet(),"~") > 0 Then
;	  $aParsedNames = StringSplit(ClipGet(),"~")
;	  $LName = $aParsedNames[1]
;	  $FName = $aParsedNames[2]
;	  Sleep(50+50)
;	  ClipPut($FName)
;	  Sleep(50+50)
;	  KorFNameRom()
;	  Sleep(50+50)
;	  $FNameRom = ClipGet()
;	  Sleep(50+50)
;	  If StringInStr($LName,"+")>0 Then
;		 $aLastNames = StringSplit($LName,"+")
;		 $LName1 = $aLastNames[1]
;		 Sleep(50+50)
;		 ClipPut($LName1)
;		 Sleep(50+50)
;		 KorLNameRom()
;		 Sleep(50+50)
;		 $LNameRom1 = ClipGet()
;		 Sleep(50+50)
;		 $LName2 = $aLastNames[2]
;		 Sleep(50+50)
;		 ClipPut($LName2)
;		 Sleep(50+50)
;		 KorLNameRom()
;		 Sleep(50+50)
;		 $LNameRom2 = ClipGet()
;		 Sleep(50+50)
;		 $LNameRom = $LNameRom1 & " " & $LNameRom2
;		 Sleep(50+50)
;	  Else
;		 Sleep(50+50)
;		 ClipPut($LName)
;		 Sleep(50+50)
;		 KorLNameRom()
;		 Sleep(50+50)
;		 $LNameRom = ClipGet()
;		 Sleep(50+50)
;	  EndIf
;	  Sleep(50+50)
;	  $KorNameRom = $LNameRom & " " & $FNameRom
;	  Sleep(50+50)
;	  ClipPut($KorNameRom)
;	  Sleep(50+50)
;   EndIf
;   If StringRegExp(StringLeft($KorNameRom,1),"[a-z]|[A-Z]")=0 Then
;	  ClipPut($ClipB)
;	  KorCorpNameRomOCLC()
;   EndIf
;Sleep(50+20)
;EndFunc

;Func NameRomanizer()
;   Global $Auth="No"
;   _CopyEX()
;   $ClipB=ClipGet()
;   $ClipB=StringReplace($ClipB,"·",", ")
;   $ClipB=StringReplace($ClipB,"・",", ")
;   If StringInStr($ClipB,",")>0 AND StringLen($ClipB)>4 AND StringLen(StringLeft($ClipB,StringInStr($ClipB,",")-1))>1 Then
;	  BatchRom()
;   Else
;	  KorNameRom20()
;   EndIf
;EndFunc

;Func BatchRom()
;   _CopyEX()
;   TrayTip($TT_Title1,$TT_Text1,15)
;   $ClipB=ClipGet()
;   $ClipB=StringReplace($ClipB,"·",",")
;   $ClipB=StringReplace($ClipB,"・",", ")
;   $ClipB=StringReplace($ClipB,", ",",")
;   If StringRight($ClipB,1)="." Then
;	  $PUNC="p"
;	  ClipPut(StringTrimRight($ClipB,1))
;   Else
;	  If StringRight($ClipB,1)="," Then
;		 $PUNC="c"
;		 ClipPut(StringTrimRight($ClipB,1))
;	  Else
;		 $PUNC="0"
;	  EndIf
;   EndIf
;   $RomName=""
;   If StringInStr($ClipB,",")>0 Then
;	  $Names=StringRegExpReplace($ClipB,",","&")
;	  $Commas=@extended
;	  Local $aNames=StringSplit($Names,"&")
;   Else
;	  $Commas=0
;	  Local $aNames[2]=["0",$ClipB]
;   EndIf
;
;   For $i=0 To $Commas+1
;	  ClipPut($aNames[$i])
;	  If StringIsInt($aNames[$i])=0 then
;		 SimpleRomanizer()
;	  $RomName=$RomName & ", " & ClipGet()
;	  EndIf
;   Next
;
;   If $PUNC="0" Then
;	  ClipPut(StringTrimLeft($RomName,2))
;   EndIf
;   If $PUNC="p" Then
;	  ClipPut(StringTrimLeft($RomName,2)&".")
;   EndIf
;   If $PUNC="c" Then
;	  ClipPut(StringTrimLeft($RomName,2)&",")
;   EndIf
;
;   Sleep4OCLC()
;   If StringRegExp(ClipGet(),"[0-9]")>0 Then
;  	  TrayTip($TT_Title2,$TT_Text2,10)
;	  ClipPut($ClipB)
;   Else
;	  If $TrayTip="On" Then
;		 TrayTip($TT_Title3,$TT_Text3,10)
;	  EndIf
;	  _PasteEx()
;   EndIf
;EndFunc

; Only for simple syllables --sc
Func SimpleRomanizer()
   Sleep(50+100)
   $WinTitle = WinGetTitle("[Active]")
   If StringInStr($WinTitle,"OCLC Connexion")>0 Then
	  $OCLC="Yes"
   Else
	  $OCLC="No"
   EndIF

   ; FKR001
   $NClipB = ClipGet()
   If StringLeft($NClipB,1)="金" OR StringLeft($NClipB,1)="金" Then
	  $NClipB = "김" & StringTrimLeft($NClipB,1)
	  ClipPut($NClipB)
   EndIf

   If $ConvertNameHancha="On" Then
	  Sleep(50+20)
	  MARC8Hancha()
	  Sleep(50+20)
	  Hancha2Hangul()
	  Sleep(50+20)
   EndIf
   $NClipB = ClipGet()
   $ClipB = StringStripWS($NClipB,1+2+4)
   Sleep(50+20)
   ClipPut($ClipB)

   $ClipB = StringStripWS($NClipB,1+2+4)
   Sleep(50+60)
   ClipPut($ClipB)
   Sleep(50+60)
   ParseKorName()
   Sleep(50+60)
   If StringInStr(ClipGet(),"~") > 0 Then
	  $aParsedNames = StringSplit(ClipGet(),"~")
	  $LName = $aParsedNames[1]
	  $FName = $aParsedNames[2]
	  ClipPut($FName)
	  KorFNameRom()
	  $FNameRom = ClipGet()
	  If StringInStr($LName,"+")>0 Then
		 $aLastNames = StringSplit($LName,"+")
		 $LName1 = $aLastNames[1]
		 ClipPut($LName1)
		 KorLNameRom()
		 $LNameRom1 = ClipGet()
		 $LName2 = $aLastNames[2]
		 ClipPut($LName2)
		 KorLNameRom()
		 $LNameRom2 = ClipGet()
		 $LNameRom = $LNameRom1 & " " & $LNameRom2
	  Else
		 ClipPut($LName)
		 KorLNameRom()
		 $LNameRom = ClipGet()
	  EndIf
	  $KorNameRom = $LNameRom & " " & $FNameRom

	  If $OCLC="No" Then
		 Local $MARC8[4][2] = [["ŏ","ŏ"],["ŭ","ŭ"],["Ŏ","Ŏ"],["Ŭ","Ŭ"]]
		 For $i = 0 To Ubound($MARC8, 1) - 1
			$KorNameRom = StringRegExpReplace($KorNameRom, "\Q" & $MARC8[$i][0] & "\E",$MARC8[$i][1])
		 Next
	  EndIf

	  ClipPut($KorNameRom)
   EndIf
EndFunc

; Main function to transliterate names ONLY
; Multiple names are possible, divided by comma or center dot.
Func KorNameRom20()
   Sleep(50+100)
   $WinTitle = WinGetTitle("[Active]")
   If StringInStr($WinTitle,"OCLC Connexion")>0 Then
	  $OCLC="Yes"
   Else
	  $OCLC="No"
   EndIF

   Sleep4OCLC()
   _CopyEx()
   $ORIG = ClipGet()
   $ORIGInPut = $ORIG
   ; FKR001
   If StringLeft($ORIG,1)="金" OR StringLeft($ORIG,1)="金" Then
	  $ORIG = "김" & StringTrimLeft($ORIG,1)
	  ClipPut($ORIG)
   EndIf
   If StringLeft($ORIG,1)="李" OR StringLeft($ORIG,1)="李" Then
	  $ORIG = "이" & StringTrimLeft($ORIG,1)
	  ClipPut($ORIG)
   EndIf
   ; <-- FKR002 -->
   If StringLeft($ORIG,1)="리" Then
	  $ORIG = "이" & StringTrimLeft($ORIG,1)
	  ClipPut($ORIG)
   EndIf
   If StringLeft($ORIG,1)="라" Then
	  $ORIG = "나" & StringTrimLeft($ORIG,1)
	  ClipPut($ORIG)
   EndIf
   If StringLeft($ORIG,1)="류" Then
	  $ORIG = "유" & StringTrimLeft($ORIG,1)
	  ClipPut($ORIG)
   EndIf
   If StringLeft($ORIG,1)="로" Then
	  $ORIG = "노" & StringTrimLeft($ORIG,1)
	  ClipPut($ORIG)
   EndIf

   ; <-- FKR003 -->
   If $ConvertNameHancha="On" Then
	  Sleep(50+20)
	  MARC8Hancha()
	  Sleep(50+20)
	  Hancha2Hangul()
	  Sleep(50+20)
   EndIf

   $NClipB = ClipGet()
   $ClipB = StringStripWS($NClipB,1+2+4)
   Sleep(50+20)
   ClipPut($ClipB)

   If StringRegExp($ClipB,"[a-z]|[A-Z]|[0-9]")>0 Then
  	  TrayTip("ERROR: " & $NClipB,"may not be a personal name. Use CTRL+ALT+k instead.",10)
   Else
		 Sleep4OCLC()
		 ParseKorName()
		 Sleep4OCLC()
		 If StringInStr(ClipGet(),"~") > 0 Then
			$aParsedNames = StringSplit(ClipGet(),"~")
			$LName = $aParsedNames[1]
			$FName = $aParsedNames[2]
			ClipPut($FName)
			KorFNameRom()
			$FNameRom = ClipGet()
			If StringInStr($LName,"+")>0 Then
			   $aLastNames = StringSplit($LName,"+")
			   $LName1 = $aLastNames[1]
			   ClipPut($LName1)
			   KorLNameRom()
			   $LNameRom1 = ClipGet()
			   $LName2 = $aLastNames[2]
			   ClipPut($LName2)
			   KorLNameRom()
			   $LNameRom2 = ClipGet()
			   $LNameRom = $LNameRom1 & " " & $LNameRom2
			Else
			   ClipPut($LName)
			   KorLNameRom()
			   $LNameRom = ClipGet()
			EndIf

			$KorNameRom = $LNameRom & " " & $FNameRom

			If $OCLC="No" Then
			   Local $MARC8[4][2] = [["ŏ","ŏ"],["ŭ","ŭ"],["Ŏ","Ŏ"],["Ŭ","Ŭ"]]
			   For $i = 0 To Ubound($MARC8, 1) - 1
				  $KorNameRom = StringRegExpReplace($KorNameRom, "\Q" & $MARC8[$i][0] & "\E",$MARC8[$i][1])
			   Next
			EndIf

			If StringRegExp($KorNameRom,"[0-9]")=1 OR $IsKoreanLName = 0 Then
			   TrayTip("ERROR: " & $ORIGInPut,"may not be a personal name. Use CTRL+ALT+k instead.",10)
			Else
			   ClipPut($KorNameRom)
			   If $Auth="Yes" Then
				  $KorNameRom=StringReplace($KorNameRom," ",", ",-1,0)
				  ClipPut($KorNameRom)
				  _PasteEx()
			   Else
				  _PasteEx()
			   EndIf
			If $TrayTip="ON" Then
			   If $OCLC="Yes" Then
				  If $Auth="Yes" Then
					 TrayTip($TT_Title3,@LF & $ORIGInPut & " > " & $KorNameRom & @LF & "(for Authority Heading in OCLC)",10)
				  Else
					 TrayTip($TT_Title3,@LF & $ORIGInPut & " > " & $KorNameRom & @LF & "(for OCLC Connexion)",10)
				  EndIf
			   Else
				  If $Auth="Yes" Then
					 TrayTip($TT_Title3,@LF & $ORIGInPut & " > " & $KorNameRom & @LF & "(for Authority Heading)",10)
				  Else
					 TrayTip($TT_Title3,@LF & $ORIGInPut & " > " & $KorNameRom,10)
				  EndIf
			   EndIf
			EndIf

			EndIf
		 Else
			$KorNameRom = ClipGet()
			If $KorNameRom = "Error!" Then
			   TrayTip("ERROR: " & $ORIGInPut,"may not be a Korean name. Use ALT+SHIFT+k instead.",10)
			Else
			   _PasteEx()
			   If $TrayTip="ON" Then
				  TrayTip($TT_Title3,@LF & $ORIGInPut & " > " & $KorNameRom & @LF & "(Romanized as foreign name)",10)
			   EndIf
			EndIf
		 EndIf
   EndIf
EndFunc

Func ParseKorName()
   $ParsedName=""
   $TargetKorOrig = ClipGet()
   $TargetKor = StringStripWS($TargetKorOrig,$STR_STRIPALL)

; <-- FKR004 -->
   Local $TwoChaKorLastNames[10]=["남궁","독고","동방","사공","서문","선우","제갈","황보","사마","을지"]
   Local $j
   For $i=0 To UBound($TwoChaKorLastNames,1)-1
	  Local $Result=StringRegExp(StringLeft($TargetKor,2),$TwoChaKorLastNames[$i])
	  If $Result="1" Then
		 $j = $j + 1
	  EndIF
   Next

   ; <-- FKR005 -->
   If StringLen($TargetKor) > 7 OR StringLen($TargetKor) = 1 OR StringInStr($TargetKorOrig," ",0,1)>3 Then
	  If $ForeignNameConversion = "Yes" Then  ; Assuming yes in SS?
		 ClipPut($TargetKorOrig)
		 KorCorpNameRomOCLC()
	  Else
		 TrayTip("Error!",@LF & $TargetKorOrig & @LF & "may not be a Korean name",10)
		 ClipPut("Error!")
	  EndIf
   Else
	  ; <-- FKR006 -->
	  If StringInStr($TargetKorOrig," ",0,3)>0 Then
		 TrayTip("Error!",@LF & $TargetKorOrig & @LF & "may not be a Korean name (too many spaces)",10)
	  Else
		 ; <-- FKR007 -->
		 If StringInStr($TargetKorOrig," ",0,1)>0 AND StringInStr($TargetKorOrig," ",0,2)>0 Then
			$aNames = StringSplit($TargetKorOrig," ")
			$ParsedName = $aNames[1] & "+" & $aNames[2] & "~" & $aNames[3]
			ClipPut($ParsedName)
		 EndIf
		 ; <-- FKR008 -->
		 If StringInStr($TargetKorOrig," ",0,1)=2 AND StringInStr($TargetKorOrig," ",0,2)=0 Then
			$aNames = StringSplit($TargetKorOrig," ")
			$ParsedName = $aNames[1] & "~" & $aNames[2]
		 EndIf
		 ; <-- FKR009 -->
		 If StringInStr($TargetKorOrig," ",0,1)=3 AND StringInStr($TargetKorOrig," ",0,2)=0 Then
			If $j=1 Then
			   $aNames = StringSplit($TargetKorOrig," ")
			   $ParsedName = $aNames[1] & "~" & $aNames[2]
			Else
			   $aNames = StringSplit($TargetKorOrig," ")
			   $ParsedName = $aNames[1] & "~" & $aNames[2]
			   $ParsedName = _StringInsert($ParsedName,"+",1)
			EndIf
		 EndIf
		 ; <-- FKR010 -->
		 If StringInStr($TargetKorOrig," ",0,1)=0 Then
			If StringLen($TargetKorOrig)=2 Then
			   $ParsedName = _StringInsert($TargetKorOrig,"~",1)
			EndIf
			If StringLen($TargetKorOrig)>2 Then
			   If $j=1 Then
				  $ParsedName = _StringInsert($TargetKorOrig,"~",2)
			   Else
				  $ParsedName = _StringInsert($TargetKorOrig,"~",1)
			   EndIf
			EndIf
		 EndIf
		 ClipPut($ParsedName)
	  EndIf
   EndIf
EndFunc

Func KorFNameRom()
   $TargetKor = ClipGet()
   Local $aArray = StringToASCIIArray ($TargetKor)
   If StringLen($TargetKor) > 0 Then
	  $ASCII1 = Number($aArray[0])-44032
	  $Target = $ASCII1
	  $Ini1 = "i" & FLOOR(Number($Target)/588)
	  $Med1 = "m" & MOD(FLOOR(Number($Target)/28),21)
	  $Fin1 = "f" & MOD(Number($Target),28)
	  If StringLen($TargetKor) > 1 Then
		 $ASCII2 = Number($aArray[1])-44032
		 $Target = $ASCII2
		 $Ini2 = "i" & FLOOR(Number($Target)/588)
		 $Med2 = "m" & MOD(FLOOR(Number($Target)/28),21)
		 $Fin2 = "f" & MOD(Number($Target),28)
		 If StringLen($TargetKor) > 2 Then
			$ASCII3 = Number($aArray[2])-44032
			$Target = $ASCII3
			$Ini3 = "i" & FLOOR(Number($Target)/588)
			$Med3 = "m" & MOD(FLOOR(Number($Target)/28),21)
			$Fin3 = "f" & MOD(Number($Target),28)
			If StringLen($TargetKor) > 3 Then
			   $ASCII4 = Number($aArray[3])-44032
			   $Target = $ASCII4
			   $Ini4 = "i" & FLOOR(Number($Target)/588)
			   $Med4 = "m" & MOD(FLOOR(Number($Target)/28),21)
			   $Fin4 = "f" & MOD(Number($Target),28)
			   If StringLen($TargetKor) > 4 Then
				  $ASCII5 = Number($aArray[4])-44032
				  $Target = $ASCII5
				  $Ini5 = "i" & FLOOR(Number($Target)/588)
				  $Med5 = "m" & MOD(FLOOR(Number($Target)/28),21)
				  $Fin5 = "f" & MOD(Number($Target),28)
				  If StringLen($TargetKor) > 5 Then
					 $ASCII6 = Number($aArray[5])-44032
					 $Target = $ASCII6
					 $Ini6 = "i" & FLOOR(Number($Target)/588)
					 $Med6 = "m" & MOD(FLOOR(Number($Target)/28),21)
					 $Fin6 = "f" & MOD(Number($Target),28)
					 $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "~" & $Ini5 & "#" & $Med5 & "#" & $Fin5 &  "~" & $Ini6 & "#" & $Med6 & "#" & $Fin6 & "E"
				  Else
					 $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "~" & $Ini5 & "#" & $Med5 & "#" & $Fin5 & "E"
				  EndIf
			   Else
				  $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "E"
			   EndIf
			Else
			   $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "E"
			EndIf
		 Else
			$Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "E"
		 EndIf
	  Else
		 $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "E"
	  EndIf
; <-- FKR011 -->
   Local $NatFin[22] = ["f2~","f2E","f3","f5","f6","f7","f9","f10","f11","f12","f13","f14","f15","f18","f19","f20","f22","f23","f24","f25","f26","f27"]
   $j = "0"
   For $i=0 To UBound($NatFin,1)-1
	  Local $Result=StringRegExp($Rom,$NatFin[$i])
	  If $Result="1" Then
		 $j = $j + 1
	  EndIF
   Next
   If $j > 0 Then
	  $OriginByFin ="Native"
   Else
	  $OriginByFin ="Sino"
   EndIf


; <-- FKR011-->
   Local $NatIni[7]=["i1#","i4#","i8#","i10#","i13#","i15#","i16#"]
   $j="0"
   For $i=0 To UBound($NatIni,1)-1
	  Local $Result=StringRegExp($Rom,$NatIni[$i])
	  If $Result="1" Then
		 $j = $j + 1
	  EndIF
   Next
   Local $SinoIni[18] = ["씨","쌍","쾌","타","탁","탄","탈","탐","탑","탕","태","택","탱","토","통","퇴","투","특"]
   $k="0"
   For $i=0 To UBound($SinoIni,1)-1
	  Local $Result=StringRegExp($TargetKor,$SinoIni[$i])
	  If $Result="1" Then
		 $k = $k + 1
	  EndIF
   Next
   If $j>0 Then
	  If $k>0 Then
		 $OriginByIni = "Sino"
	  Else
		 $OriginByIni = "Native"
	  EndIf
   Else
		 $OriginByIni = "Sino"
   EndIf
; <-- FKR012 -->
   Local $NatMed[10]=["m1#f4","m1#f8","m1#f16","m1#f17","m5#f4","m5#f8","m5#f16","m5#f17","m5#f21","m18#f0"]
   $l="0"
   For $i=0 To UBound($NatMed,1)-1
	  Local $Result=StringRegExp($Rom,$NatMed[$i])
	  If $Result="1" Then
		 $l = $l + 1
	  EndIF
   Next
   If $l>0 Then
	  $OriginByMed = "Native"
   Else
	  $OriginByMed = "Sino"
   EndIF

; <-- FKR013 -->
   If StringInStr($Rom,"m19#")>0 Then
	  If StringInStr($TargetKor,"의")>0 OR StringInStr($TargetKor,"희")>0 Then
		 $OriginByMed = "Sino"
	  Else
		 $OriginByMed = "Native"
	  EndIf
   EndIf

; <-- FKR014 -->
   Local $Rule1[3][2] = [["f1~i2#","f21~i2#"],["f1~i5#","f21~i2#"],["f1~i6#","f21~i6#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
; <-- FKR015 -->
   Local $Rule1[3][2] = [["f2~i2#","f21~i2#"],["f2~i5#","f21~i2#"],["f2~i6#","f21~i6#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
; <-- FKR016 -->
   Local $Rule1[1][2] = [["f4~i5#","f8~i5#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
; <-- FKR017 -->
   Local $Rule1[3][2] = [["f7~i2#","f4~i2#"],["f7~i5#","f4~i2#"],["f7~i6#","f4~i6#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
; <-- FKR018 -->
   Local $Rule1[1][2] = [["f8~i2#","f8~i5#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
; <-- FKR019 -->
   Local $Rule1[1][2] = [["f16~i5#","f16~i2#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
; <-- FKR020 -->
   Local $Rule1[3][2] = [["f17~i2#","f16~i2#"],["f17~i5#","f16~i2#"],["f17~i6#","f16~i6#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
; <-- FKR021 -->
   Local $Rule1[4][2] = [["f19~i2#","f4~i2#"],["f19~i5#","f4~i2#"],["f19~i6#","f4~i6#"],["f19~i11#","f0~i9#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
; <-- FKR022 -->
   Local $Rule1[4][2] = [["f20~i2#","f4~i2#"],["f20~i5#","f4~i2#"],["f20~i6#","f4~i6#"],["f20~i11#","f0~i10#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
; <-- FKR023 -->
   Local $Rule1[1][2] = [["f21~i5#","f21~i2#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
; <-- FKR024 -->
   Local $Rule1[4][2] = [["f22~i2#","f4~i2#"],["f22~i5#","f4~i2#"],["f22~i6#","f4~i6#"],["f22~i11#","f0~i12#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
; <-- FKR025 -->
   Local $Rule1[4][2] = [["f23~i2#","f4~i2#"],["f23~i5#","f4~i2#"],["f23~i6#","f4~i6#"],["f23~i11#","f0~i14#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
; <-- FKR026 -->
   Local $Rule1[8][2] = [["f27~i0#","f0~i15#"],["f27~i2#","f4~i2#"],["f27~i3#","f0~i16#"],["f27~i5#","f4~i2#"],["f27~i6#","f4~i6#"],["f27~i7#","f0~i17#"],["f27~i11#","f0~i11#"],["f27~i12#","f0~i14#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next

; <-- FKR027 -->
   Local $FinRule[21][2] = [["f1E","f1"],["f2E","f1"],["f3E","f1"],["f4E","f4"],["f7E","f7"],["f8E","f8"],["f9E","f1"],["f10E","f16"],["f16E","f16"],["f17E","f17"],["f18E","f17"],["f19E","f7"],["f20E","f7"],["f21E","f21"],["f22E","f7"],["f23E","f7"],["f24E","f1"],["f25E","f7"],["f26E","f17"],["f27E","f7"]]
   For $i = 0 To Ubound($FinRule, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $FinRule[$i][0] & "\E",$FinRule[$i][1])
   Next

; <-- FKR028 -->
   Local $Rule1[18][2] = [["f0~i0#","~g"],["f0~i3#","~d"],["f0~i7#","~b"],["f0~i12#","~j"],["f4~i0#","n~g"],["f4~i3#","n~d"],["f4~i7#","n~b"],["f4~i12#","n~j"],["f8~i0#","l~g"],["f8~i7#","l~b"],["f16~i0#","m~g"],["f16~i3#","m~d"],["f16~i7#","m~b"],["f16~i12#","m~j"],["f21~i0#","ng~g"],["f21~i3#","ng~d"],["f21~i7#","ng~b"],["f21~i12#","ng~j"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next

; <-- FKR029 -->
   Local $Rule1[4][2] = [["f1~i11#","g~"],["f7~i11#","d~"],["f17~i11#","b~"],["f22~i11#","j~"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next

; <-- FKR030 -->
   Local $Initials[19][2] = [["i10","ss"],["i11",""],["i12","ch"],["i13","tch"],["i14","ch'"],["i15","k'"],["i16","t'"],["i17","p'"],["i18","h"],["i0","k"],["i1","kk"],["i2","n"],["i3","t"],["i4","tt"],["i5","r"],["i6","m"],["i7","p"],["i8","pp"],["i9","s"]]
   For $i = 0 To Ubound($Initials, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Initials[$i][0] & "\E",$Initials[$i][1])
   Next

   Local $Medials[22][2] = [["m10","wae"],["m11","oe"],["m12","yo"],["m13","u"],["m14","wŏ"],["m15","we"],["m16","wi"],["m17","yu"],["m18","ŭ"],["m19","ŭi"],["m20","i"],["m0","a"],["m1","ae"],["m2","ya"],["m3","yae"],["m4","ŏ"],["m5","e"],["m6","yŏ"],["m7","ye"],["m8","o"],["m9","wa"],["f0E","f0"]]
   For $i = 0 To Ubound($Medials, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Medials[$i][0] & "\E",$Medials[$i][1])
   Next

   Local $Finals[16][2] = [["f16","m"],["f17","p"],["f19","t"],["f20","t"],["f21","ng"],["f22","t"],["f23","t"],["f24","k"],["f25","t"],["f26","p"],["f27","t"],["f1","k"],["f4","n"],["f7","t"],["f8","l"],["f0",""]]
   For $i = 0 To Ubound($Finals, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Finals[$i][0] & "\E",$Finals[$i][1])
   Next

$Rom = StringReplace($Rom,"#","")
$Rom = StringReplace($Rom,"swi","shwi",0,1)
$Rom = StringReplace($Rom,"Swi","Shwi",0,1)

If StringLen($TargetKor)=2 Then
   $Rom = StringReplace($Rom,"~","-")
Else
   $Rom = StringReplace ($Rom,"n~g","n'g")
   $Rom = StringReplace($Rom,"~","")
EndIf

; <-- FKR031 -->
   Local $Rule1[11][2] = [["l-a","r-a"],["l-i","r-i"],["l-e","r-e"],["l-o","r-o"],["l-u","r-u"],["l-h","r-h"],["l-ŏ","r-ŏ"],["l-ŭ","r-ŭ"],["l-y","r-y"],["l-w","r-w"],["l-r","l*r"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
   Local $Rule1[12][2] = [["la","ra"],["li","ri"],["le","re"],["lo","ro"],["lu","ru"],["lh","rh"],["lŏ","rŏ"],["lŭ","rŭ"],["ly","ry"],["lw","rw"],["*r","-l"],["lr","ll"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next

; <-- FKR032-->
   $Rom1 = StringTrimRight($Rom,StringLen($Rom)-1)
   $Rom2 = StringTrimLeft($Rom,1)
   $Rom = StringUpper($Rom1) & $Rom2

; <-- FKR033 -->
   If StringLen($TargetKor)=2 Then
	  If $OriginByIni = "Native" OR $OriginByFin = "Native" OR $OriginByMed = "Native" Then
		 $Rom = StringReplace ($Rom,"n-g","n'g")
		 $Rom = StringReplace ($Rom,"-","")
	  EndIf
   EndIf

; <-- FKR034 -->
If $NameInitial="On" Then
   If StringLen($TargetKor) > 1 Then
	  If StringInStr($Rom,"Ra")=1 Then
		 $Rom = StringReplace($Rom,"Ra","Na",1)
	  EndIf
	  If StringInStr($Rom,"Ro")=1 Then
		 $Rom = StringReplace($Rom,"Ro","No",1)
	  EndIf
	  If StringInStr($Rom,"Ri")=1 Then
		 $Rom = StringReplace($Rom,"Ri","I",1)
	  EndIf
	  If StringInStr($Rom,"Ry")=1 Then
		 $Rom = StringReplace($Rom,"Ry","Y",1)
	  EndIf
  EndIf
EndIf

   ClipPut($Rom)
Else

EndIf

EndFunc

Func KorLNameRom()
   Sleep(50+20)
   $TargetKor = ClipGet()
   Sleep(50+20)
   If StringLen($TargetKor) = 2 Then
	  Local $TwoCharacters[10][2] = [["南宮","Namgung"],["諸葛","Chegal"],["皇甫","Hwangbo"],["鮮于","Sŏnu"],["西門","Sŏmun"],["東方","Tongbang"],["獨孤","Tokko"],["司空","Sagong"],["司馬","Sama"],["乙支","Ŭlchi"]]
	  For $i = 0 To Ubound($TwoCharacters, 1) - 1
		 $TargetKor = StringRegExpReplace($TargetKor, "\Q" & $TwoCharacters[$i][0] & "\E",$TwoCharacters[$i][1])
		 $IsKoreanLName = $IsKoreanLName + @extended
	  Next
	  Local $TwoCharacters[10][2] = [["남궁","Namgung"],["제갈","Chegal"],["황보","Hwangbo"],["선우","Sŏnu"],["서문","Sŏmun"],["동방","Tongbang"],["독고","Tokko"],["사공","Sagong"],["사마","Sama"],["을지","Ŭlchi"]]
	  For $i = 0 To Ubound($TwoCharacters, 1) - 1
		 $TargetKor = StringRegExpReplace($TargetKor, "\Q" & $TwoCharacters[$i][0] & "\E",$TwoCharacters[$i][1])
		 $IsKoreanLName = $IsKoreanLName + @extended
	  Next
	  $Rom = $TargetKor
   Else
	  Local $LNinChiSet[275][2] = [['賈','가'],['簡','간'],['葛','갈'],['甘','감'],['剛','강'],['姜','강'],['康','강'],['强','강'],['彊','강'],['介','개'],['堅','견'],['甄','견'],['京','경'],['慶','경'],['景','경'],['桂','계'],['高','고'],['曲','곡'],['公','공'],['孔','공'],['郭','곽'],['橋','교'],['丘','구'],['具','구'],['邱','구'],['國','국'],['菊','국'],['鞠','국'],['君','군'],['弓','궁'],['鴌','궉'],['權','권'],['斤','근'],['琴','금'],['奇','기'],['箕','기'],['吉','길'],['金','김'],['金','김'],['羅','나'],['欒','난'],['南','남'],['浪','낭'],['乃','내'],['奈','내'],['盧','노'],['路','노'],['魯','노'],['賴','뇌'],['雷','뇌'],['樓','누'],['單','단'],['段','단'],['端','단'],['譚','담'],['唐','당'],['大','대'],['道','도'],['都','도'],['陶','도'],['敦','돈'],['頓','돈'],['董','동'],['杜','두'],['頭','두'],['柳','류'],['馬','마'],['麻','마'],['萬','만'],['梅','매'],['孟','맹'],['明','명'],['毛','모'],['牟','모'],['睦','목'],['苗','묘'],['墨','묵'],['文','문'],['米','미'],['閔','민'],['朴','박'],['潘','반'],['班','반'],['房','방'],['方','방'],['邦','방'],['龐','방'],['裵','배'],['白','백'],['凡','범'],['范','범'],['卞','변'],['邊','변'],['卜','복'],['奉','봉'],['鳳','봉'],['傅','부'],['夫','부'],['丕','비'],['彬','빈'],['賓','빈'],['冰','빙'],['氷','빙'],['史','사'],['舍','사'],['謝','사'],['杉','삼'],['森','삼'],['尙','상'],['徐','서'],['西','서'],['昔','석'],['石','석'],['宣','선'],['楔','설'],['薛','설'],['葉','섭'],['成','성'],['星','성'],['肖','소'],['蘇','소'],['邵','소'],['孫','손'],['宋','송'],['松','송'],['水','수'],['洙','수'],['淳','순'],['舜','순'],['荀','순'],['順','순'],['承','승'],['昇','승'],['施','시'],['柴','시'],['愼','신'],['申','신'],['辛','신'],['沈','심'],['沈','심'],['什','십'],['阿','아'],['安','안'],['艾','애'],['夜','야'],['梁','양'],['楊','양'],['樑','양'],['襄','양'],['魚','어'],['嚴','엄'],['余','여'],['呂','여'],['汝','여'],['延','연'],['燕','연'],['連','연'],['廉','염'],['葉','엽'],['影','영'],['榮','영'],['永','영'],['乂','예'],['芮','예'],['吳','오'],['玉','옥'],['溫','온'],['邕','옹'],['雍','옹'],['王','왕'],['姚','요'],['龍','용'],['于','우'],['宇','우'],['禹','우'],['芸','운'],['雲','운'],['元','원'],['苑','원'],['袁','원'],['韋','위'],['魏','위'],['兪','유'],['劉','유'],['庾','유'],['陸','육'],['尹','윤'],['殷','은'],['陰','음'],['伊','이'],['李','이'],['異','이'],['印','인'],['任','임'],['林','임'],['慈','자'],['張','장'],['章','장'],['莊','장'],['蔣','장'],['邸','저'],['全','전'],['田','전'],['錢','전'],['占','점'],['丁','정'],['程','정'],['鄭','정'],['諸','제'],['齊','제'],['曺','조'],['趙','조'],['宗','종'],['鍾','종'],['左','좌'],['周','주'],['朱','주'],['俊','준'],['汁','즙'],['增','증'],['曾','증'],['智','지'],['池','지'],['晋','진'],['眞','진'],['秦','진'],['陳','진'],['車','차'],['倉','창'],['昌','창'],['菜','채'],['蔡','채'],['采','채'],['千','천'],['天','천'],['初','초'],['楚','초'],['肖','초'],['崔','최'],['秋','추'],['鄒','추'],['椿','춘'],['卓','탁'],['彈','탄'],['太','태'],['判','판'],['彭','팽'],['扁','편'],['片','편'],['平','평'],['包','포'],['表','표'],['馮','풍'],['皮','피'],['弼','필'],['夏','하'],['河','하'],['學','학'],['漢','한'],['韓','한'],['咸','함'],['海','해'],['許','허'],['玄','현'],['邢','형'],['扈','호'],['胡','호'],['鎬','호'],['洪','홍'],['化','화'],['桓','환'],['黃','황'],['候','후'],['后','후'],['興','흥']]
	  For $i = 0 To Ubound($LNinChiSet, 1) - 1
		 $TargetKor = StringRegExpReplace($TargetKor, "\Q" & $LNinChiSet[$i][0] & "\E",$LNinChiSet[$i][1])
		 $IsKoreanLName = $IsKoreanLName + @extended
	  Next
	  Local $OneCharacters[175][2] = [["김","Kim"],["가","Ka"],["간","Kan"],["갈","Kal"],["감","Kam"],["강","Kang"],["개","Kae"],["견","Kyŏn"],["경","Kyŏng"],["계","Kye"],["고","Ko"],["곡","Kok"],["공","Kong"],["곽","Kwak"],["교","Kyo"],["구","Ku"],["국","Kuk"],["군","Kun"],["궁","Kung"],["궉","Kwŏk"],["권","Kwŏn"],["근","Kŭn"],["금","Kŭm"],["기","Ki"],["길","Kil"],["나","Na"],["난","Nan"],["남","Nam"],["낭","Nang"],["내","Nae"],["노","No"],["뇌","Noe"],["누","Nu"],["단","Tan"],["담","Tam"],["당","Tang"],["대","Tae"],["도","To"],["독","Tok"],["돈","Ton"],["동","Tong"],["두","Tu"],["라","Na"],["로","No"],["류","Yu"],["리","Yi"],["림","Im"],["마","Ma"],["만","Man"],["매","Mae"],["맹","Maeng"],["명","Myŏng"],["모","Mo"],["목","Mok"],["묘","Myo"],["묵","Muk"],["문","Mun"],["미","Mi"],["민","Min"],["박","Pak"],["반","Pan"],["방","Pang"],["배","Pae"],["백","Paek"],["범","Pŏm"],["변","Pyŏn"],["복","Pok"],["봉","Pong"],["부","Pu"],["비","Pi"],["빈","Pin"],["빙","Ping"],["사","Sa"],["삼","Sam"],["상","Sang"],["서","Sŏ"],["석","Sŏk"],["선","Sŏn"],["설","Sŏl"],["섭","Sŏp"],["성","Sŏng"],["소","So"],["손","Son"],["송","Song"],["수","Su"],["순","Sun"],["승","Sŭng"],["시","Si"],["신","Sin"],["심","Sim"],["십","Sip"],["아","A"],["안","An"],["애","Ae"],["야","Ya"],["양","Yang"],["어","Ŏ"],["엄","Ŏm"],["여","Yŏ"],["연","Yŏn"],["염","Yŏm"],["엽","Yŏp"],["영","Yŏng"],["예","Ye"],["오","O"],["옥","Ok"],["온","On"],["옹","Ong"],["왕","Wang"],["요","Yo"],["용","Yong"],["우","U"],["운","Un"],["원","Wŏn"],["위","Wi"],["유","Yu"],["육","Yuk"],["윤","Yun"],["은","Ŭn"],["음","Ŭm"],["이","Yi"],["인","In"],["임","Im"],["자","Cha"],["장","Chang"],["저","Chŏ"],["전","Chŏn"],["점","Chŏm"],["정","Chŏng"],["제","Che"],["조","Cho"],["종","Chong"],["좌","Chwa"],["주","Chu"],["준","Chun"],["즙","Chŭp"],["증","Chŭng"],["지","Chi"],["진","Chin"],["차","Ch'a"],["창","Ch'ang"],["채","Ch'ae"],["천","Ch'ŏn"],["초","Ch'o"],["최","Ch'oe"],["추","Ch'u"],["춘","Ch'un"],["침","Sim"],["탁","T'ak"],["탄","T'an"],["태","T'ae"],["판","P'an"],["팽","P'aeng"],["편","P'yŏn"],["평","P'yŏng"],["포","P'o"],["표","P'yo"],["풍","P'ung"],["피","P'i"],["필","P'il"],["하","Ha"],["학","Hak"],["한","Han"],["함","Ham"],["해","Hae"],["허","Hŏ"],["현","Hyŏn"],["형","Hyŏng"],["호","Ho"],["홍","Hong"],["화","Hwa"],["환","Hwan"],["황","Hwang"],["후","Hu"],["흥","Hŭng"]]
	  For $i = 0 To Ubound($OneCharacters, 1) - 1
		 $TargetKor = StringRegExpReplace($TargetKor, "\Q" & $OneCharacters[$i][0] & "\E",$OneCharacters[$i][1])
		 $IsKoreanLName = $IsKoreanLName + @extended
	  Next
	  $Rom = $TargetKor
   EndIf
   ClipPut($Rom)
EndFunc

Func KorCorpNameRomOCLC()
   Sleep(50+50)
   $NClipB = ClipGet()
   $TargetKorOrig = $NClipB
   $CHU = "0"
   $YU = "0"
   If StringLeft($NClipB,4)="(주) " Then
	  $NClipB = StringTrimLeft($NClipB,4)
	  $CHU = "L"
   EndIf
   If StringRight($NClipB,4)=" (주)" Then
	  $NClipB = StringTrimRight($NClipB,4)
	  $CHU = "R"
   EndIf
   If StringLeft($NClipB,4)="(유) " Then
	  $NClipB = StringTrimLeft($NClipB,4)
	  $YU = "L"
   EndIf
   If StringRight($NClipB,4)=" (유)" Then
	  $NClipB = StringTrimRight($NClipB,4)
	  $YU = "R"
   EndIf
   $ClipB = StringStripWS($NClipB,1+2+4)
   Sleep(50+20)
   $Result=""
   Local $aArray=StringSplit($ClipB," ")
   For $i = 1 To Ubound($aArray, 1)-1
	 ClipPut($aArray[$i])
	 Sleep(50+50)
	 RomanizerOCLCAuto()
	 Sleep(50+50)
	 $Result=$Result & " " & ClipGet()
	 Sleep(50+50)
   Next
   $Result1=StringStripWS($Result,1+4)
   $Result2=""
   Local $aArray=StringSplit($Result1," ")
   For $i = 1 To Ubound($aArray, 1)-1
	  Sleep(50+50)
	  ClipPut(StringUpper(StringLeft($aArray[$i],1)) & StringTrimLeft($aArray[$i],1))
	  Sleep(50+50)
	  $Result2=$Result2 & " " & ClipGet()
	  Sleep(50+50)
   Next
   If $CHU = "L" Then
	  $Result2 = "(Chu) " & $Result2
   EndIf
   If $CHU = "R" Then
	  $Result2 = $Result2 & " (Chu)"
   EndIf
   If $YU = "L" Then
	  $Result2 = "(Yu) " & $Result2
   EndIf
   If $YU = "R" Then
	  $Result2 = $Result2 & " (Yu)"
   EndIf
Sleep(50+50)
; <-- FKR035 -->
   Local $Rule1[4][2] = [["Nuk'ŏsŭ","Luk'ŏsŭ"],["Rotte","Lotte"],["Ri P'illŭm","Li P'illŭm"],["Numiksŭ","Lumiksŭ"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Result2 = StringRegExpReplace($Result2, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next

   ClipPut(StringStripWS($Result2,1+4))
Sleep(50+50)
EndFunc

; Main function to romanize everything but personal names.
; <-- FKR036 -->
Func Romanizer() ; <-- FKR037 -->
   $Ambig = "No"
   $AmbigExp = ""

   _CopyEx()
   $OriginalText = ClipGet()

; <-- FKR038 -->
   If $ConvertHancha="On" Then
	  Sleep(50+20)
	  MARC8Hancha()
	  Sleep(50+20)
	  Hancha2Hangul()
	  Sleep(50+20)
   EndIf

   $RawClip = " " & ClipGet() & " "

   ; FKR039
   Local $RuleDivPN[21][2] = [[" 프린스턴 대학교 "," P'ŭrinsŭt'ŏn Taehakkyo "],[" 동남 아시아 "," Tongnam Asia "],[" 동북 아시아 "," Tongbuk Asia "],[" 서남 아시아 "," Sŏnam Asia "],[" 서울 대학교 "," Sŏul Taehakkyo "],[" 중앙 아시아 "," Chungang Asia "],[" 갑오 경장 "," Kabo Kyŏngjang "],[" 동 아시아 "," Tong Asia "],[" 러일 전쟁 "," Rŏ-Il Chŏnjaeng "],[" 병자 호란 "," Pyŏngja Horan "],[" 서 아시아 "," Sŏ Asia "],[" 아관 파천 "," Agwan P'ach'ŏn "],[" 을미 사변 "," Ŭlmi Sabyŏn "],[" 임오 군란 "," Imo Kullan "],[" 임진 왜란 "," Imjin Waeran "],[" 정유 재란 "," Chŏngyu Chaeran "],[" 청일 전쟁 "," Ch'ŏng-Il Chŏnjaeng "],[" 남 유럽 "," Nam Yurŏp "],[" 동 유럽 "," Tong Yurŏp "],[" 북 유럽 "," Puk Yurŏp "],[" 서 유럽 "," Sŏ Yurŏp "]]
   For $i = 0 To Ubound($RuleDivPN, 1) - 1
	 $RawClip = StringRegExpReplace($RawClip,$RuleDivPN[$i][0],$RuleDivPN[$i][1])
   Next

   ; FKR040
   Local $RuleHyphenPN[23][2] = [[" 남북조 "," Nam-Pukcho "],[" 남북한 "," Nam-Pukhan "],[" 동서양 "," Tong-Sŏyang "],[" 나당 "," Na-Tang "],[" 노일 "," No-Il "],[" 당송 "," Tang-Song "],[" 러일 "," Rŏ-Il "],[" 명청 "," Myŏng-Ch'ŏng "],[" 미일 "," Mi-Il "],[" 영미 "," Yŏng-Mi "],[" 영프 "," Yŏng-P'ŭ "],[" 영한 "," Yŏng-Han "],[" 위진 "," Wi-Chin "],[" 중일 "," Chung-Il "],[" 중한 "," Chung-Han "],[" 청일 "," Ch'ŏng-Il "],[" 한독 "," Han-Tok "],[" 한미 "," Han-Mi "],[" 한불 "," Han-Pul "],[" 한영 "," Han-Yŏng "],[" 한일 "," Han-Il "],[" 한중일 "," Han-Chung-Il "],[" 한중 "," Han-Chung "]]
   For $i = 0 To Ubound($RuleHyphenPN, 1) - 1
	 $RawClip = StringRegExpReplace($RawClip,$RuleHyphenPN[$i][0],$RuleHyphenPN[$i][1])
   Next

   ;FKR041
   Local $RuleGN[19][2] = [[" ㄱ "," 기역 "],[" ㄲ "," 쌍기역 "],[" ㄴ "," 니은 "],[" ㄷ "," 디귿 "],[" ㄸ "," 쌍디귿 "],[" ㄹ "," riŭl "],[" ㅁ "," 미음 "],[" ㅂ "," 비읍 "],[" ㅃ "," 쌍비읍 "],[" ㅅ "," 시옷 "],[" ㅆ "," 쌍시옷 "],[" ㅇ "," 이응 "],[" ㅈ "," 지읒 "],[" ㅉ "," 쌍지읒 "],[" ㅊ "," 치읓 "],[" ㅋ "," 키읔 "],[" ㅌ "," 티읕 "],[" ㅍ "," 피읖 "],[" ㅎ "," 히읗 "]]
   For $i = 0 To Ubound($RuleGN, 1) - 1
	 $RawClip = StringRegExpReplace($RawClip,$RuleGN[$i][0],$RuleGN[$i][1])
   Next

   $Input = StringReplace($RawClip,@CR," ")
   $Input = StringReplace($Input,@LF," ")
   ClipPut($Input)

   If $TrayTip="ON" Then
	  TrayTip($TT_Title1,$TT_Text4,15)
   EndIf
   RomanizerOCLCAuto()
   $Output = ClipGet()

   ;FKR042
   If $CapitalizeAll = "On" Then
	  CapitalizeAll()
	  $Output = StringStripWS(ClipGet(),1+4)
   EndIf
  ;FKR043
   If $Capitalize = "On" Then
	  If StringLeft($Output,3)="ǂa " OR StringLeft($Output,3)="‡a " Then
		 $Output = StringLeft($Output,3) & StringUpper(StringMid($Output,4,1)) & StringTrimLeft($Output,4)
	  Else
		 $Output = StringUpper(StringLeft($Output,1)) & StringTrimLeft($Output,1)
	  EndIf
	  ClipPut(StringStripWS($Output,1+4))
   EndIf

; FKR044
   $OutputAmbi = StringReplace($Output,","," ")
   $OutputAmbi = StringReplace($OutputAmbi,"."," ")
   $OutputAmbi = StringReplace($OutputAmbi,'"'," ")
   $OutputAmbi = StringReplace($OutputAmbi,";"," ")
   $OutputAmbi = StringReplace($OutputAmbi,":"," ")
   $OutputAmbi = StringReplace($OutputAmbi,"  "," ")
   $OutputAmbi = " " & $OutPutAmbi & " "

   Opt("WinTitleMatchMode", 1)
   If WinActive("Voyager Cataloging") Then
	  $NoOCLCBreve = "On"
   Else
	  $NoOCLCBreve = "Off"
   EndIf

   If $NoOCLCBreve = "On" Then
	  Local $OCLCBreve[4][2] = [["ŏ","ŏ"],["ŭ","ŭ"],["Ŏ","Ŏ"],["Ŭ","Ŭ"]]
	  For $i = 0 To Ubound($OCLCBreve, 1) - 1
		 $Output = StringRegExpReplace($Output, "\Q" & $OCLCBreve[$i][0] & "\E",$OCLCBreve[$i][1])
	  Next
	  ClipPut($OutPut)
   EndIf

_PasteEx()

If $TrayTip="ON" Then

; FKR045
$STT = "0"

If StringInStr($OutputAmbi," Kyŏnggi ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & $OutputAmbi
EndIf
If StringInStr($OutputAmbi," Kyŏngsang ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• kyŏngsang, IF 경상 is NOT :慶尙 (Province)" & @LF
EndIf
If StringInStr($OutputAmbi," Kyŏngju ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• kyŏngju, IF 경주 is NOT :慶州 (City)" & @LF
EndIf
If StringInStr($OutputAmbi," Koryŏ ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• koryŏ, IF 고려 is NOT :高麗 (Country)" & @LF
EndIf
If StringInStr($OutputAmbi," lidŏ ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• ridŏ, IF 리더 is : reader" & @LF
EndIf
If StringInStr($OutputAmbi," lingk'ŭ ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• ringk'ŭ, IF 링크 is : rink" & @LF
EndIf
If StringInStr($OutputAmbi," sŏnjo ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• Sŏnjo, IF 선조 is NOT :宣祖 (King of Korea)" & @LF
EndIf
If StringInStr($OutputAmbi," sudan ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• Sudan, IF 수단 is : Sudan (Country)" & @LF
EndIf
If StringInStr($OutputAmbi," sunjong ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• Sunjong, IF 순종 is : 純宗 (King of Korea)" & @LF
EndIf
If StringInStr($OutputAmbi," anda ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• anta, IF 안다 is : to embrace" & @LF
EndIf
If StringInStr($OutputAmbi," Yŏsu ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• yŏsu, IF 여수 is NOT :麗水 (City)" & @LF
EndIf
If StringInStr($OutputAmbi," oman ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• Oman, IF 오만 is : Oman (Country)" & @LF
EndIf
If StringInStr($OutputAmbi," iran ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• Iran, IF 이란 is : Iran (Country)" & @LF
EndIf
If StringInStr($OutputAmbi," indo ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• Indo, IF 인도 is : India (Country)" & @LF
EndIf
If StringInStr($OutputAmbi," Injo ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• injo, IF 인조 is NOT :仁祖 (King of Korea)" & @LF
EndIf
If StringInStr($OutputAmbi," chamjari ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• chamchari, IF 잠자리 is : bed" & @LF
EndIf
If StringInStr($OutputAmbi," Chŏlla ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• chŏlla, IF 전라 is NOT :全羅 (Province)" & @LF
EndIf
If StringInStr($OutputAmbi," Chŏnju ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• chŏnju, IF 전주 is NOT :全州 (City)" & @LF
EndIf
If StringInStr($OutputAmbi," Cheju ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• cheju, IF 제주 is NOT :濟州 (Province)" & @LF
EndIf
If StringInStr($OutputAmbi," Chejudo ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• Cheju-do, IF 제주도 is : 濟州道 (Province)" & @LF
EndIf
If StringInStr($OutputAmbi," Chosŏn ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• chosŏn, IF 조선 is NOT :朝鮮 (Country)" & @LF
EndIf
If StringInStr($OutputAmbi," ch'ŏngsalli ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• Ch'ŏngsan-ni, IF 청산리 is : 靑山里" & @LF
EndIf
If StringInStr($OutputAmbi," P'yŏngan ")>$STT Then
 $Ambig = "Yes"
 $AmbigExp = $AmbigExp & @LF & "• p'yŏngan, IF 평안 is NOT :平安 (Province)" & @LF
EndIf

; FKR046
Sleep(50+300)

   If StringLen($AmbigExp)>240 Then
	  $AmbigExp = StringLeft($AmbigExp,StringInStr($AmbigExp,"•",0,-1)-1) & "... and more."
   EndIf

   If $Ambig="Yes" Then
	  Sleep(50+50)
	  TrayTip("CONSIDER",$AmbigExp,30,2)
   Else
	  If StringInStr($Output," ",0,4)=0 Then
		 Sleep(50+50)
		 $TrayTipText = @LF & $OriginalText & " = " & $Output
	  Else
		 Sleep(50+50)
		 $TrayTipText = $TT_Text3
	  EndIf
	  Sleep(50+50)
	  TrayTip($TT_Title3,$TrayTipText,10,1)
   EndIf
EndIf
EndFunc

Func OneSylKorRom()
   $TargetKor = ClipGet()
   If StringLen($TargetKor) = 2 Then
	  Local $TwoCharacters[8][2] = [["남궁","Namgung"],["제갈","Chegal"],["황보","Hwangbo"],["선우","Sŏnu"],["서문","Sŏmun"],["동방","Tongbang"],["독고","Tokko"],["사공","Sagong"]]
	  For $i = 0 To Ubound($TwoCharacters, 1) - 1
	  $TargetKor = StringRegExpReplace($TargetKor, "\Q" & $TwoCharacters[$i][0] & "\E",$TwoCharacters[$i][1])
	  Next
	  $Rom = $TargetKor
   Else
	  Local $aArray = StringToASCIIArray ($TargetKor)
	  $ASCII1 = Number($aArray[0])-44032
	  $Target = $ASCII1
	  $Ini1 = "i" & FLOOR(Number($Target)/588)
	  $Med1 = "m" & MOD(FLOOR(Number($Target)/28),21)
	  $Fin1 = "f" & MOD(Number($Target),28)
	  $Rom = $Ini1 & $Med1 & $Fin1
	  Local $Initials[19][2] = [["i10","ss"],["i11",""],["i12","ch"],["i13","tch"],["i14","ch'"],["i15","k'"],["i16","t'"],["i17","p'"],["i18","h"],["i0","k"],["i1","kk"],["i2","n"],["i3","t"],["i4","tt"],["i5","r"],["i6","m"],["i7","p"],["i8","pp"],["i9","s"]]
	  For $i = 0 To Ubound($Initials, 1) - 1
		 $Rom = StringRegExpReplace($Rom, "\Q" & $Initials[$i][0] & "\E",$Initials[$i][1])
	  Next
	  Local $Medials[22][2] = [["m10","wae"],["m11","oe"],["m12","yo"],["m13","u"],["m14","wŏ"],["m15","we"],["m16","wi"],["m17","yu"],["m18","ŭ"],["m19","ŭi"],["m20","i"],["m0","a"],["m1","ae"],["m2","ya"],["m3","yae"],["m4","ŏ"],["m5","e"],["m6","yŏ"],["m7","ye"],["m8","o"],["m9","wa"],["f0E","f0"]]
	  For $i = 0 To Ubound($Medials, 1) - 1
		 $Rom = StringRegExpReplace($Rom, "\Q" & $Medials[$i][0] & "\E",$Medials[$i][1])
	  Next
	  Local $Finals[8][2] = [["f16","m"],["f17","p"],["f21","ng"],["f1","k"],["f4","n"],["f7","t"],["f8","l"],["f0",""]]
	  For $i = 0 To Ubound($Finals, 1) - 1
		 $Rom = StringRegExpReplace($Rom, "\Q" & $Finals[$i][0] & "\E",$Finals[$i][1])
	  Next
	  ;FKR047
	  $Rom1 = StringTrimRight($Rom,StringLen($Rom)-1)
	  $Rom2 = StringTrimLeft($Rom,1)
	  $Rom = StringUpper($Rom1) & $Rom2
   EndIf

   ; FKR048
   If StringInStr($Rom,"Ry")=1 Then
	  $Rom = StringReplace($Rom,"Ry","Y")
   EndIf

   ClipPut($Rom)

EndFunc

Func RomanizerOCLCAuto() ; FKR049
   $NClipB = " " & ClipGet()

$CountSymb=49
;FKR050
   Local $Rule[$CountSymb][2] = [[' ! ',' SB01KQ '],[' " ',' SB02KQ '],[' # ',' SB03KQ '],[' $ ',' SB04KQ '],[' % ',' SB05KQ '],[' & ',' SB06KQ '],[" ' ",' SB07KQ '],[' ( ',' SB08KQ '],[' ) ',' SB09KQ '],[' * ',' SB10KQ '],[' + ',' SB11KQ '],[' , ',' SB12KQ '],[' - ',' SB13KQ '],[' . ',' SB14KQ '],[' / ',' SB15KQ '],[' : ',' SB16KQ '],[' ; ',' SB17KQ '],[' < ',' SB18KQ '],[' = ',' SB19KQ '],[' > ',' SB20KQ '],[' ? ',' SB21KQ '],[' ・ ',' SB22KQ '],[' ǂ ',' SB23KQ '],[' 「 ',' SB24KQ '],[' 」 ',' SB25KQ '],[' 『 ',' SB26KQ '],[' 』 ',' SB27KQ '],[' @ ',' SB28KQ '],[' [ ',' SB29KQ '],[' \ ',' SB30KQ '],[' ] ',' SB31KQ '],[' ^ ',' SB32KQ '],[' _ ',' SB33KQ '],[' ` ',' SB34KQ '],[' { ',' SB35KQ '],[' | ',' SB36KQ '],[' } ',' SB37KQ '],[' ~ ',' SB38KQ '],[' ‡ ',' SB39KQ '],[' ‰  ',' SB40KQ '],[' ‘ ',' SB41KQ '],[' ’ ',' SB42KQ '],[' “ ',' SB43KQ '],[' ” ',' SB44KQ '],[' – ',' SB45KQ '],[' — ',' SB46KQ '],[' ˜ ',' SB47KQ '],[' © ',' SB48KQ '],[' · ',' SB49KQ ']]
   For $i = 0 To Ubound($Rule, 1) - 1
	  $NClipB = StringRegExpReplace($NClipB, "\Q" & $Rule[$i][0] & "\E",$Rule[$i][1])
   Next
   Local $Rule[$CountSymb][2] = [[' !',' SB01CQ '],[' "',' SB02CQ '],[' #',' SB03CQ '],[' $',' SB04CQ '],[' %',' SB05CQ '],[' &',' SB06CQ '],[" '",' SB07CQ '],[' (',' SB08CQ '],[' )',' SB09CQ '],[' *',' SB10CQ '],[' +',' SB11CQ '],[' ,',' SB12CQ '],[' -',' SB13CQ '],[' .',' SB14CQ '],[' /',' SB15CQ '],[' :',' SB16CQ '],[' ;',' SB17CQ '],[' <',' SB18CQ '],[' =',' SB19CQ '],[' >',' SB20CQ '],[' ?',' SB21CQ '],[' ・',' SB22CQ '],[' ǂ',' SB23CQ '],[' 「',' SB24CQ '],[' 」',' SB25CQ '],[' 『',' SB26CQ '],[' 』',' SB27CQ '],[' @',' SB28CQ '],[' [',' SB29CQ '],[' \',' SB30CQ '],[' ]',' SB31CQ '],[' ^',' SB32CQ '],[' _',' SB33CQ '],[' `',' SB34CQ '],[' {',' SB35CQ '],[' |',' SB36CQ '],[' }',' SB37CQ '],[' ~',' SB38CQ '],[' ‡',' SB39CQ '],[' ‰ ',' SB40CQ '],[' ‘',' SB41CQ '],[' ’',' SB42CQ '],[' “',' SB43CQ '],[' ”',' SB44CQ '],[' –',' SB45CQ '],[' —',' SB46CQ '],[' ˜',' SB47CQ '],[' ©',' SB48CQ '],[' ·',' SB49CQ ']]
   For $i = 0 To Ubound($Rule, 1) - 1
	  $NClipB = StringRegExpReplace($NClipB, "\Q" & $Rule[$i][0] & "\E",$Rule[$i][1])
   Next
   Local $Rule[$CountSymb][2] = [['! ',' SB01TQ '],['" ',' SB02TQ '],['# ',' SB03TQ '],['$ ',' SB04TQ '],['% ',' SB05TQ '],['& ',' SB06TQ '],["' ",' SB07TQ '],['( ',' SB08TQ '],[') ',' SB09TQ '],['* ',' SB10TQ '],['+ ',' SB11TQ '],[', ',' SB12TQ '],['- ',' SB13TQ '],['. ',' SB14TQ '],['/ ',' SB15TQ '],[': ',' SB16TQ '],['; ',' SB17TQ '],['< ',' SB18TQ '],['= ',' SB19TQ '],['> ',' SB20TQ '],['? ',' SB21TQ '],['・ ',' SB22TQ '],['ǂ ',' SB23TQ '],['「 ',' SB24TQ '],['」 ',' SB25TQ '],['『 ',' SB26TQ '],['』 ',' SB27TQ '],['@ ',' SB28TQ '],['[ ',' SB29TQ '],['\ ',' SB30TQ '],['] ',' SB31TQ '],['^ ',' SB32TQ '],['_ ',' SB33TQ '],['` ',' SB34TQ '],['{ ',' SB35TQ '],['| ',' SB36TQ '],['} ',' SB37TQ '],['~ ',' SB38TQ '],['‡ ',' SB39TQ '],['‰  ',' SB40TQ '],['‘ ',' SB41TQ '],['’ ',' SB42TQ '],['“ ',' SB43TQ '],['” ',' SB44TQ '],['– ',' SB45TQ '],['— ',' SB46TQ '],['˜ ',' SB47TQ '],['© ',' SB48TQ '],['· ',' SB49TQ ']]
   For $i = 0 To Ubound($Rule, 1) - 1
	  $NClipB = StringRegExpReplace($NClipB, "\Q" & $Rule[$i][0] & "\E",$Rule[$i][1])
   Next
   Local $Rule[$CountSymb][2] = [['!',' SB01PQ '],['"',' SB02PQ '],['#',' SB03PQ '],['$',' SB04PQ '],['%',' SB05PQ '],['&',' SB06PQ '],["'",' SB07PQ '],['(',' SB08PQ '],[')',' SB09PQ '],['*',' SB10PQ '],['+',' SB11PQ '],[',',' SB12PQ '],['-',' SB13PQ '],['.',' SB14PQ '],['/',' SB15PQ '],[':',' SB16PQ '],[';',' SB17PQ '],['<',' SB18PQ '],['=',' SB19PQ '],['>',' SB20PQ '],['?',' SB21PQ '],['・',' SB22PQ '],['ǂ',' SB23PQ '],['「',' SB24PQ '],['」',' SB25PQ '],['『',' SB26PQ '],['』',' SB27PQ '],['@',' SB28PQ '],['[',' SB29PQ '],['\',' SB30PQ '],[']',' SB31PQ '],['^',' SB32PQ '],['_',' SB33PQ '],['`',' SB34PQ '],['{',' SB35PQ '],['|',' SB36PQ '],['}',' SB37PQ '],['~',' SB38PQ '],['‡',' SB39PQ '],['‰ ',' SB40PQ '],['‘',' SB41PQ '],['’',' SB42PQ '],['“',' SB43PQ '],['”',' SB44PQ '],['–',' SB45PQ '],['—',' SB46PQ '],['˜',' SB47PQ '],['©',' SB48PQ '],['·',' SB49PQ ']]
   For $i = 0 To Ubound($Rule, 1) - 1
	  $NClipB = StringRegExpReplace($NClipB, "\Q" & $Rule[$i][0] & "\E",$Rule[$i][1])
   Next
;FKR051

;FKR052
   If StringRegExp($NClipB," 제[0-9]") Then
	  $NClipB = StringReplace($NClipB," 제"," 제 ")
   EndIf

$NClipB = " " & $NClipB

Local $RuleNu[360][2] = [[' 무의식역 ',' 무의식+역 '],[' 신연활자 ',' 신+연활^자 '],[' 신도림역 ',' 신도림+역 '],[' 옛이야기 ',' 옛+이야기 '],[' 지하철역 ',' 지하철+역 '],[' 짓이기다 ',' 짓+이기다 '],[' 한여름밤 ',' 한+여름^밤 '],[' 가공육 ',' 가공+육 '],[' 가락엿 ',' 가락+엿 '],[' 가랑잎 ',' 가랑+잎 '],[' 각막염 ',' 각막+염 '],[' 갈댓잎 ',' 갈댓+잎 '],[' 감각역 ',' 감각+역 '],[' 감람유 ',' 감람+유 '],[' 강관론 ',' 강관+론 '],[' 강신론 ',' 강신+론 '],[' 강연료 ',' 강연+료 '],[' 개선론 ',' 개선+론 '],[' 개연론 ',' 개연+론 '],[' 개편론 ',' 개편+론 '],[' 건축용 ',' 건축+용 '],[' 견문록 ',' 견문+록 '],[' 견인력 ',' 견인+력 '],[' 결단력 ',' 결^단+력 '],[' 결막염 ',' 결막+염 '],[' 경산역 ',' 경산+역 '],[' 경신록 ',' 경신+록 '],[' 계산력 ',' 계산+력 '],[' 계선료 ',' 계선+료 '],[' 고막염 ',' 고막+염 '],[' 고문역 ',' 고문+역 '],[' 고신록 ',' 고신+록 '],[' 고춧잎 ',' 고춧+잎 '],[' 골연령 ',' 골+연령 '],[' 공권력 ',' 공^권+력 '],[' 공염불 ',' 공+염불 '],[' 공간론 ',' 공간+론 '],[' 공격용 ',' 공격+용 '],[' 공군력 ',' 공군+력 '],[' 공면력 ',' 공면+력 '],[' 공신력 ',' 공신+력 '],[' 공신록 ',' 공신+록 '],[' 공업용 ',' 공업+용 '],[' 공연료 ',' 공연+료 '],[' 광명역 ',' 광명+역 '],[' 교육열 ',' 교육+열 '],[' 교육용 ',' 교육+용 '],[' 교환력 ',' 교환+력 '],[' 교환율 ',' 교환+율 '],[' 구문론 ',' 구문+론 '],[' 구원론 ',' 구원+론 '],[' 구인록 ',' 구인+록 '],[' 구전론 ',' 구전+론 '],[' 국민역 ',' 국민+역 '],[' 굴신력 ',' 굴신+력 '],[' 궁원록 ',' 궁원+록 '],[' 궤변론 ',' 궤변+론 '],[' 규한록 ',' 규한+록 '],[' 균전론 ',' 균전+론 '],[' 극단론 ',' 극단+론 '],[' 근육염 ',' 근육+염 '],[' 기본론 ',' 기본+론 '],[' 기신론 ',' 기신+론 '],[' 기준량 ',' 기준+량 '],[' 기준율 ',' 기준+율 '],[' 기판력 ',' 기판+력 '],[' 나뭇잎 ',' 나뭇+잎 '],[' 낙관론 ',' 낙관+론 '],[' 남영역 ',' 남영+역 '],[' 뇌막염 ',' 뇌막+염 '],[' 누진율 ',' 누진+율 '],[' 눈요기 ',' 눈+요기 '],[' 늑막염 ',' 늑막+염 '],[' 늦여름 ',' 늦+여름 '],[' 다신론 ',' 다신+론 '],[' 다원론 ',' 다원+론 '],[' 단원론 ',' 단원+론 '],[' 단풍잎 ',' 단풍+잎 '],[' 담뱃잎 ',' 담뱃+잎 '],[' 대장염 ',' 대장+염 '],[' 대전료 ',' 대전+료 '],[' 대전역 ',' 대전+역 '],[' 더블유 ',' 더블+유 '],[' 도선료 ',' 도선+료 '],[' 도착역 ',' 도착+역 '],[' 독단론 ',' 독단+론 '],[' 돌진력 ',' 돌^진+력 '],[' 동역학 ',' 동+역학 '],[' 동권론 ',' 동권+론 '],[' 동원력 ',' 동원+력 '],[' 동원령 ',' 동원+령 '],[' 두문령 ',' 두문+령 '],[' 떡갈잎 ',' 떡갈+잎 '],[' 마늘잎 ',' 마늘+잎 '],[' 마산역 ',' 마산+역 '],[' 망막염 ',' 망막+염 '],[' 명분론 ',' 명분+론 '],[' 명신록 ',' 명신+록 '],[' 모순론 ',' 모순+론 '],[' 무신론 ',' 무신+론 '],[' 무원록 ',' 무원+록 '],[' 무인론 ',' 무인+론 '],[' 문단론 ',' 문단+론 '],[' 문학열 ',' 문학+열 '],[' 민권론 ',' 민^권+론 '],[' 밀양역 ',' 밀양+역 '],[' 바늘잎 ',' 바늘+잎 '],[' 박진력 ',' 박진+력 '],[' 반신료 ',' 반신+료 '],[' 반전론 ',' 반전+론 '],[' 발권력 ',' 발^권+력 '],[' 발전량 ',' 발^전+량 '],[' 발전력 ',' 발^전+력 '],[' 발언록 ',' 발언+록 '],[' 방문록 ',' 방문+록 '],[' 방언량 ',' 방언+량 '],[' 방편력 ',' 방편+력 '],[' 방한력 ',' 방한+력 '],[' 밭이랑 ',' 밭+이랑 '],[' 배근력 ',' 배근+력 '],[' 백분율 ',' 백^분+율 '],[' 버들잎 ',' 버들+잎 '],[' 범신론 ',' 범신+론 '],[' 법선력 ',' 법선+력 '],[' 변신론 ',' 변신+론 '],[' 병인론 ',' 병인+론 '],[' 보관료 ',' 보관+료 '],[' 보온력 ',' 보온+력 '],[' 보존력 ',' 보존+력 '],[' 보존료 ',' 보존+료 '],[' 보편론 ',' 보편+론 '],[' 복막염 ',' 복막+염 '],[' 복원력 ',' 복원+력 '],[' 본원력 ',' 본원+력 '],[' 부산역 ',' 부산+역 '],[' 부원록 ',' 부원+록 '],[' 부인론 ',' 부인+론 '],[' 불문율 ',' 불문+율 '],[' 불변량 ',' 불변+량 '],[' 불신론 ',' 불신+론 '],[' 비관론 ',' 비관+론 '],[' 비늘잎 ',' 비늘+잎 '],[' 비전론 ',' 비전+론 '],[' 비판력 ',' 비판+력 '],[' 사변록 ',' 사변+록 '],[' 사분력 ',' 사분+력 '],[' 산업용 ',' 산업+용 '],[' 산욕열 ',' 산욕+열 '],[' 살균력 ',' 살균+력 '],[' 삼성역 ',' 삼성+역 '],[' 삼신론 ',' 삼신+론 '],[' 삼전론 ',' 삼전+론 '],[' 상견례 ',' 상견+례 '],[' 상담역 ',' 상담+역 '],[' 상연료 ',' 상연+료 '],[' 상한론 ',' 상한+론 '],[' 색연필 ',' 색+연필 '],[' 생산량 ',' 생산+량 '],[' 생산력 ',' 생산+력 '],[' 서울역 ',' 서울+역 '],[' 서원력 ',' 서원+력 '],[' 선견력 ',' 선견+력 '],[' 선언령 ',' 선언+령 '],[' 선원록 ',' 선원+록 '],[' 선천론 ',' 선천+론 '],[' 성문율 ',' 성문+율 '],[' 성분력 ',' 성분+력 '],[' 세균론 ',' 세균+론 '],[' 속단론 ',' 속단+론 '],[' 수막염 ',' 수막+염 '],[' 수원역 ',' 수원+역 '],[' 순간력 ',' 순간+력 '],[' 순환론 ',' 순환+론 '],[' 시인론 ',' 시인+론 '],[' 식용유 ',' 식용+유 '],[' 신여성 ',' 신+여성 '],[' 신인론 ',' 신인+론 '],[' 실천력 ',' 실천+력 '],[' 실천론 ',' 실천+론 '],[' 안양역 ',' 안양+역 '],[' 알선료 ',' 알선+료 '],[' 압축열 ',' 압축+열 '],[' 어원론 ',' 어원+론 '],[' 여전론 ',' 여전+론 '],[' 연꽃잎 ',' 연꽃+잎 '],[' 연습용 ',' 연습+용 '],[' 열역학 ',' 열+역학 '],[' 염분량 ',' 염분+량 '],[' 영동역 ',' 영동+역 '],[' 영문록 ',' 영문+록 '],[' 영업용 ',' 영업+용 '],[' 예찬론 ',' 예찬+론 '],[' 옛이응 ',' 옛+이응 '],[' 오동잎 ',' 오동+잎 '],[' 올여름 ',' 올+여름 '],[' 외연량 ',' 외연+량 '],[' 용단력 ',' 용단+력 '],[' 용산역 ',' 용산+역 '],[' 용선료 ',' 용선+료 '],[' 우연론 ',' 우연+론 '],[' 우인론 ',' 우인+론 '],[' 우편료 ',' 우편+료 '],[' 운반력 ',' 운반+력 '],[' 원동력 ',' 원동+력 '],[' 윗입몸 ',' 윗+입몸 '],[' 윗입술 ',' 윗+입술 '],[' 유신론 ',' 유신+론 '],[' 은행잎 ',' 은행+잎 '] _
,[' 음식용 ',' 음식+용 '],[' 음운론 ',' 음운+론 '],[' 응축열 ',' 응축+열 '],[' 의견란 ',' 의견+란 '],[' 의식역 ',' 의식+역 '],[' 이신론 ',' 이신+론 '],[' 이원론 ',' 이원+론 '],[' 인간력 ',' 인간+력 '],[' 인간론 ',' 인간+론 '],[' 인순론 ',' 인순+론 '],[' 일일이 ',' 일+일이 '],[' 일반론 ',' 일반+론 '],[' 일산량 ',' 일산+량 '],[' 일신론 ',' 일신+론 '],[' 일원론 ',' 일원+론 '],[' 임진란 ',' 임진+란 '],[' 임진록 ',' 임진+록 '],[' 입원료 ',' 입원+료 '],[' 자본력 ',' 자본+력 '],[' 자본론 ',' 자본+론 '],[' 자신력 ',' 자신+력 '],[' 자연력 ',' 자연+력 '],[' 자연론 ',' 자연+론 '],[' 잔존력 ',' 잔존+력 '],[' 전단력 ',' 전단+력 '],[' 전신료 ',' 전신+료 '],[' 전철역 ',' 전철+역 '],[' 정맥염 ',' 정맥+염 '],[' 정신력 ',' 정신+력 '],[' 정신론 ',' 정신+론 '],[' 정진력 ',' 정진+력 '],[' 정한론 ',' 정한+론 '],[' 조문록 ',' 조문+록 '],[' 조성용 ',' 조성+용 '],[' 조천록 ',' 조천+록 '],[' 종착역 ',' 종착+역 '],[' 주권론 ',' 주^권+론 '],[' 주선력 ',' 주선+력 '],[' 주선료 ',' 주선+료 '],[' 주전론 ',' 주전+론 '],[' 중관론 ',' 중관+론 '],[' 중앙역 ',' 중앙+역 '],[' 증언록 ',' 증언+록 '],[' 지원록 ',' 지원+록 '],[' 지진력 ',' 지진+력 '],[' 직관력 ',' 직관+력 '],[' 직원록 ',' 직원+록 '],[' 진신록 ',' 진신+록 '],[' 차원론 ',' 차원+론 '],[' 창원역 ',' 창원+역 '],[' 창작열 ',' 창작+열 '],[' 채탄량 ',' 채탄+량 '],[' 처분령 ',' 처분+령 '],[' 천안역 ',' 천안+역 '],[' 천연론 ',' 천연+론 '],[' 첫여름 ',' 첫+여름 '],[' 첫이레 ',' 첫+이레 '],[' 체선료 ',' 체선+료 '],[' 총연습 ',' 총+연습 '],[' 총연장 ',' 총+연장 '],[' 총연합 ',' 총+연합 '],[' 추진력 ',' 추진+력 '],[' 축전량 ',' 축전+량 '],[' 출발역 ',' 출발+역 '],[' 출산력 ',' 출산+력 '],[' 출산율 ',' 출산+율 '],[' 출연료 ',' 출연+료 '],[' 치안력 ',' 치안+력 '],[' 퇴군령 ',' 퇴군+령 '],[' 퇴적열 ',' 퇴적+열 '],[' 투신력 ',' 투신+력 '],[' 판단력 ',' 판단+력 '],[' 판막염 ',' 판막+염 '],[' 평균량 ',' 평균+량 '],[' 평균율 ',' 평균+율 '],[' 평택역 ',' 평택+역 '],[' 표면력 ',' 표면+력 '],[' 표준량 ',' 표준+량 '],[' 표현력 ',' 표현+력 '],[' 필연론 ',' 필연+론 '],[' 학문론 ',' 학문+론 '],[' 학생용 ',' 학생+용 '],[' 학습용 ',' 학습+용 '],[' 학안록 ',' 학안+록 '],[' 한여름 ',' 한+여름 '],[' 한전론 ',' 한전+론 '],[' 할인료 ',' 할인+료 '],[' 할인율 ',' 할인+율 '],[' 항만료 ',' 항만+료 '],[' 핵연료 ',' 핵+연료 '],[' 행군령 ',' 행군+령 '],[' 행동력 ',' 행동+력 '],[' 향산록 ',' 향산+록 '],[' 향신료 ',' 향신+료 '],[' 향학열 ',' 향학+열 '],[' 헛열매 ',' 헛+열매 '],[' 헛이름 ',' 헛+이름 '],[' 혁신론 ',' 혁신+론 '],[' 현존량 ',' 현존+량 '],[' 호박엿 ',' 호박+엿 '],[' 호박잎 ',' 호박+잎 '],[' 홍문록 ',' 홍문+록 '],[' 홑이불 ',' 홑+이불 '],[' 화문록 ',' 화문+록 '],[' 화물역 ',' 화물+역 '],[' 환승역 ',' 환승+역 '],[' 회군령 ',' 회군+령 '],[' 회신료 ',' 회신+료 '],[' 회전율 ',' 회전+율 '],[' 후천론 ',' 후천+론 '],[' 휘발유 ',' 휘발+유 '],[' 흥신록 ',' 흥신+록 '],[' 희생양 ',' 희생+양 '],[' 갈잎 ',' 갈+잎 '],[' 감잎 ',' 감+잎 '],[' 겹잎 ',' 겹+잎 '],[' 귤잎 ',' 귤+잎 '],[' 깻잎 ',' 깻+잎 '],[' 꽃잎 ',' 꽃+잎 '],[' 끝일 ',' 끝+일 '],[' 낯익 ',' 낯+익 '],[' 댓잎 ',' 댓+잎 '],[' 덧입 ',' 덧+입 '],[' 떡잎 ',' 떡+잎 '],[' 막일 ',' 막+일 '],[' 맨입 ',' 맨+입 '],[' 물약 ',' 물+약 '],[' 물엿 ',' 물+엿 '],[' 밭일 ',' 밭+일 '],[' 뽕잎 ',' 뽕+잎 '],[' 삯일 ',' 삯+일 '],[' 설익 ',' 설+익 '],[' 솔잎 ',' 솔+잎 '],[' 숫양 ',' 숫+양 '],[' 알약 ',' 알+약 '],[' 연잎 ',' 연+잎 '],[' 옛일 ',' 옛+일 '],[' 작열 ',' 작+열 '],[' 장염 ',' 장+염 '],[' 정열 ',' 정+열 '],[' 찻잎 ',' 찻+잎 '],[' 첫입 ',' 첫+입 '],[' 콩잎 ',' 콩+잎 '],[' 팥잎 ',' 팥+잎 '],[' 풀잎 ',' 풀+잎 '],[' 한입 ',' 한+입 '],[' 햇잎 ',' 햇+잎 '],[' 헛일 ',' 헛+일 '],[' 홑잎 ',' 홑+잎 '],[' 흙일 ',' 흙+일 '],[' 극예술 ',' 극+예술 '],[' 웬일 ',' 웬+일 ']]
   For $i = 0 To Ubound($RuleNu, 1) - 1
	 $NClipB = StringRegExpReplace($NClipB,$RuleNu[$i][0],$RuleNu[$i][1])
   Next

Local $RuleFortis[990][2] = [[' 이비인후과 ',' 이비인후^과 '],[' 걱정거리 ',' 걱정^거리 '],[' 고민거리 ',' 고민^거리 '],[' 관심거리 ',' 관심^거리 '],[' 구경거리 ',' 구경^거리 '],[' 근심거리 ',' 근심^거리 '],[' 금난전권 ',' 금난전^권 '],[' 김장거리 ',' 김장^거리 '],[' 논병아리 ',' 논^병아리 '],[' 놀림거리 ',' 놀림^거리 '],[' 농담거리 ',' 농담^거리 '],[' 농지거리 ',' 농지^거리 '],[' 뉴스거리 ',' 뉴스^거리 '],[' 말썽거리 ',' 말썽^거리 '],[' 망신거리 ',' 망신^거리 '],[' 먹을거리 ',' 먹을^거리 '],[' 바라밀다 ',' 바라밀^다 '],[' 반찬거리 ',' 반찬^거리 '],[' 비뇨기과 ',' 비뇨기^과 '],[' 산봉우리 ',' 산^봉우리 '],[' 산부인과 ',' 산부인^과 '],[' 상행위법 ',' 상행위^법 '],[' 소일거리 ',' 소일^거리 '],[' 아침거리 ',' 아침^거리 '],[' 양념거리 ',' 양념^거리 '],[' 웃음거리 ',' 웃음^거리 '],[' 위안거리 ',' 위안^거리 '],[' 이십일도 ',' 이십일^도 '],[' 읽을거리 ',' 읽을^거리 '],[' 자랑거리 ',' 자랑^거리 '],[' 잡담거리 ',' 잡담^거리 '],[' 점심거리 ',' 점심^거리 '],[' 조롱거리 ',' 조롱^거리 '],[' 지리산권 ',' 지리산^권 '],[' 가산점 ',' 가산^점 '],[' 가슴골 ',' 가슴^골 '],[' 가시권 ',' 가시^권 '],[' 가을밤 ',' 가을^밤 '],[' 가을비 ',' 가을^비 '],[' 가을빛 ',' 가을^빛 '],[' 가장권 ',' 가장^권 '],[' 가정법 ',' 가정^법 '],[' 가정집 ',' 가정^집 '],[' 가채점 ',' 가채^점 '],[' 간장국 ',' 간장^국 '],[' 간질병 ',' 간질^병 '],[' 갈지자 ',' 갈^지^자 '],[' 갈림길 ',' 갈림^길 '],[' 강줄기 ',' 강^줄기 '],[' 강남권 ',' 강남^권 '],[' 강원권 ',' 강원^권 '],[' 강제권 ',' 강제^권 '],[' 강철빛 ',' 강철^빛 '],[' 개울가 ',' 개울^가 '],[' 개장국 ',' 개장^국 '],[' 개최권 ',' 개최^권 '],[' 거래법 ',' 거래^법 '],[' 거부권 ',' 거부^권 '],[' 건망증 ',' 건망^증 '],[' 건설적 ',' 건설^적 '],[' 건조증 ',' 건조^증 '],[' 걸림돌 ',' 걸림^돌 '],[' 걸을게 ',' 걸을^게 '],[' 검찰권 ',' 검찰^권 '],[' 겨울밤 ',' 겨울^밤 '],[' 겨울비 ',' 겨울^비 '],[' 결승점 ',' 결승^점 '],[' 결의권 ',' 결의^권 '],[' 결재권 ',' 결재^권 '],[' 경계점 ',' 경계^점 '],[' 경남권 ',' 경남^권 '],[' 경영권 ',' 경영^권 '],[' 경영법 ',' 경영^법 '],[' 경쟁법 ',' 경쟁^법 '],[' 경제권 ',' 경제^권 '],[' 경찰권 ',' 경찰^권 '],[' 경품권 ',' 경품^권 '],[' 계절도 ',' 계절^도 '],[' 고대법 ',' 고대^법 '],[' 고동빛 ',' 고동^빛 '],[' 고밀도 ',' 고밀^도 '],[' 고산병 ',' 고산^병 '],[' 고생길 ',' 고생^길 '],[' 고유법 ',' 고유^법 '],[' 고질병 ',' 고질^병 '],[' 공산권 ',' 공산^권 '],[' 공소권 ',' 공소^권 '],[' 공수병 ',' 공수^병 '],[' 공연권 ',' 공연^권 '],[' 공연법 ',' 공연^법 '],[' 공유점 ',' 공유^점 '],[' 공주병 ',' 공주^병 '],[' 공중권 ',' 공중^권 '],[' 공통점 ',' 공통^점 '],[' 과세권 ',' 과세^권 '],[' 과장법 ',' 과장^법 '],[' 관동권 ',' 관동^권 '],[' 관리권 ',' 관리^권 '],[' 관리법 ',' 관리^법 '],[' 관서권 ',' 관서^권 '],[' 관찰도 ',' 관찰^도 '],[' 관찰점 ',' 관찰^점 '],[' 관할권 ',' 관할^권 '],[' 광산권 ',' 광산^권 '],[' 괴혈병 ',' 괴혈^병 '],[' 교차점 ',' 교차^점 '],[' 교통권 ',' 교통^권 '],[' 교통법 ',' 교통^법 '],[' 구두점 ',' 구두^점 '],[' 구들방 ',' 구들^방 '],[' 구심점 ',' 구심^점 '],[' 국내법 ',' 국내^법 '],[' 국문법 ',' 국문^법 '],[' 국제법 ',' 국제^법 '],[' 국회법 ',' 국회^법 '],[' 굴절도 ',' 굴절^도 '],[' 궁금증 ',' 궁금^증 '],[' 귀결점 ',' 귀결^점 '],[' 귀향길 ',' 귀향^길 '],[' 균전법 ',' 균전^법 '],[' 그믐달 ',' 그믐^달 '],[' 극대점 ',' 극대^점 '],[' 극소점 ',' 극소^점 '],[' 극장권 ',' 극장^권 '],[' 극한점 ',' 극한^점 '],[' 근일점 ',' 근일^점 '],[' 근지점 ',' 근지^점 '],[' 글거리 ',' 글^거리 '],[' 금가루 ',' 금^가루 '],[' 금덩이 ',' 금^덩이 '],[' 금융권 ',' 금융^권 '],[' 금융법 ',' 금융^법 '],[' 금지법 ',' 금지^법 '],[' 급성병 ',' 급성^병 '],[' 급제점 ',' 급제^점 '],[' 기름기 ',' 기름^기 '],[' 기름불 ',' 기름^불 '],[' 기본권 ',' 기본^권 '],[' 기본법 ',' 기본^법 '],[' 기술자 ',' 기술^자 '],[' 기술적 ',' 기술^적 '],[' 기준점 ',' 기준^점 '],[' 기후병 ',' 기후^병 '],[' 길거리 ',' 길^거리 '],[' 길동무 ',' 길^동무 '],[' 길바닥 ',' 길^바닥 '],[' 끊을게 ',' 끊을^게 '],[' 낙제점 ',' 낙제^점 '],[' 낙하점 ',' 낙하^점 '],[' 난치병 ',' 난치^병 '],[' 남부권 ',' 남부^권 '],[' 남산골 ',' 남산^골 '],[' 냉방병 ',' 냉방^병 '],[' 노동권 ',' 노동^권 '],[' 노동법 ',' 노동^법 '],[' 노출증 ',' 노출^증 '],[' 논바닥 ',' 논^바닥 '],[' 논쟁점 ',' 논쟁^점 '],[' 놋활자 ',' 놋활^자 '],[' 농사법 ',' 농사^법 '],[' 뇌졸중 ',' 뇌졸^중 '],[' 눈동자 ',' 눈^동자 '],[' 눈물점 ',' 눈물^점 '],[' 능률적 ',' 능률^적 '],[' 단결권 ',' 단결^권 '],[' 단골집 ',' 단골^집 '],[' 단월대 ',' 단월^대 '],[' 단칸방 ',' 단칸^방 '],[' 달덩이 ',' 달^덩이 '],[' 달동네 ',' 달^동네 '],[' 당뇨병 ',' 당뇨^병 '],[' 당선권 ',' 당선^권 '],[' 대기권 ',' 대기^권 '],[' 대류권 ',' 대류^권 '],[' 대응점 ',' 대응^점 '],[' 대장간 ',' 대장^간 '],[' 대칭점 ',' 대칭^점 '],[' 대표권 ',' 대표^권 '],[' 대행권 ',' 대행^권 '],[' 도달점 ',' 도달^점 '],[' 도산법 ',' 도산^법 '],[' 도치법 ',' 도치^법 '],[' 독점권 ',' 독점^권 '],[' 돌가루 ',' 돌^가루 '],[' 돌덩이 ',' 돌^덩이 '],[' 동구권 ',' 동구^권 '],[' 동물권 ',' 동물^권 '],[' 동부권 ',' 동부^권 '],[' 동일점 ',' 동일^점 '],[' 동포법 ',' 동포^법 '],[' 동활자 ',' 동활^자 '],[' 된장국 ',' 된장^국 '],[' 뒤발굽 ',' 뒤발^굽 '],[' 뒤안길 ',' 뒤안^길 '],[' 득실점 ',' 득실^점 '],[' 들장미 ',' 들^장미 '],[' 등산길 ',' 등산^길 '],[' 등잔불 ',' 등잔^불 '],[' 땅덩이 ',' 땅^덩이 '],[' 땅바닥 ',' 땅^바닥 '],[' 띄활자 ',' 띄활^자 '],[' 로마법 ',' 로마^법 '],[' 마구간 ',' 마구^간 '],[' 마취과 ',' 마취^과 '],[' 만월대 ',' 만월^대 '],[' 말동무 ',' 말^동무 '] _
,[' 말버릇 ',' 말^버릇 '],[' 말장난 ',' 말^장난 '],[' 말발굽 ',' 말발^굽 '],[' 망상증 ',' 망상^증 '],[' 맞춤법 ',' 맞춤^법 '],[' 맥주병 ',' 맥주^병 '],[' 면허증 ',' 면허^증 '],[' 명령권 ',' 명령^권 '],[' 목활자 ',' 목활^자 '],[' 몰골법 ',' 몰골^법 '],[' 몽유병 ',' 몽유^병 '],[' 무고죄 ',' 무고^죄 '],[' 무실점 ',' 무실^점 '],[' 무조건 ',' 무조^건 '],[' 묵비권 ',' 묵비^권 '],[' 문고리 ',' 문^고리 '],[' 문둥병 ',' 문둥^병 '],[' 문설주 ',' 문설^주 '],[' 문제점 ',' 문제^점 '],[' 문화권 ',' 문화^권 '],[' 물고기 ',' 물^고기 '],[' 물동이 ',' 물^동이 '],[' 물방울 ',' 물^방울 '],[' 미술적 ',' 미술^적 '],[' 밀가루 ',' 밀^가루 '],[' 바람결 ',' 바람^결 '],[' 박달재 ',' 박달^재 '],[' 반월도 ',' 반월^도 '],[' 반환점 ',' 반환^점 '],[' 발가락 ',' 발^가락 '],[' 발바닥 ',' 발^바닥 '],[' 발자국 ',' 발^자국 '],[' 발자취 ',' 발^자취 '],[' 발사점 ',' 발사^점 '],[' 발언권 ',' 발언^권 '],[' 발행권 ',' 발행^권 '],[' 발화점 ',' 발화^점 '],[' 밤거리 ',' 밤^거리 '],[' 방바닥 ',' 방^바닥 '],[' 방송권 ',' 방송^권 '],[' 방청권 ',' 방청^권 '],[' 배열도 ',' 배열^도 '],[' 백골단 ',' 백^골^단 '],[' 백골단 ',' 백골^단 '],[' 백혈병 ',' 백혈^병 '],[' 벌판길 ',' 벌판^길 '],[' 벼랑길 ',' 벼랑^길 '],[' 벼슬길 ',' 벼슬^길 '],[' 변증법 ',' 변증^법 '],[' 변호권 ',' 변호^권 '],[' 병리과 ',' 병리^과 '],[' 보건법 ',' 보건^법 '],[' 보길도 ',' 보길^도 '],[' 보름밤 ',' 보름^밤 '],[' 보험법 ',' 보험^법 '],[' 복제권 ',' 복제^권 '],[' 복지법 ',' 복지^법 '],[' 볼거리 ',' 볼^거리 '],[' 봄바람 ',' 봄^바람 '],[' 부동점 ',' 부동^점 '],[' 부인과 ',' 부인^과 '],[' 북부권 ',' 북부^권 '],[' 분기점 ',' 분기^점 '],[' 분열증 ',' 분열^증 '],[' 분포권 ',' 분포^권 '],[' 분홍빛 ',' 분홍^빛 '],[' 불덩이 ',' 불^덩이 '],[' 불감증 ',' 불감^증 '],[' 불면증 ',' 불면^증 '],[' 불임증 ',' 불임^증 '],[' 불치병 ',' 불치^병 '],[' 불환권 ',' 불환^권 '],[' 비단길 ',' 비단^길 '],[' 비유법 ',' 비유^법 '],[' 비탈길 ',' 비탈^길 '],[' 빈혈증 ',' 빈혈^증 '],[' 빙판길 ',' 빙판^길 '],[' 빵가루 ',' 빵^가루 '],[' 사용권 ',' 사용^권 '],[' 사용법 ',' 사용^법 '],[' 사절단 ',' 사절^단 '],[' 사주점 ',' 사주^점 '],[' 사진발 ',' 사진^발 '],[' 산기슭 ',' 산^기슭 '],[' 산더미 ',' 산^더미 '],[' 산동네 ',' 산^동네 '],[' 산짐승 ',' 산^짐승 '],[' 산술적 ',' 산술^적 '],[' 살덩이 ',' 살^덩이 '],[' 살림집 ',' 살림^집 '],[' 삼일절 ',' 삼일^절 '],[' 상사병 ',' 상사^병 '],[' 상위권 ',' 상위^권 '],[' 상이점 ',' 상이^점 '],[' 상팔담 ',' 상팔^담 '],[' 상표권 ',' 상표^권 '],[' 상표법 ',' 상표^법 '],[' 상품권 ',' 상품^권 '],[' 생명권 ',' 생명^권 '],[' 생명점 ',' 생명^점 '],[' 생살권 ',' 생살^권 '],[' 생선국 ',' 생선^국 '],[' 생장점 ',' 생장^점 '],[' 생존권 ',' 생존^권 '],[' 생활권 ',' 생활^권 '],[' 생활점 ',' 생활^점 '],[' 서구권 ',' 서구^권 '],[' 서부권 ',' 서부^권 '],[' 석양빛 ',' 석양^빛 '],[' 선거권 ',' 선거^권 '],[' 선두권 ',' 선두^권 '],[' 선수권 ',' 선수^권 '],[' 선취점 ',' 선취^점 '],[' 설중매 ',' 설^중매 '],[' 성냥불 ',' 성냥^불 '],[' 성인병 ',' 성인^병 '],[' 성장점 ',' 성장^점 '],[' 성층권 ',' 성층^권 '],[' 소금기 ',' 소금^기 '],[' 소설집 ',' 소설^집 '],[' 소송법 ',' 소송^법 '],[' 소수점 ',' 소수^점 '],[' 소아과 ',' 소아^과 '],[' 소아병 ',' 소아^병 '],[' 소유권 ',' 소유^권 '],[' 소주병 ',' 소주^병 '],[' 손가락 ',' 손^가락 '],[' 손바닥 ',' 손^바닥 '],[' 손버릇 ',' 손^버릇 '],[' 손자국 ',' 손^자국 '],[' 손재주 ',' 손^재주 '],[' 솔방울 ',' 솔^방울 '],[' 쇠발굽 ',' 쇠발^굽 '],[' 수강증 ',' 수강^증 '],[' 수도권 ',' 수도^권 '],[' 수료증 ',' 수료^증 '],[' 수밀도 ',' 수밀^도 '],[' 수사권 ',' 수사^권 '],[' 수사법 ',' 수사^법 '],[' 수전증 ',' 수전^증 '],[' 순위권 ',' 순위^권 '],[' 술버릇 ',' 술^버릇 '],[' 술자리 ',' 술^자리 '],[' 술주정 ',' 술^주정 '],[' 승차권 ',' 승차^권 '],[' 시골길 ',' 시골^길 '],[' 시골집 ',' 시골^집 '],[' 시민권 ',' 시민^권 '],[' 시발점 ',' 시발^점 '],[' 시사점 ',' 시사^점 '],[' 시장기 ',' 시장^기 '],[' 시장법 ',' 시장^법 '],[' 시찰단 ',' 시찰^단 '],[' 식사법 ',' 식사^법 '],[' 신바람 ',' 신^바람 '],[' 신경과 ',' 신경^과 '],[' 신분증 ',' 신분^증 '],[' 신활자 ',' 신활^자 '],[' 실어증 ',' 실어^증 '],[' 실정법 ',' 실정^법 '],[' 심술보 ',' 심술^보 '],[' 심의권 ',' 심의^권 '],[' 심장병 ',' 심장^병 '],[' 십알단 ',' 십알^단 '],[' 쌀가루 ',' 쌀^가루 '],[' 쌀자루 ',' 쌀^자루 '],[' 아침밥 ',' 아침^밥 '],[' 악조건 ',' 악조^건 '],[' 않을게 ',' 않을^게 '],[' 암살단 ',' 암살^단 '],[' 앞발굽 ',' 앞발^굽 '],[' 야맹증 ',' 야맹^증 '],[' 양반집 ',' 양반^집 '],[' 양탕국 ',' 양탕^국 '],[' 언어권 ',' 언어^권 '],[' 언월도 ',' 언월^도 '],[' 얼굴빛 ',' 얼굴^빛 '],[' 여름밤 ',' 여름^밤 '],[' 여름비 ',' 여름^비 '],[' 여염집 ',' 여염^집 '],[' 역설적 ',' 역설^적 '],[' 역세권 ',' 역세^권 '],[' 연주법 ',' 연주^법 '],[' 연활자 ',' 연활^자 '],[' 영남권 ',' 영남^권 '],[' 영동권 ',' 영동^권 '],[' 영서권 ',' 영서^권 '],[' 영어권 ',' 영어^권 '],[' 영월대 ',' 영월^대 '],[' 영유권 ',' 영유^권 '],[' 영주권 ',' 영주^권 '],[' 영토권 ',' 영토^권 '],[' 영해권 ',' 영해^권 '],[' 영화과 ',' 영화^과 '],[' 예방법 ',' 예방^법 '],[' 예술단 ',' 예술^단 '],[' 예술적 ',' 예술^적 '],[' 예술제 ',' 예술^제 '],[' 오솔길 ',' 오솔^길 '],[' 온돌방 ',' 온돌^방 '],[' 외양간 ',' 외양^간 '],[' 외치법 ',' 외치^법 '],[' 요리법 ',' 요리^법 '],[' 용융점 ',' 용융^점 '],[' 우선권 ',' 우선^권 '],[' 우승권 ',' 우승^권 '],[' 우울증 ',' 우울^증 '],[' 우유병 ',' 우유^병 '],[' 운동권 ',' 운동^권 '],[' 운영권 ',' 운영^권 '],[' 울화병 ',' 울화^병 '] _
,[' 원근법 ',' 원근^법 '],[' 원일점 ',' 원일^점 '],[' 원지점 ',' 원지^점 '],[' 원초점 ',' 원초^점 '],[' 원토점 ',' 원토^점 '],[' 원화점 ',' 원화^점 '],[' 월요병 ',' 월요^병 '],[' 월화점 ',' 월화^점 '],[' 위생법 ',' 위생^법 '],[' 위장병 ',' 위장^병 '],[' 유권자 ',' 유^권자 '],[' 유동점 ',' 유동^점 '],[' 유사점 ',' 유사^점 '],[' 유전병 ',' 유전^병 '],[' 유행병 ',' 유행^병 '],[' 유활자 ',' 유활^자 '],[' 유황불 ',' 유황^불 '],[' 은행권 ',' 은행^권 '],[' 응고점 ',' 응고^점 '],[' 의결권 ',' 의결^권 '],[' 의문점 ',' 의문^점 '],[' 의열단 ',' 의열^단 '],[' 의처증 ',' 의처^증 '],[' 이름자 ',' 이름^자 '],[' 이분법 ',' 이분^법 '],[' 이슬빛 ',' 이슬^빛 '],[' 이슬점 ',' 이슬^점 '],[' 이용법 ',' 이용^법 '],[' 이음점 ',' 이음^점 '],[' 이해점 ',' 이해^점 '],[' 인사과 ',' 인사^과 '],[' 인사권 ',' 인사^권 '],[' 인사법 ',' 인사^법 '],[' 인화점 ',' 인화^점 '],[' 일거리 ',' 일^거리 '],[' 일자리 ',' 일^자리 '],[' 일반법 ',' 일반^법 '],[' 일사병 ',' 일사^병 '],[' 일월도 ',' 일월^도 '],[' 일조권 ',' 일조^권 '],[' 일치점 ',' 일치^점 '],[' 임계점 ',' 임계^점 '],[' 임면권 ',' 임면^권 '],[' 임명권 ',' 임명^권 '],[' 입장권 ',' 입장^권 '],[' 있을게 ',' 있을^게 '],[' 자갈길 ',' 자갈^길 '],[' 자연권 ',' 자연^권 '],[' 자연법 ',' 자연^법 '],[' 자위권 ',' 자위^권 '],[' 자유권 ',' 자유^권 '],[' 자율권 ',' 자율^권 '],[' 자율적 ',' 자율^적 '],[' 자재과 ',' 자재^과 '],[' 자치권 ',' 자치^권 '],[' 자치법 ',' 자치^법 '],[' 자폐증 ',' 자폐^증 '],[' 작용점 ',' 작용^점 '],[' 잠기운 ',' 잠^기운 '],[' 잠버릇 ',' 잠^버릇 '],[' 잠수병 ',' 잠수^병 '],[' 장난감 ',' 장난^감 '],[' 장단점 ',' 장단^점 '],[' 재산권 ',' 재산^권 '],[' 쟁의권 ',' 쟁의^권 '],[' 저밀도 ',' 저밀^도 '],[' 저승길 ',' 저승^길 '],[' 저장법 ',' 저장^법 '],[' 전남권 ',' 전남^권 '],[' 전등불 ',' 전등^불 '],[' 전설적 ',' 전설^적 '],[' 전세권 ',' 전세^권 '],[' 전술적 ',' 전술^적 '],[' 전염병 ',' 전염^병 '],[' 전이점 ',' 전이^점 '],[' 전환점 ',' 전환^점 '],[' 절충점 ',' 절충^점 '],[' 점유권 ',' 점유^권 '],[' 접근권 ',' 접근^권 '],[' 접근법 ',' 접근^법 '],[' 정밀도 ',' 정밀^도 '],[' 정신과 ',' 정신^과 '],[' 정신병 ',' 정신^병 '],[' 정치권 ',' 정치^권 '],[' 정치법 ',' 정치^법 '],[' 제도권 ',' 제도^권 '],[' 제안권 ',' 제안^권 '],[' 제조법 ',' 제조^법 '],[' 제해권 ',' 제해^권 '],[' 조리법 ',' 조리^법 '],[' 조명발 ',' 조명^발 '],[' 조음점 ',' 조음^점 '],[' 조정법 ',' 조정^법 '],[' 조준점 ',' 조준^점 '],[' 종지점 ',' 종지^점 '],[' 주도권 ',' 주도^권 '],[' 주술적 ',' 주술^적 '],[' 주시점 ',' 주시^점 '],[' 주안점 ',' 주안^점 '],[' 주요점 ',' 주요^점 '],[' 주의점 ',' 주의^점 '],[' 주인집 ',' 주인^집 '],[' 주홍빛 ',' 주홍^빛 '],[' 주황빛 ',' 주황^빛 '],[' 죽을병 ',' 죽을^병 '],[' 중간권 ',' 중간^권 '],[' 중부권 ',' 중부^권 '],[' 중심점 ',' 중심^점 '],[' 중위권 ',' 중위^권 '],[' 중화점 ',' 중화^점 '],[' 지결도 ',' 지결^도 '],[' 지름길 ',' 지름^길 '],[' 지리권 ',' 지리^권 '],[' 지명권 ',' 지명^권 '],[' 지배권 ',' 지배^권 '],[' 지탱점 ',' 지탱^점 '],[' 지향점 ',' 지향^점 '],[' 지휘권 ',' 지휘^권 '],[' 직설적 ',' 직설^적 '],[' 집시법 ',' 집시^법 '],[' 집필자 ',' 집필^자 '],[' 집필진 ',' 집필^진 '],[' 징세권 ',' 징세^권 '],[' 차단점 ',' 차단^점 '],[' 차이점 ',' 차이^점 '],[' 착안점 ',' 착안^점 '],[' 착지점 ',' 착지^점 '],[' 착탄점 ',' 착탄^점 '],[' 착화점 ',' 착화^점 '],[' 찬실도 ',' 찬실^도 '],[' 책임법 ',' 책임^법 '],[' 천정점 ',' 천정^점 '],[' 철자법 ',' 철자^법 '],[' 철활자 ',' 철활^자 '],[' 첫날밤 ',' 첫날^밤 '],[' 청구권 ',' 청구^권 '],[' 청일점 ',' 청일^점 '],[' 초롱불 ',' 초롱^불 '],[' 초상집 ',' 초상^집 '],[' 초승달 ',' 초승^달 '],[' 초행길 ',' 초행^길 '],[' 최고가 ',' 최고^가 '],[' 최고점 ',' 최고^점 '],[' 최상점 ',' 최상^점 '],[' 최저점 ',' 최저^점 '],[' 최종점 ',' 최종^점 '],[' 최하점 ',' 최하^점 '],[' 추가점 ',' 추가^점 '],[' 추분점 ',' 추분^점 '],[' 추첨권 ',' 추첨^권 '],[' 축농증 ',' 축농^증 '],[' 축지법 ',' 축지^법 '],[' 춘곤증 ',' 춘곤^증 '],[' 춘분점 ',' 춘분^점 '],[' 출근길 ',' 출근^길 '],[' 출발점 ',' 출발^점 '],[' 충청권 ',' 충청^권 '],[' 치료법 ',' 치료^법 '],[' 친정집 ',' 친정^집 '],[' 칼자국 ',' 칼^자국 '],[' 칼자루 ',' 칼^자루 '],[' 콩가루 ',' 콩^가루 '],[' 큰대자 ',' 큰대^자 '],[' 탄저병 ',' 탄저^병 '],[' 태을도 ',' 태을^도 '],[' 텃세권 ',' 텃세^권 '],[' 통계권 ',' 통계^권 '],[' 통근권 ',' 통근^권 '],[' 통수권 ',' 통수^권 '],[' 통제권 ',' 통제^권 '],[' 통치권 ',' 통치^권 '],[' 통치법 ',' 통치^법 '],[' 통팔도 ',' 통팔^도 '],[' 통행권 ',' 통행^권 '],[' 통행증 ',' 통행^증 '],[' 퇴근길 ',' 퇴근^길 '],[' 투사점 ',' 투사^점 '],[' 투표권 ',' 투표^권 '],[' 특별법 ',' 특별^법 '],[' 특이점 ',' 특이^점 '],[' 특허권 ',' 특허^권 '],[' 특화점 ',' 특화^점 '],[' 파괴점 ',' 파괴^점 '],[' 패혈증 ',' 패혈^증 '],[' 평균점 ',' 평균^점 '],[' 평등권 ',' 평등^권 '],[' 포화점 ',' 포화^점 '],[' 표고점 ',' 표고^점 '],[' 표기법 ',' 표기^법 '],[' 표본점 ',' 표본^점 '],[' 표의자 ',' 표의^자 '],[' 표창장 ',' 표창^장 '],[' 풍토병 ',' 풍토^병 '],[' 피난길 ',' 피난^길 '],[' 피부과 ',' 피부^과 '],[' 피부병 ',' 피부^병 '],[' 하늘길 ',' 하늘^길 '],[' 하늘빛 ',' 하늘^빛 '],[' 하위권 ',' 하위^권 '],[' 하지점 ',' 하지^점 '],[' 학생증 ',' 학생^증 '],[' 학술적 ',' 학술^적 '],[' 한계점 ',' 한계^점 '],[' 한밤중 ',' 한밤^중 '],[' 합류점 ',' 합류^점 '],[' 합의점 ',' 합의^점 '],[' 합치점 ',' 합치^점 '],[' 항공권 ',' 항공^권 '],[' 해설집 ',' 해설^집 '],[' 해장국 ',' 해장^국 '],[' 행렬도 ',' 행렬^도 '] _
,[' 행실도 ',' 행실^도 '],[' 행정법 ',' 행정^법 '],[' 향수병 ',' 향수^병 '],[' 허가증 ',' 허가^증 '],[' 허초점 ',' 허초^점 '],[' 현기증 ',' 현기^증 '],[' 현시점 ',' 현시^점 '],[' 현행법 ',' 현행^법 '],[' 혈우병 ',' 혈우^병 '],[' 형벌법 ',' 형벌^법 '],[' 형사법 ',' 형사^법 '],[' 호남권 ',' 호남^권 '],[' 호롱불 ',' 호롱^불 '],[' 호열자 ',' 호열^자 '],[' 호조건 ',' 호조^건 '],[' 호패법 ',' 호패^법 '],[' 홍일점 ',' 홍일^점 '],[' 화분증 ',' 화분^증 '],[' 화장법 ',' 화장^법 '],[' 환경권 ',' 환경^권 '],[' 환유법 ',' 환유^법 '],[' 황금빛 ',' 황금^빛 '],[' 황달병 ',' 황달^병 '],[' 황천길 ',' 황천^길 '],[' 회원권 ',' 회원^권 '],[' 횡단점 ',' 횡단^점 '],[' 효율적 ',' 효율^적 '],[' 후유증 ',' 후유^증 '],[' 휘발도 ',' 휘발^도 '],[' 흑사병 ',' 흑사^병 '],[' 희망점 ',' 희망^점 '],[' 갈게 ',' 갈^게 '],[' 갈대 ',' 갈^대 '],[' 갈등 ',' 갈^등 '],[' 갈증 ',' 갈^증 '],[' 감가 ',' 감^가 '],[' 감다 ',' 감^다 '],[' 감빛 ',' 감^빛 '],[' 강가 ',' 강^가 '],[' 걸작 ',' 걸^작 '],[' 결격 ',' 결^격 '],[' 결단 ',' 결^단 '],[' 결재 ',' 결^재 '],[' 결전 ',' 결^전 '],[' 결정 ',' 결^정 '],[' 결제 ',' 결^제 '],[' 결집 ',' 결^집 '],[' 고점 ',' 고^점 '],[' 골동 ',' 골^동 '],[' 공권 ',' 공^권 '],[' 공법 ',' 공^법 '],[' 관권 ',' 관^권 '],[' 관점 ',' 관^점 '],[' 광기 ',' 광^기 '],[' 교권 ',' 교^권 '],[' 군권 ',' 군^권 '],[' 굴절 ',' 굴^절 '],[' 굴지 ',' 굴^지 '],[' 권법 ',' 권^법 '],[' 글감 ',' 글^감 '],[' 글단 ',' 글^단 '],[' 글발 ',' 글^발 '],[' 글방 ',' 글^방 '],[' 글자 ',' 글^자 '],[' 금빛 ',' 금^빛 '],[' 기권 ',' 기^권 '],[' 기법 ',' 기^법 '],[' 길가 ',' 길^가 '],[' 길조 ',' 길^조 '],[' 꿈결 ',' 꿈^결 '],[' 날빛 ',' 날^빛 '],[' 날조 ',' 날^조 '],[' 남기 ',' 남^기 '],[' 남빛 ',' 남^빛 '],[' 내과 ',' 내^과 '],[' 내적 ',' 내^적 '],[' 냉국 ',' 냉^국 '],[' 넘고 ',' 넘^고 '],[' 넘다 ',' 넘^다 '],[' 논길 ',' 논^길 '],[' 논법 ',' 논^법 '],[' 농법 ',' 농^법 '],[' 눈길 ',' 눈^길 '],[' 눈독 ',' 눈^독 '],[' 눈발 ',' 눈^발 '],[' 눈병 ',' 눈^병 '],[' 눈빛 ',' 눈^빛 '],[' 눈짓 ',' 눈^짓 '],[' 단점 ',' 단^점 '],[' 달밤 ',' 달^밤 '],[' 달빛 ',' 달^빛 '],[' 달집 ',' 달^집 '],[' 담고 ',' 담^고 '],[' 담다 ',' 담^다 '],[' 대격 ',' 대^격 '],[' 대권 ',' 대^권 '],[' 도법 ',' 도^법 '],[' 돌길 ',' 돌^길 '],[' 돌진 ',' 돌^진 '],[' 동격 ',' 동^격 '],[' 들개 ',' 들^개 '],[' 들길 ',' 들^길 '],[' 들불 ',' 들^불 '],[' 등골 ',' 등^골 '],[' 등불 ',' 등^불 '],[' 땅개 ',' 땅^개 '],[' 땔감 ',' 땔^감 '],[' 똥개 ',' 똥^개 '],[' 만점 ',' 만^점 '],[' 말단 ',' 말^단 '],[' 말발 ',' 말^발 '],[' 맹점 ',' 맹^점 '],[' 묘법 ',' 묘^법 '],[' 문건 ',' 문^건 '],[' 문법 ',' 문^법 '],[' 문자 ',' 문^자 '],[' 물가 ',' 물^가 '],[' 물감 ',' 물^감 '],[' 물개 ',' 물^개 '],[' 물격 ',' 물^격 '],[' 물결 ',' 물^결 '],[' 물권 ',' 물^권 '],[' 물길 ',' 물^길 '],[' 물병 ',' 물^병 '],[' 물빛 ',' 물^빛 '],[' 물자 ',' 물^자 '],[' 물정 ',' 물^정 '],[' 물주 ',' 물^주 '],[' 물질 ',' 물^질 '],[' 민권 ',' 민^권 '],[' 민법 ',' 민^법 '],[' 밀도 ',' 밀^도 '],[' 밀접 ',' 밀^접 '],[' 밀정 ',' 밀^정 '],[' 밀집 ',' 밀^집 '],[' 발굽 ',' 발^굽 '],[' 발길 ',' 발^길 '],[' 발단 ',' 발^단 '],[' 발달 ',' 발^달 '],[' 발등 ',' 발^등 '],[' 발작 ',' 발^작 '],[' 발전 ',' 발^전 '],[' 발정 ',' 발^정 '],[' 발제 ',' 발^제 '],[' 발족 ',' 발^족 '],[' 발주 ',' 발^주 '],[' 발진 ',' 발^진 '],[' 밤빛 ',' 밤^빛 '],[' 백골 ',' 백^골 '],[' 뱀독 ',' 뱀^독 '],[' 벌점 ',' 벌^점 '],[' 벌집 ',' 벌^집 '],[' 범법 ',' 범^법 '],[' 범자 ',' 범^자 '],[' 별빛 ',' 별^빛 '],[' 병증 ',' 병^증 '],[' 본격 ',' 본^격 '],[' 봄밤 ',' 봄^밤 '],[' 봄비 ',' 봄^비 '],[' 봄빛 ',' 봄^빛 '],[' 분권 ',' 분^권 '],[' 불단 ',' 불^단 '],[' 불법 ',' 불^법 '],[' 불빛 ',' 불^빛 '],[' 비법 ',' 비^법 '],[' 빵집 ',' 빵^집 '],[' 사건 ',' 사^건 '],[' 산골 ',' 산^골 '],[' 산길 ',' 산^길 '],[' 산불 ',' 산^불 '],[' 살결 ',' 살^결 '],[' 살빛 ',' 살^빛 '],[' 살집 ',' 살^집 '],[' 상권 ',' 상^권 '],[' 상법 ',' 상^법 '],[' 서법 ',' 서^법 '],[' 설득 ',' 설^득 '],[' 설법 ',' 설^법 '],[' 설전 ',' 설^전 '],[' 설정 ',' 설^정 '],[' 성격 ',' 성^격 '],[' 성과 ',' 성^과 '],[' 성병 ',' 성^병 '],[' 세법 ',' 세^법 '],[' 셈법 ',' 셈^법 '],[' 손금 ',' 손^금 '],[' 손길 ',' 손^길 '],[' 손등 ',' 손^등 '],[' 솔직 ',' 솔^직 '],[' 수법 ',' 수^법 '],[' 술독 ',' 술^독 '],[' 술동 ',' 술^동 '],[' 술병 ',' 술^병 '],[' 술잔 ',' 술^잔 '],[' 술집 ',' 술^집 '],[' 숨결 ',' 숨^결 '],[' 숨고 ',' 숨^고 '],[' 숨다 ',' 숨^다 '],[' 승격 ',' 승^격 '],[' 시적 ',' 시^적 '],[' 시점 ',' 시^점 '],[' 신격 ',' 신^격 '],[' 신권 ',' 신^권 '],[' 신다 ',' 신^다 '],[' 실격 ',' 실^격 '],[' 실과 ',' 실^과 '],[' 실권 ',' 실^권 '],[' 실단 ',' 실^단 '],[' 실장 ',' 실^장 '],[' 실적 ',' 실^적 '],[' 실전 ',' 실^전 '],[' 실점 ',' 실^점 '],[' 실정 ',' 실^정 '],[' 실제 ',' 실^제 '],[' 실족 ',' 실^족 '],[' 실존 ',' 실^존 '],[' 실종 ',' 실^종 '],[' 실증 ',' 실^증 '],[' 실직 ',' 실^직 '],[' 실질 ',' 실^질 '],[' 싫증 ',' 싫^증 '],[' 심고 ',' 심^고 '],[' 심다 ',' 심^다 '],[' 심적 ',' 심^적 '],[' 안건 ',' 안^건 '],[' 안과 ',' 안^과 '],[' 안길 ',' 안^길 '],[' 알집 ',' 알^집 '],[' 야권 ',' 야^권 '],[' 어법 ',' 어^법 '],[' 엄격 ',' 엄^격 '],[' 여건 ',' 여^건 '] _
,[' 여권 ',' 여^권 '],[' 열권 ',' 열^권 '],[' 열대 ',' 열^대 '],[' 열도 ',' 열^도 '],[' 열독 ',' 열^독 '],[' 열등 ',' 열^등 '],[' 열전 ',' 열^전 '],[' 열정 ',' 열^정 '],[' 열조 ',' 열^조 '],[' 염증 ',' 염^증 '],[' 영적 ',' 영^적 '],[' 예법 ',' 예^법 '],[' 외과 ',' 외^과 '],[' 요건 ',' 요^건 '],[' 요점 ',' 요^점 '],[' 용법 ',' 용^법 '],[' 울진 ',' 울^진 '],[' 월권 ',' 월^권 '],[' 월도 ',' 월^도 '],[' 월등 ',' 월^등 '],[' 월장 ',' 월^장 '],[' 유권 ',' 유^권 '],[' 율격 ',' 율^격 '],[' 율동 ',' 율^동 '],[' 율법 ',' 율^법 '],[' 은빛 ',' 은^빛 '],[' 의과 ',' 의^과 '],[' 이권 ',' 이^권 '],[' 인격 ',' 인^격 '],[' 인권 ',' 인^권 '],[' 인기 ',' 인^기 '],[' 일감 ',' 일^감 '],[' 일단 ',' 일^단 '],[' 일당 ',' 일^당 '],[' 일대 ',' 일^대 '],[' 일독 ',' 일^독 '],[' 일등 ',' 일^등 '],[' 일장 ',' 일^장 '],[' 일절 ',' 일^절 '],[' 일정 ',' 일^정 '],[' 일제 ',' 일^제 '],[' 일조 ',' 일^조 '],[' 일종 ',' 일^종 '],[' 일주 ',' 일^주 '],[' 일지 ',' 일^지 '],[' 일진 ',' 일^진 '],[' 잠결 ',' 잠^결 '],[' 장국 ',' 장^국 '],[' 장독 ',' 장^독 '],[' 장점 ',' 장^점 '],[' 쟁점 ',' 쟁^점 '],[' 저점 ',' 저^점 '],[' 전권 ',' 전^권 '],[' 절단 ',' 절^단 '],[' 절대 ',' 절^대 '],[' 절도 ',' 절^도 '],[' 절제 ',' 절^제 '],[' 절지 ',' 절^지 '],[' 절집 ',' 절^집 '],[' 점자 ',' 점^자 '],[' 점집 ',' 점^집 '],[' 정가 ',' 정^가 '],[' 정권 ',' 정^권 '],[' 정점 ',' 정^점 '],[' 조건 ',' 조^건 '],[' 주격 ',' 주^격 '],[' 주권 ',' 주^권 '],[' 준법 ',' 준^법 '],[' 줄게 ',' 줄^게 '],[' 중점 ',' 중^점 '],[' 중증 ',' 중^증 '],[' 증권 ',' 증^권 '],[' 질적 ',' 질^적 '],[' 질주 ',' 질^주 '],[' 채점 ',' 채^점 '],[' 철도 ',' 철^도 '],[' 철제 ',' 철^제 '],[' 철종 ',' 철^종 '],[' 초점 ',' 초^점 '],[' 출두 ',' 출^두 '],[' 출진 ',' 출^진 '],[' 치과 ',' 치^과 '],[' 칠대 ',' 칠^대 '],[' 칠진 ',' 칠^진 '],[' 침권 ',' 침^권 '],[' 타점 ',' 타^점 '],[' 탈격 ',' 탈^격 '],[' 탈당 ',' 탈^당 '],[' 탈법 ',' 탈^법 '],[' 탈주 ',' 탈^주 '],[' 탈진 ',' 탈^진 '],[' 탕국 ',' 탕^국 '],[' 태권 ',' 태^권 '],[' 털빛 ',' 털^빛 '],[' 통점 ',' 통^점 '],[' 통증 ',' 통^증 '],[' 판권 ',' 판^권 '],[' 팔달 ',' 팔^달 '],[' 팔당 ',' 팔^당 '],[' 팔대 ',' 팔^대 '],[' 팔도 ',' 팔^도 '],[' 팔자 ',' 팔^자 '],[' 팔진 ',' 팔^진 '],[' 패권 ',' 패^권 '],[' 편법 ',' 편^법 '],[' 평가 ',' 평^가 '],[' 폐병 ',' 폐^병 '],[' 풀빛 ',' 풀^빛 '],[' 품격 ',' 품^격 '],[' 품고 ',' 품^고 '],[' 품다 ',' 품^다 '],[' 필독 ',' 필^독 '],[' 필두 ',' 필^두 '],[' 필법 ',' 필^법 '],[' 필자 ',' 필^자 '],[' 필적 ',' 필^적 '],[' 필지 ',' 필^지 '],[' 필진 ',' 필^진 '],[' 한자 ',' 한^자 '],[' 할게 ',' 할^게 '],[' 할당 ',' 할^당 '],[' 함자 ',' 함^자 '],[' 해법 ',' 해^법 '],[' 헌법 ',' 헌^법 '],[' 형법 ',' 형^법 '],[' 화법 ',' 화^법 '],[' 활동 ',' 활^동 '],[' 활자 ',' 활^자 '],[' 활주 ',' 활^주 '],[' 흠집 ',' 흠^집 ']]

   For $i = 0 To Ubound($RuleFortis, 1) - 1
	 $NClipB = StringRegExpReplace($NClipB,$RuleFortis[$i][0],$RuleFortis[$i][1])
   Next

   $ClipB = StringStripWS($NClipB,1+2+4)
   $ClipB = StringReplace ($ClipB,"^"," GLOTTAL ")
   Sleep(50+20)
   $Result=""
   Local $aArray=StringSplit($ClipB," ")
   For $i = 1 To Ubound($aArray, 1)-1
	 ClipPut($aArray[$i])
	 KorRom()
	 $Result=$Result & " " & ClipGet()
   Next

   $Result2 = " " & StringStripWS($Result,1) & " "

   ; FKR059
   $Result2 = StringReplace($Result2," GLOTTAL ","")

   $Result2 = StringReplace($Result2,"*","")
   $Result2 = StringReplace($Result2,"^","")
   For $i=0 to StringInStr($Result2,'"-')/2
	  $Result2=StringReplace($Result2,'"-',' "',1)
	  $Result2=StringReplace($Result2,' "-','" ',1)
   Next

   ; FKR060
   Local $Rule[8][2] = [["-nyŏn ","-yŏn "],["-nyŏn ","-yŏn "],["-nyŏndo ","-yŏndo "],["-nyŏndo ","-yŏndo "],["-nyŏndae ","-yŏndae "],["-nyŏndae ","-yŏndae "],["-nyŏnsa ","-yŏnsa "],["-nyŏnsaeng ","-yŏnsaeng "]]
   $Result2 = $Result2 & " "
   For $i = 0 To Ubound($Rule, 1) - 1
	  $Result2 = StringRegExpReplace($Result2, "\Q" & $Rule[$i][0] & "\E",$Rule[$i][1])
   Next

   $Result2 = " " & (StringStripWS($Result2,4)) & " "

   ;FKR061
Local $RuleGN[471][2] = [[" kangnamgu "," Kangnam-gu "],[" kangdonggu "," Kangdong-gu "],[" kangbukku "," Kangbuk-ku "],[" kangsŏgu "," Kangsŏ-gu "],[" kwanakku "," Kwanak-ku "],[" kwangjin'gu "," Kwangjin-gu "],[" kurogu "," Kuro-gu "],[" kŭmch'ŏn'gu "," Kŭmch'ŏn-gu "],[" nowŏn'gu "," Nowŏn-gu "],[" tobonggu "," Tobong-gu "],[" tongdaemun'gu "," Tongdaemun-gu "],[" tongjakku "," Tongjak-ku "],[" map'ogu "," Map'o-gu "],[" sŏdaemun'gu "," Sŏdaemun-gu "],[" sŏch'ogu "," Sŏch'o-gu "],[" sŏngdonggu "," Sŏngdong-gu "],[" sŏngbukku "," Sŏngbuk-ku "],[" songp'agu "," Songp'a-gu "],[" yangch'ŏn'gu "," Yangch'ŏn-gu "],[" yŏngdŭngp'ogu "," Yŏngdŭngp'o-gu "],[" yongsan'gu "," Yongsan-gu "],[" ŭnp'yŏnggu "," Ŭnp'yŏng-gu "],[" chongnogu "," Chongno-gu "],[" chunggu "," Chung-gu "],[" chungnanggu "," Chungnang-gu "],[" taehan min'guk "," Taehan Min'guk "],[" taehan cheguk "," Taehan Cheguk "],[" taehanmin'guk "," Taehan Min'guk "],[" taehancheguk "," Taehan Cheguk "],[" kap'yŏnggun "," Kap'yŏng-gun "],[" kangjin'gun "," Kangjin-gun "],[" kanghwagun "," Kanghwa-gun "],[" kŏch'anggun "," Kŏch'ang-gun "],[" koryŏnggun "," Koryŏng-gun "],[" kosŏnggun "," Kosŏng-gun "],[" koch'anggun "," Koch'ang-gun "],[" kohŭnggun "," Kohŭng-gun "],[" koksŏnggun "," Koksŏng-gun "],[" koesan'gun "," Koesan-gun "],[" kuryegun "," Kurye-gun "],[" kunwigun "," Kunwi-gun "],[" kŭmsan'gun "," Kŭmsan-gun "],[" kijanggun "," Kijang-gun "],[" namhaegun "," Namhae-gun "],[" tanyanggun "," Tanyang-gun "],[" talsŏnggun "," Talsŏng-gun "],[" tamyanggun "," Tamyang-gun "],[" muan'gun "," Muan-gun "],[" mujugun "," Muju-gun "],[" posŏnggun "," Posŏng-gun "],[" poŭn'gun "," Poŭn-gun "],[" ponghwagun "," Ponghwa-gun "],[" puan'gun "," Puan-gun "],[" puyŏgun "," Puyŏ-gun "],[" sanch'ŏnggun "," Sanch'ŏng-gun "],[" sŏch'ŏn'gun "," Sŏch'ŏn-gun "],[" sŏngjugun "," Sŏngju-gun "],[" sunch'anggun "," Sunch'ang-gun "],[" sinan'gun "," Sinan-gun "],[" yanggugun "," Yanggu-gun "],[" yangyanggun "," Yangyang-gun "],[" yangp'yŏnggun "," Yangpy'ŏng-gun "],[" yŏjugun "," Yŏju-gun "],[" yŏnch'ŏn'gun "," Yŏnch'ŏn-gun "],[" yŏnggwanggun "," Yŏnggwang-gun "],[" yŏngdŏkkun "," Yŏngdŏk-kun "],[" yŏngdonggun "," Yŏngdong-gun "],[" yŏngamgun "," Yŏngam-gun "],[" yŏngyanggun "," Yŏngyang-gun "],[" yŏngwŏlgun "," Yŏngwŏl-gun "],[" yesan'gun "," Yesan-gun "],[" yech'ŏn'gun "," Yech'ŏn-gun "],[" okch'ŏn'gun "," Okch'ŏn-gun "],[" ongjin'gun "," Ongjin-gun "],[" wandogun "," Wando-gun "],[" wanjugun "," Wanju-gun "],[" ullŭnggun "," Ullŭng-gun "],[" uljugun "," Ulchu-gun "],[" ulchin'gun "," Ulchin-gun "],[" ŭmsŏnggun "," Ŭmsŏng-gun "],[" ŭiryŏnggun "," Ŭiryŏng-gun "],[" ŭisŏnggun "," Ŭisŏng-gun "],[" injegun "," Inje-gun "],[" imsilgun "," Imsil-gun "],[" changsŏnggun "," Changsŏng-gun "],[" changsugun "," Changsu-gun "],[" changhŭnggun "," Changhŭng-gun "],[" chŏngsŏn'gun "," Chŏngsŏn-gun "],[" chŭngp'yŏnggun "," Chŭngp'yŏng-gun "],[" chindogun "," Chindo-gun "],[" chinan'gun "," Chinan-gun "],[" chinyanggun "," Chinyang-gun "],[" chinch'ŏn'gun "," Chinch'ŏn-gun "],[" ch'angnyŏnggun "," Ch'angnyŏng-gun "],[" ch'ŏrwŏn'gun "," Ch'ŏrwŏn-gun "],[" ch'ŏngdogun "," Ch'ŏngdo-gun "],[" ch'ŏngsonggun "," Ch'ŏngsong-gun "],[" ch'ŏngyanggun "," Ch'ŏngyang-gun "],[" ch'ilgokkun "," Ch'ilgok-kun "],[" t'aean'gun "," T'aean-gun "],[" p'yŏngch'anggun "," P'yŏngch'ang-gun "],[" hadonggun "," Hadong-gun "],[" haman'gun "," Haman-gun "],[" hamyanggun "," Hamyang-gun "],[" hamp'yŏnggun "," Hamp'yŏng-gun "],[" hapch'ŏn'gun "," Hapch'ŏn-gun "],[" haenamgun "," Haenam-gun "],[" hongsŏnggun "," Hongsŏng-gun "],[" hongch'ŏn'gun "," Hongch'ŏn-gun "],[" hwasun'gun "," Hwasun-gun "],[" hwach'ŏn'gun "," Hwach'ŏn-gun "],[" hoengsŏnggun "," Hoengsŏng-gun "],[" kangwŏndo "," Kangwŏn-do "],[" kyŏnggido "," Kyŏnggi-do "],[" Kyŏngsang namdo "," Kyŏngsang-namdo "],[" Kyŏngsang pukto "," Kyŏngsang-bukto "] _
,[" kyŏngsangnamdo "," Kyŏngsang-namdo "],[" kyŏngsangdo "," Kyŏngsang-do "],[" kyŏngsangbukto "," Kyŏngsang-bukto "],[" Chŏlla namdo "," Chŏlla-namdo "],[" Chŏlla pukto "," Chŏlla-bukto "],[" chŏllanamdo "," Chŏlla-namdo "],[" chŏllado "," Chŏlla-do "],[" chŏllabukto "," Chŏlla-bukto "],[" Cheju t'ŭkpyŏl chach'ido "," Cheju T'ŭkpyŏl Chach'ido "],[" chejut'ŭkpyŏljach'ido "," Cheju T'ŭkpyŏl Chach'ido "],[" Ch'ungch'ŏng namdo "," Ch'ungch'ŏng-namdo "],[" Ch'ungch'ŏng pukto "," Ch'ungch'ŏng-bukto "],[" ch'ungch'ŏngnamdo "," Ch'ungch'ŏng-namdo "],[" ch'ungch'ŏngdo "," Ch'ungch'ŏng-do "],[" ch'ungch'ŏngbukto "," Ch'ungch'ŏng-bukto "],[" P'yŏngan namdo "," P'yŏngan-namdo "],[" P'yŏngan pukto "," P'yŏngan-bukto "],[" p'yŏngannamdo "," P'yŏngan-namdo "],[" p'yŏngando "," P'yŏngan-do "],[" p'yŏnganbukto "," P'yŏngan-bukto "],[" Hamgyŏng namdo "," Hamgyŏng-namdo "],[" Hamgyŏng pukto "," Hamgyŏng-bukto "],[" hamgyŏngnamdo "," Hamgyŏng-namdo "],[" hamgyŏngdo "," Hamgyŏng-do "],[" hamgyŏngbukto "," Hamgyŏng-bukto "],[" hwanghaedo "," Hwanghae-do "],[" kyŏngsŏngbu "," Kyŏngsŏng-bu "],[" hansŏngbu "," Hansŏng-bu "],[" hanyangbu "," Hanyang-bu "],[" kangnŭngsi "," Kangnŭng-si "],[" kŏjesi "," Kŏje-si "],[" kyŏngsansi "," Kyŏngsan-si "],[" kyŏngjusi "," Kyŏngju-si "],[" koyangsi "," Koyang-si "],[" kongjusi "," Kongju-si "],[" kwach'ŏnsi "," Kwach'ŏn-si "],[" kwangmyŏngsi "," Kwangmyŏng-si "],[" kwangyangsi "," Kwangyang-si "],[" Kwangju kwangyŏksi "," Kwangju Kwangyŏksi "],[" kwangjugwangyŏksi "," Kwangju Kwangyŏksi "],[" kwangjusi "," Kwangju-si "],[" kurisi "," Kuri-si "],[" kumisi "," Kumi-si "],[" kunsansi "," Kunsan-si "],[" kunp'osi "," Kunp'o-si "],[" kimjesi "," Kimje-si "],[" kimch'ŏnsi "," Kimch'ŏn-si "],[" kimp'osi "," Kimp'o-si "],[" kimhaesi "," Kimhae-si "],[" najusi "," Naju-si "],[" namyangjusi "," Namyangju-si "],[" namwŏnsi "," Namwŏn-si "],[" nonsansi "," Nonsan-si "],[" tangjinsi "," Tangjin-si "],[" Taegu kwangyŏksi "," Taegu Kwangyŏksi "],[" taegugwangyŏksi "," Taegu Kwangyŏksi "],[" taegusi "," Taegu-si "],[" Taejŏn kwangyŏksi "," Taejŏn Kwangyŏksi "],[" taejŏn'gwangyŏksi "," Taejŏn Kwangyŏksi "],[" taejŏnsi "," Taejŏn-si "],[" tongduch'ŏnsi "," Tongduch'ŏn-si "],[" tonghaesi "," Tonghae-si "],[" masansi "," Masan-si "],[" mokp'osi "," Mokp'o-si "],[" mun'gyŏngsi "," Mun'gyŏng-si "],[" miryangsi "," Miryang-si "],[" poryŏngsi "," Poryŏng-si "],[" Pusan kwangyŏksi "," Pusan Kwangyŏksi "],[" pusan'gwangyŏksi "," Pusan Kwangyŏksi "],[" pusansi "," Pusan-si "],[" puch'ŏnsi "," Puch'ŏn-si "],[" sach'ŏnsi "," Sach'ŏn-si "],[" samch'ŏksi "," Samch'ŏk-si "],[" samch'ŏnp'osi "," Samch'ŏnp'o-si "],[" sangjusi "," Sangju-si "],[" sŏgwip'osi "," Sŏgwip'o-si "],[" sŏsansi "," Sŏsan-si "],[" Sŏul t'ŭkpyŏlsi "," Sŏul T'ŭkpyŏlsi "],[" sŏulsi "," Sŏul-si "],[" sŏult'ŭkpyŏlsi "," Sŏul T'ŭkpyŏlsi "],[" sŏngnamsi "," Sŏngnam-si "],[" Sejong t'ŭkpyŏl chach'isi "," Sejong T'ŭkpyŏl Chach'isi "],[" sejongsi "," Sejong-si "],[" sejongt'ŭkpyŏljach'isi "," Sejong T'ŭkpyŏl Chach'isi "],[" sokch'osi "," Sokch'o-si "],[" suwŏnsi "," Suwŏn-si "],[" Sui t'ŭkpyŏlsi "," Sui T'ŭkpyŏlsi "],[" suit'ŭkpyŏlsi "," Sui T'ŭkpyŏlsi "],[" sunch'ŏnsi "," Sunch'ŏn-si "],[" sihŭngsi "," Sihŭng-si "],[" asansi "," Asan-si "],[" andongsi "," Andong-si "],[" ansansi "," Ansan-si "],[" ansŏngsi "," Ansŏng-si "],[" anyangsi "," Anyang-si "],[" yangsansi "," Yangsan-si "],[" yangjusi "," Yangju-si "],[" yŏsusi "," Yŏsu-si "],[" yŏjusi "," Yŏju-si "],[" yŏngjusi "," Yŏngju-si "],[" yŏngch'ŏnsi "," Yŏngch'ŏn-si "],[" osansi "," Osan-si "],[" yonginsi "," Yongin-si "],[" Ulsan kwangyŏksi "," Ulsan Kwangyŏksi "],[" ulsan'gwangyŏksi "," Ulsan Kwangyŏksi "],[" ulsansi "," Ulsan-si "],[" wŏnjusi "," Wŏnju-si "],[" ŭiwangsi "," Ŭiwang-si "],[" ŭijŏngbusi "," Ŭijŏngbu-si "],[" ich'ŏnsi "," Ich'ŏn-si "],[" iksansi "," Iksan-si "] _
,[" Inch'ŏn kwangyŏksi "," Inch'ŏn Kwangyŏksi "],[" inch'ŏn'gwangyŏksi "," Inch'ŏn Kwangyŏksi "],[" inch'ŏnsi "," Inch'ŏn-si "],[" chŏnjusi "," Chŏnju-si "],[" chŏngŭpsi "," Chŏngŭp-si "],[" chejusi "," Cheju-si "],[" chech'ŏnsi "," Chech'ŏn-si "],[" chinjusi "," Chinju-si "],[" chinhaesi "," Chinhae-si "],[" ch'angwŏnsi "," Ch'angwŏn-si "],[" ch'ŏnansi "," Ch'ŏnan-si "],[" ch'ŏngjusi "," Ch'ŏngju-si "],[" ch'unch'ŏnsi "," Ch'unch'ŏn-si "],[" ch'ungjusi "," Ch'ungju-si "],[" t'aebaeksi "," T'aebaek-si "],[" t'ongyŏngsi "," T'ongyŏng-si "],[" p'ajusi "," P'aju-si "],[" p'yŏngt'aeksi "," P'yŏngt'aek-si "],[" p'och'ŏnsi "," P'och'ŏn-si "],[" p'ohangsi "," P'ohang-si "],[" hanamsi "," Hanam-si "],[" hwasŏngsi "," Hwasŏng-si "],[" kanamŭp "," Kanam-ŭp "],[" kayaŭp "," Kaya-ŭp "],[" kaŭnŭp "," Kaŭn-ŭp "],[" kap'yŏngŭp "," Kap'yŏng-ŭp "],[" kansŏngŭp "," Kansŏng-ŭp "],[" kalmarŭp "," Kalmar-ŭp "],[" kamp'oŭp "," Kamp'o-ŭp "],[" kanggyŏngŭp "," Kanggyŏng-ŭp "],[" kangjinŭp "," Kangjin-ŭp "],[" kanghwaŭp "," Kanghwa-ŭp "],[" kŏjinŭp "," Kŏjin-ŭp "],[" kŏch'angŭp "," Kŏch'ang-ŭp "],[" kŏnch'ŏnŭp "," Kŏnch'ŏn-ŭp "],[" koryŏngŭp "," Koryŏng-ŭp "],[" kosŏngŭp "," Kosŏng-ŭp "],[" koaŭp "," Koa-ŭp "],[" koch'angŭp "," Koch'ang-ŭp "],[" koch'onŭp "," Koch'on-ŭp "],[" kohanŭp "," Kohan-ŭp "],[" kohŭngŭp "," Kohŭng-ŭp "],[" koksŏngŭp "," Koksŏng-ŭp "],[" kongdoŭp "," Kongdo-ŭp "],[" kwansanŭp "," Kwansan-ŭp "],[" kwangyangŭp "," Kwangyang-ŭp "],[" kwangch'ŏnŭp "," Kwangch'ŏn-ŭp "],[" koesanŭp "," Koesan-ŭp "],[" kuryeŭp "," Kurye-ŭp "],[" kuryongp'oŭp "," Kuryongp'o-ŭp "],[" kujwaŭp "," Kujwa-ŭp "],[" kunwiŭp "," Kunwi-ŭp "],[" kŭmsanŭp "," Kŭmsan-ŭp "],[" kŭmwangŭp "," Kŭmwang-ŭp "],[" kŭmirŭp "," Kŭmir-ŭp "],[" kŭmhoŭp "," Kŭmho-ŭp "],[" kijangŭp "," Kijang-ŭp "],[" kimhwaŭp "," Kimhwa-ŭp "],[" namyangŭp "," Namyang-ŭp "],[" namwŏnŭp "," Namwŏn-ŭp "],[" namjiŭp "," Namji-ŭp "],[" namp'yŏngŭp "," Namp'yŏng-ŭp "],[" namhaeŭp "," Namhae-ŭp "],[" naesŏŭp "," Naesŏ-ŭp "],[" naesuŭp "," Naesu-ŭp "],[" nohwaŭp "," Nohwa-ŭp "],[" non'gongŭp "," Non'gong-ŭp "],[" tasaŭp "," Tasa-ŭp "],[" tanyangŭp "," Tanyang-ŭp "],[" tamyangŭp "," Tamyang-ŭp "],[" taedŏgŭp "," Taedŏg-ŭp "],[" taesanŭp "," Taesan-ŭp "],[" taejŏngŭp "," Taejŏng-ŭp "],[" togyeŭp "," Togye-ŭp "],[" toyangŭp "," Toyang-ŭp "],[" tolsanŭp "," Tolsan-ŭp "],[" tongsongŭp "," Tongsong-ŭp "],[" tongŭp "," Tong-ŭp "],[" man'gyŏngŭp "," Man'gyŏng-ŭp "],[" maep'oŭp "," Maep'o-ŭp "],[" mokch'ŏnŭp "," Mokch'ŏn-ŭp "],[" muanŭp "," Muan-ŭp "],[" mujuŭp "," Muju-ŭp "],[" mun'gyŏngŭp "," Mun'gyŏng-ŭp "],[" munmagŭp "," Munmag-ŭp "],[" munsanŭp "," Munsan-ŭp "],[" mulgŭmŭp "," Mulgŭm-ŭp "],[" paebangŭp "," Paebang-ŭp "],[" paeksŏgŭp "," Paeksŏg-ŭp "],[" paeksuŭp "," Paeksu-ŭp "],[" pŏlgyoŭp "," Pŏlgyo-ŭp "],[" pŏmsŏŭp "," Pŏmsŏ-ŭp "],[" pŏbwŏnŭp "," Pŏbwŏn-ŭp "],[" posŏngŭp "," Posŏng-ŭp "],[" poŭnŭp "," Poŭn-ŭp "],[" pongdamŭp "," Pongdam-ŭp "],[" pongdongŭp "," Pongdong-ŭp "],[" pongyangŭp "," Pongyang-ŭp "],[" ponghwaŭp "," Ponghwa-ŭp "],[" pubarŭp "," Pubar-ŭp "],[" puanŭp "," Puan-ŭp "],[" puyŏŭp "," Puyŏ-ŭp "],[" puksamŭp "," Puksam-ŭp "],[" sabugŭp "," Sabug-ŭp "],[" sach'ŏnŭp "," Sach'ŏn-ŭp "],[" sanyangŭp "," Sanyang-ŭp "],[" sanch'ŏngŭp "," Sanch'ŏng-ŭp "],[" samnangjinŭp "," Samnangjin-ŭp "],[" samnyeŭp "," Samnye-ŭp "],[" samhyangŭp "," Samhyang-ŭp "],[" samhoŭp "," Samho-ŭp "],[" sapkyoŭp "," Sapkyo-ŭp "],[" sangdongŭp "," Sangdong-ŭp "],[" sŏch'ŏnŭp "," Sŏch'ŏn-ŭp "],[" sŏkchŏgŭp "," Sŏkchŏg-ŭp "],[" sŏnsanŭp "," Sŏnsan-ŭp "],[" sŏnggŏŭp "," Sŏnggŏ-ŭp "],[" sŏngsanŭp "," Sŏngsan-ŭp "],[" sŏngjuŭp "," Sŏngju-ŭp "],[" sŏnghwanŭp "," Sŏnghwan-ŭp "],[" sohŭrŭp "," Sohŭr-ŭp "] _
,[" songagŭp "," Songag-ŭp "],[" sunch'angŭp "," Sunch'ang-ŭp "],[" sŭngjuŭp "," Sŭngju-ŭp "],[" sindongŭp "," Sindong-ŭp "],[" sinbugŭp "," Sinbug-ŭp "],[" sint'aeinŭp "," Sint'aein-ŭp "],[" silch'onŭp "," Silch'on-ŭp "],[" ap'oŭp "," Ap'o-ŭp "],[" an'gangŭp "," An'gang-ŭp "],[" anmyŏnŭp "," Anmyŏn-ŭp "],[" anjungŭp "," Anjung-ŭp "],[" aphaeŭp "," Aphae-ŭp "],[" aewŏrŭp "," Aewŏr-ŭp "],[" yangguŭp "," Yanggu-ŭp "],[" yangyangŭp "," Yangyang-ŭp "],[" yangch'onŭp "," Yangch'on-ŭp "],[" yangp'yŏngŭp "," Yangp'yŏng-ŭp "],[" ŏnyangŭp "," Ŏnyang-ŭp "],[" yŏjuŭp "," Yŏju-ŭp "],[" yŏnmuŭp "," Yŏnmu-ŭp "],[" yŏnirŭp "," Yŏnir-ŭp "],[" yŏnch'ŏnŭp "," Yŏnch'ŏn-ŭp "],[" yŏmch'iŭp "," Yŏmch'i-ŭp "],[" yŏnggwangŭp "," Yŏnggwang-ŭp "],[" yŏngdŏgŭp "," Yŏngdŏg-ŭp "],[" yŏngdongŭp "," Yŏngdong-ŭp "],[" yŏngamŭp "," Yŏngam-ŭp "],[" yŏngyangŭp "," Yŏngyang-ŭp "],[" yŏngwŏrŭp "," Yŏngwŏr-ŭp "],[" yesanŭp "," Yesan-ŭp "],[" yech'ŏnŭp "," Yech'ŏn-ŭp "],[" onamŭp "," Onam-ŭp "],[" osongŭp "," Osong-ŭp "],[" och'angŭp "," Och'ang-ŭp "],[" och'ŏnŭp "," Och'ŏn-ŭp "],[" op'oŭp "," Op'o-ŭp "],[" okkuŭp "," Okku-ŭp "],[" okch'ŏnŭp "," Okch'ŏn-ŭp "],[" onsanŭp "," Onsan-ŭp "],[" onyangŭp "," Onyang-ŭp "],[" wabuŭp "," Wabu-ŭp "],[" wandoŭp "," Wando-ŭp "],[" waegwanŭp "," Waegwan-ŭp "],[" oedongŭp "," Oedong-ŭp "],[" yongjinŭp "," Yongjin-ŭp "],[" ujŏngŭp "," Ujŏng-ŭp "],[" unbongŭp "," Unbong-ŭp "],[" ullŭngŭp "," Ullŭng-ŭp "],[" ulchinŭp "," Ulchin-ŭp "],[" ungch'ŏnŭp "," Ungch'ŏn-ŭp "],[" wŏndŏgŭp "," Wŏndŏg-ŭp "],[" yuguŭp "," Yugu-ŭp "],[" ŭmsŏngŭp "," Ŭmsŏng-ŭp "],[" ŭiryŏngŭp "," Ŭiryŏng-ŭp "],[" ŭisŏngŭp "," Ŭisŏng-ŭp "],[" ŭich'angŭp "," Ŭich'ang-ŭp "],[" injeŭp "," Inje-ŭp "],[" illoŭp "," Illo-ŭp "],[" imsirŭp "," Imsir-ŭp "],[" changsŏngŭp "," Changsŏng-ŭp "],[" changsuŭp "," Changsu-ŭp "],[" changanŭp "," Changan-ŭp "],[" changhangŭp "," Changhang-ŭp "],[" changhowŏnŭp "," Changhowŏn-ŭp "],[" changhŭngŭp "," Changhŭng-ŭp "],[" chŏn'gogŭp "," Chŏn'gog-ŭp "],[" chŏnggwanŭp "," Chŏnggwan-ŭp "],[" chŏngsŏnŭp "," Chŏngsŏn-ŭp "],[" choriŭp "," Chori-ŭp "],[" choch'ŏnŭp "," Choch'ŏn-ŭp "],[" choch'iwŏnŭp "," Choch'iwŏn-ŭp "],[" chunaeŭp "," Chunae-ŭp "],[" chudŏgŭp "," Chudŏg-ŭp "],[" chumunjinŭp "," Chumunjin-ŭp "],[" chŭngp'yŏngŭp "," Chŭngp'yŏng-ŭp "],[" chidoŭp "," Chido-ŭp "],[" chiksanŭp "," Chiksan-ŭp "],[" chin'gŏnŭp "," Chin'gŏn-ŭp "],[" chindoŭp "," Chindo-ŭp "],[" chillyangŭp "," Chillyang-ŭp "],[" chinanŭp "," Chinan-ŭp "],[" chinyŏngŭp "," Chinyŏng-ŭp "],[" chinjŏbŭp "," Chinjŏb-ŭp "],[" chinch'ŏnŭp "," Chinch'ŏn-ŭp "],[" ch'angnyŏngŭp "," Ch'angnyŏng-ŭp "],[" ch'ŏrwŏnŭp "," Ch'ŏrwŏn-ŭp "],[" ch'ŏngdoŭp "," Ch'ŏngdo-ŭp "],[" ch'ŏngbugŭp "," Ch'ŏngbug-ŭp "],[" ch'ŏngsongŭp "," Ch'ŏngsong-ŭp "],[" ch'ŏngyangŭp "," Ch'ŏngyang-ŭp "],[" ch'owŏrŭp "," Ch'owŏr-ŭp "],[" ch'irwŏnŭp "," Ch'irwŏn-ŭp "],[" t'aeanŭp "," T'aean-ŭp "],[" t'ongjinŭp "," T'ongjin-ŭp "],[" p'aengsŏngŭp "," P'aengsŏng-ŭp "],[" p'yŏngch'angŭp "," P'yŏngch'ang-ŭp "],[" p'yŏnghaeŭp "," P'yŏnghae-ŭp "],[" p'ogogŭp "," P'ogog-ŭp "],[" p'osŭngŭp "," P'osŭng-ŭp "],[" p'unggiŭp "," P'unggi-ŭp "],[" p'ungsanŭp "," P'ungsan-ŭp "],[" hanamŭp "," Hanam-ŭp "],[" hadongŭp "," Hadong-ŭp "],[" hayangŭp "," Hayang-ŭp "],[" hallimŭp "," Hallim-ŭp "],[" hamyangŭp "," Hamyang-ŭp "],[" hamyŏrŭp "," Hamyŏr-ŭp "],[" hamch'angŭp "," Hamch'ang-ŭp "],[" hamp'yŏngŭp "," Hamp'yŏng-ŭp "],[" haptŏgŭp "," Haptŏg-ŭp "],[" hapch'ŏnŭp "," Hapch'ŏn-ŭp "],[" haenamŭp "," Haenam-ŭp "],[" hyangnamŭp "," Hyangnam-ŭp "],[" hongnongŭp "," Hongnong-ŭp "],[" hongbugŭp "," Hongbug-ŭp "],[" hongsŏngŭp "," Hongsŏng-ŭp "],[" hongch'ŏnŭp "," Hongch'ŏn-ŭp "] _
,[" hwadoŭp "," Hwado-ŭp "],[" hwasunŭp "," Hwasun-ŭp "],[" hwayangŭp "," Hwayang-ŭp "],[" hwawŏnŭp "," Hwawŏn-ŭp "],[" hwach'ŏnŭp "," Hwach'ŏn-ŭp "],[" hoengsŏngŭp "," Hoengsŏng-ŭp "]]

   For $i = 0 To Ubound($RuleGN, 1) - 1
	 $Result2 = StringRegExpReplace($Result2,$RuleGN[$i][0],$RuleGN[$i][1])
   Next

  ;FKR063
;~ Local $RuleKN[85][2] = [[" ch'ang taewang "," Ch'ang Taewang "],[" ch'ang wang "," Ch'ang Wang "],[" ch'angwang "," Ch'ang Wang "],[" Ch'ŏlchong taewang "," ch'ŏlchong Taewang "],[" ch'ŏnch'u t'aehu "," Ch'ŏnch'u T'aehu "],[" Chŏngjo taewang "," Chŏngjo Taewang "],[" Chŏngjong taewang "," Chŏngjong Taewang "],[" ch'unghye taewang "," Ch'unghye Taewang "],[" ch'unghye wang "," Ch'unghye Wang "],[" ch'unghyewang "," Ch'unghye Wang "],[" Chungjong taewang "," Chungjong Taewang "],[" ch'ungjŏng taewang "," Ch'ungjŏng Taewang "],[" ch'ungjŏng wang "," Ch'ungjŏng Wang "],[" ch'ungjŏngwang "," Ch'ungjŏng Wang "],[" ch'ungmogwang "," Ch'ungmok Wang "],[" ch'ungmok taewang "," Ch'ungmok Taewang "],[" ch'ungmok wang "," Ch'ungmok Wang "],[" ch'ungnyŏl taewang "," Ch'ungnyŏl Taewang "],[" ch'ungnyŏl wang "," Ch'ungnyŏl Wang "],[" ch'ungnyŏrwang "," Ch'ungnyŏl Wang "],[" ch'ungsŏn taewang "," Ch'ungsŏn Taewang "],[" ch'ungsŏn wang "," Ch'ungsŏn Wang "],[" ch'ungsŏnwang "," Ch'ungsŏn Wang "],[" ch'ungsugwang "," Ch'ungsuk Wang "],[" ch'ungsuk taewang "," Ch'ungsuk Taewang "],[" ch'ungsuk wang "," Ch'ungsuk Wang "],[" Hŏnjong taewang "," Hŏnjong Taewang "],[" hot'ae wang "," Hot'ae Wang "],[" hot'aewang "," Hot'ae Wang "],[" Hŭijong taewang "," Hŭijong Taewang "],[" Hyejong taewang "," Hyejong Taewang "],[" Hyojong taewang "," Hyojong Taewang "],[" Hyŏnjong taewang "," Hyŏnjong Taewang "],[" Injo taewang "," Injo Taewang "],[" Injong taewang "," Injong Taewang "],[" Kangjong taewang "," Kangjong Taewang "],[" Kojong hwangje "," Kojong Hwangje "],[" Kojong taewang "," Kojong Taewang "],[" kongmin taewang "," Kongmin Taewang "],[" kongmin wang "," Kongmin Wang "],[" kongminwang "," Kongmin Wang "],[" kongyang taewang "," Kongyang Taewang "],[" kongyang wang "," Kongyang Wang "],[" kongyangwang "," Kongyang Wang "],[" kwanggaet'o taewang "," Kwanggaet'o Taewang "],[" kwanggaet'o t'aewang "," Kwanggaet'o T'aewang "],[" kwanggaet'o wang "," Kwanggaet'o Wang "],[" kwanggaet'owang "," Kwanggaet'o Wang "],[" kwanghae kun "," Kwanghae Kun "],[" kwanghae taewang "," Kwanghae Taewang "],[" kwanghaegun "," Kwanghae Kun "],[" Kwangjong taewang "," Kwangjong Taewang "],[" Kyŏngjong taewang "," Kyŏngjong Taewang "],[" Mokchong taewang "," Mokchong Taewang "],[" Munjong taewang "," Munjong Taewang "],[" Myŏngjong taewang "," Myŏngjong Taewang "],[" myŏngsŏng hwanghu "," Myŏngsŏng Hwanghu "],[" Sejo taewang "," Sejo Taewang "],[" Sejong taewang "," Sejong Taewang "],[" Sinjong taewang "," Sinjong Taewang "],[" sohyŏn seja "," Sohyŏn Seja "],[" Sŏngjong taewang "," Sŏngjong Taewang "],[" Sŏnjong taewang "," Sŏnjong Taewang "],[" Sukchong taewang "," Sukchong Taewang "],[" Sunjo taewang "," Sunjo Taewang "],[" sunjong hwangje "," Sunjong Hwangje "],[" T'aejo taewang "," T'aejo Taewang "],[" T'aejong taewang "," T'aejong Taewang "],[" Tanjong taewang "," Tanjong Taewang "],[" Tŏkchong taewang "," Tŏkchong Taewang "],[" u taewang "," U Taewang "],[" u wang "," U Wang "],[" ŭi ch'inwang "," Ŭi Ch'inwang "],[" ŭich'inwang "," Ŭi Ch'inwang "],[" Ŭijong taewang "," Ŭijong Taewang "],[" uwang "," U Wang "],[" Wŏnjong taewang "," Wŏnjong Taewang "],[" Yejong taewang "," Yejong Taewang "],[" yŏng ch'inwang "," Yŏng Ch'inwang "],[" yŏngch'inwang "," Yŏng Ch'inwang "],[" Yŏngjo taewang "," Yŏngjo Taewang "],[" Yŏngjong taewang "," Yŏngjong Taewang "],[" yŏnsan kun "," Yŏnsan Kun "],[" yŏnsan taewang "," Yŏnsan Taewang "],[" yŏnsan'gun "," Yŏnsan Kun "]]
Local $RuleKN[215][2] = [[" adalla isagŭm "," Adalla Isagŭm "],[" aejangwang "," Aejang Wang "],[" anjangwang "," Anjang Wang "],[" anwŏnwang "," Anwŏn Wang "],[" asinwang "," Asin Wang "],[" chabi maripkan "," Chabi Maripkan "],[" chabiwang "," Chabi Wang "],[" ch'adaewang "," Ch'adae Wang "],[" ch'aekkyewang "," Ch'aekkye Wang "],[" ch'ang taewang "," Ch'ang Taewang "],[" ch'ang wang "," Ch'ang Wang "],[" changsuwang "," Changsu Wang "],[" ch'angwang "," Ch'ang Wang "],[" chijŭngwang "," Chijŭng Wang "],[" chima isagŭm "," Chima Isagŭm "],[" ch'imnyuwang "," Ch'imnyu Wang "],[" chindŏgyŏwang "," Chindŏk Yŏwang "],[" chindŏk yŏwang "," Chindŏk Yŏwang "],[" chinhŭngwang "," Chinhŭng Wang "],[" chinjiwang "," Chinji Wang "],[" chinp'yŏngwang "," Chinp'yŏng Wang "],[" chinsawang "," Chinsa Wang "],[" chinsŏng yŏwang "," Chinsŏng Yŏwang "],[" chinsŏngyŏwang "," Chinsŏng Yŏwang "],[" chobun isagŭm "," Chobun Isagŭm "],[" ch'ogowang "," Ch'ogo Wang "],[" Ch'ŏlchong taewang "," ch'ŏlchong Taewang "],[" ch'ŏmhae isagŭm "," Ch'ŏmhae Isagŭm "],[" ch'ŏnch'u t'aehu "," Ch'ŏnch'u T'aehu "],[" chŏnggangwang "," Chŏnggang Wang "],[" Chŏngjo taewang "," Chŏngjo Taewang "],[" Chŏngjong taewang "," Chŏngjong Taewang "],[" chŏnjiwang "," Chŏnji Wang "],[" chungch'ŏnwang "," Chungch'ŏn Wang "],[" ch'unghye taewang "," Ch'unghye Taewang "],[" ch'unghye wang "," Ch'unghye Wang "],[" ch'unghyewang "," Ch'unghye Wang "],[" Chungjong taewang "," Chungjong Taewang "],[" ch'ungjŏng taewang "," Ch'ungjŏng Taewang "],[" ch'ungjŏng wang "," Ch'ungjŏng Wang "],[" ch'ungjŏngwang "," Ch'ungjŏng Wang "],[" ch'ungmogwang "," Ch'ungmok Wang "],[" ch'ungmok taewang "," Ch'ungmok Taewang "],[" ch'ungmok wang "," Ch'ungmok Wang "],[" ch'ungnyŏl taewang "," Ch'ungnyŏl Taewang "],[" ch'ungnyŏl wang "," Ch'ungnyŏl Wang "],[" ch'ungnyŏrwang "," Ch'ungnyŏl Wang "],[" ch'ungsŏn taewang "," Ch'ungsŏn Taewang "],[" ch'ungsŏn wang "," Ch'ungsŏn Wang "],[" ch'ungsŏnwang "," Ch'ungsŏn Wang "],[" ch'ungsugwang "," Ch'ungsuk Wang "],[" ch'ungsuk taewang "," Ch'ungsuk Taewang "],[" ch'ungsuk wang "," Ch'ungsuk Wang "],[" hŏnanwang "," Hŏnan Wang "],[" hŏndŏgwang "," Hŏndŏk Wang "],[" hŏn'gangwang "," Hŏn'gang Wang "],[" Hŏnjong taewang "," Hŏnjong Taewang "],[" hot'ae wang "," Hot'ae Wang "],[" hot'aewang "," Hot'ae Wang "],[" hŭigangwang "," Hŭigang Wang "],[" Hŭijong taewang "," Hŭijong Taewang "],[" hŭngdŏgwang "," Hŭngdŏk Wang "],[" hŭrhae isagŭm "," Hŭrhae Isagŭm "],[" hyegongwang "," Hyegong Wang "],[" Hyejong taewang "," Hyejong Taewang "],[" hyewang "," Hye Wang "],[" hyogongwang "," Hyogong Wang "],[" Hyojong taewang "," Hyojong Taewang "],[" hyŏkkŏse kŏsŏgan "," Hyŏkkŏse Kŏsŏgan "],[" hyŏkkŏsewang "," Hyŏkkŏse Wang "],[" Hyŏnjong taewang "," Hyŏnjong Taewang "],[" hyosŏngwang "," Hyosŏng Wang "],[" hyosowang "," Hyoso Wang "],[" ilsŏng isagŭm "," Ilsŏng Isagŭm "],[" Injo taewang "," Injo Taewang "],[" Injong taewang "," Injong Taewang "],[" kaerowang "," Kaero Wang "],[" kaeruwang "," Kaeru Wang "],[" Kangjong taewang "," Kangjong Taewang "],[" kirim isagŭm "," Kirim Isagŭm "],[" kiruwang "," Kiru Wang "],[" kogugwŏnwang "," Kogugwŏn Wang "],[" kogugyangwang "," Kogugyang Wang "],[" kogukch'ŏnwang "," Kogukch'ŏn Wang "],[" koiwang "," Koi Wang "],[" Kojong hwangje "," Kojong Hwangje "],[" Kojong taewang "," Kojong Taewang "],[" kongmin taewang "," Kongmin Taewang "],[" kongmin wang "," Kongmin Wang "],[" kongminwang "," Kongmin Wang "],[" kongyang taewang "," Kongyang Taewang "],[" kongyang wang "," Kongyang Wang "],[" kongyangwang "," Kongyang Wang "],[" kuisinwang "," Kuisin Wang "],[" kŭnch'ogowang "," Kŭnch'ogo Wang "],[" kŭn'gusuwang "," Kŭn'gusu Wang "],[" kusuwang "," Kusu Wang "],[" kwanggaet'o taewang "," Kwanggaet'o Taewang "],[" kwanggaet'o t'aewang "," Kwanggaet'o T'aewang "],[" kwanggaet'o wang "," Kwanggaet'o Wang "],[" kwanggaet'odaewang "," Kwanggaet'o Taewang "] _
,[" kwanggaet'ot'aewang "," Kwanggaet'o T'aewang "],[" kwanggaet'owang "," Kwanggaet'o Wang "],[" kwanghae kun "," Kwanghae Kun "],[" kwanghae taewang "," Kwanghae Taewang "],[" kwanghaegun "," Kwanghae Kun "],[" Kwangjong taewang "," Kwangjong Taewang "],[" kyewang "," Kye Wang "],[" kyŏngaewang "," Kyŏngae Wang "],[" kyŏngdŏgwang "," Kyŏngdŏk Wang "],[" Kyŏngjong taewang "," Kyŏngjong Taewang "],[" kyŏngmunwang "," Kyŏngmun Wang "],[" kyŏngmyŏngwang "," Kyŏngmyŏng Wang "],[" kyŏngsunwang "," Kyŏngsun Wang "],[" mich'ŏnwang "," Mich'ŏn Wang "],[" mich'u isagŭm "," Mich'u Isagŭm "],[" minaewang "," Minae Wang "],[" minjungwang "," Minjung Wang "],[" mobonwang "," Mobon Wang "],[" Mokchong taewang "," Mokchong Taewang "],[" munchamyŏngwang "," Munjamyŏng Wang "],[" munchawang "," Munja Wang "],[" Munjong taewang "," Munjong Taewang "],[" munjuwang "," Munju Wang "],[" munmuwang "," Munmu Wang "],[" munsŏngwang "," Munsŏng Wang "],[" muryŏngwang "," Muryŏng Wang "],[" muwang "," Mu Wang "],[" muyŏrwang "," Muyŏl Wang "],[" Myŏngjong taewang "," Myŏngjong Taewang "],[" myŏngsŏng hwanghu "," Myŏngsŏng Hwanghu "],[" naehae isagŭm "," Naehae Isagŭm "],[" naemul maripkan "," Naemul Maripkan "],[" naemurwang "," Naemul Wang "],[" Namhae ch'ach'aung "," Namhae Ch'ach'aung "],[" namhaewang "," Namhae Wang "],[" nulji maripkan "," Nulchi Maripkan "],[" nuljiwang "," Nulchi Wang "],[" onjowang "," Onjo Wang "],[" p'asa isagŭm "," P'asa Isagŭm "],[" piryuwang "," Piryu Wang "],[" piyuwang "," Piyu Wang "],[" pŏbwang "," Pŏb Wang "],[" pojangwang "," Pojang Wang "],[" pongsangwang "," Pongsang Wang "],[" pŏphŭngwang "," Pŏphŭng Wang "],[" pŏrhyu isagŭm "," Pŏrhyu Isagŭm "],[" punsŏwang "," Punsŏ Wang "],[" p'yŏngwŏnwang "," P'yŏngwŏn Wang "],[" sabanwang "," Saban Wang "],[" samgŭnwang "," Samgŭn Wang "],[" sansangwang "," Sansang Wang "],[" Sejo taewang "," Sejo Taewang "],[" Sejong taewang "," Sejong Taewang "],[" silsŏng maripkan "," Silsŏng Maripkan "],[" sindaewang "," Sindae Wang "],[" Sinjong taewang "," Sinjong Taewang "],[" sinmunwang "," Sinmun Wang "],[" sinmuwang "," Sinmu Wang "],[" sŏch'ŏnwang "," Sŏch'ŏn Wang "],[" sohyŏn seja "," Sohyŏn Seja "],[" soji maripkan "," Soji Maripkan "],[" sojiwang "," Soji Wang "],[" sŏndŏgyŏwang "," Sŏndŏk Yŏwang "],[" sŏndŏk yŏwang "," Sŏndŏk Yŏwang "],[" sŏngdŏgwang "," Sŏngdŏk Wang "],[" Sŏngjong taewang "," Sŏngjong Taewang "],[" sŏngwang "," Sŏng Wang "],[" Sŏnjong taewang "," Sŏnjong Taewang "],[" sosŏngwang "," Sosŏng Wang "],[" sosurimwang "," Sosurim Wang "],[" Sukchong taewang "," Sukchong Taewang "],[" Sunjo taewang "," Sunjo Taewang "],[" sunjong hwangje "," Sunjong Hwangje "],[" T'aejo taewang "," T'aejo Taewang "],[" t'aejodaewang "," T'aejo Taewang "],[" T'aejong taewang "," T'aejong Taewang "],[" t'aejowang "," T'aejo Wang "],[" taemusinwang "," Taemusin Wang "],[" Tanjong taewang "," Tanjong Taewang "],[" t'arhae isagŭm "," T'arhae Isagŭm "],[" t'arhaewang "," T'arhae Wang "],[" taruwang "," Taru Wang "],[" Tŏkchong taewang "," Tŏkchong Taewang "],[" tongch'ŏnwang "," Tongch'ŏn Wang "],[" tongmyŏng Sŏng Wang "," Tongmyŏng Sŏngwang "],[" tongmyŏng sŏngwang "," Tongmyŏng Sŏngwang "],[" tongmyŏngsŏngwang "," Tongmyŏng Sŏngwang "],[" tongmyŏngwang "," Tongmyŏng Wang "],[" tongsŏngwang "," Tongsŏng Wang "],[" u taewang "," U Taewang "],[" u wang "," U Wang "],[" ŭi ch'inwang "," Ŭi Ch'inwang "],[" ŭich'inwang "," Ŭi Ch'inwang "],[" ŭijawang "," Ŭija Wang "],[" Ŭijong taewang "," Ŭijong Taewang "],[" uwang "," U Wang "],[" widŏgwang "," Widŏg Wang "],[" Wŏnjong taewang "," Wŏnjong Taewang "],[" wŏnsŏngwang "," Wŏnsŏng Wang "],[" yangwŏnwang "," Yangwŏn Wang "],[" Yejong taewang "," Yejong Taewang "],[" yŏng ch'inwang "," Yŏng Ch'inwang "],[" yŏngch'inwang "," Yŏng Ch'inwang "],[" Yŏngjo taewang "," Yŏngjo Taewang "],[" Yŏngjong taewang "," Yŏngjong Taewang "] _
,[" yŏngnyuwang "," Yŏngnyu Wang "],[" yŏngyangwang "," Yŏngyang Wang "],[" yŏnsan kun "," Yŏnsan Kun "],[" yŏnsan taewang "," Yŏnsan Taewang "],[" yŏnsan'gun "," Yŏnsan Kun "],[" yuri isagŭm "," Yuri Isagŭm "],[" yurimyŏngwang "," Yurimyŏng Wang "],[" yuriwang "," Yuri Wang "],[" yurye isagŭm "," Yurye Isagŭm "]]
   For $i = 0 To Ubound($RuleKN, 1) - 1
	 $Result2 = StringRegExpReplace($Result2,$RuleKN[$i][0],$RuleKN[$i][1])
   Next

   ;FKR064
   Local $RulePopN[66][2] = [[" kang kamch'an "," Kang Kam-ch'an "],[" kwak chaeu "," Kwak Chae-u "],[" kwŏn yul "," Kwŏn Yul "],[" kim ku "," Kim Ku "],[" kim taegŏn "," Kim Tae-gŏn "],[" kim taejung "," Kim Tae-jung "],[" kim pusik "," Kim Pu-sik "],[" kim satkat "," Kim Satkat "],[" kim sowŏl "," Kim So-wŏl "],[" kim yŏna "," Kim Yŏn-a "],[" kim yŏngnang "," Kim Yŏng-nang "],[" kim yŏngsam "," Kim Yŏng-sam "],[" kim okkyun "," Kim Ok-kyun "],[" kim yusin "," Kim Yu-sin "],[" kim chŏngho "," Kim Chŏng-ho "],[" kim chŏnghŭi "," Kim Chŏng-hŭi "],[" kim chwajin "," Kim Chwa-jin "],[" kim ch'unsu "," Kim Ch'un-su "],[" kim hongdo "," Kim Hong-do "],[" no muhyŏn "," No Mu-hyŏn "],[" tae choyŏng "," Tae Cho-yŏng "],[" mun chaein "," Mun Chae-in "],[" pak kŭnhye "," Pak Kŭn-hye "],[" pak wŏnsun "," Pak Wŏn-sun "],[" pak chŏnghŭi "," Pak Chŏng-hŭi "],[" pak chiyŏng "," Pak Chi-yŏng "],[" pak chiwŏn "," Pak Chi-wŏn "],[" pan kimun "," Pan Ki-mun "],[" sŏ hŭi "," Sŏ Hŭi "],[" son pyŏnghŭi "," Son Pyŏng-hŭi "],[" sin saimdang "," Sin Saimdang "],[" sin yunbok "," Sin Yun-bok "],[" an chunggŭn "," An Chung-gŭn "],[" an ch'angho "," An Ch'ang-ho "],[" an ch'ŏlsu "," An Ch'ŏl-su "],[" ŏm hyŏnju "," Ŏm Hyŏn-ju "],[" o ŭnsŭng "," O Ŭn-sŭng "],[" yu kwansun "," Yu Kwan-sun "],[" yu simin "," Yu Si-min "],[" yun tongju "," Yun Tong-ju "],[" yun ponggil "," Yun Pong-gil "],[" i myŏngbak "," Yi Myŏng-bak "],[" i sunsin "," Yi Sun-sin "],[" i hyŏngbae "," Yi Hyŏng-bae "],[" isabu "," Isabu "],[" ich'adon "," Ich'adon "],[" chang pogo "," Chang Po-go "],[" chang sŭngŏp "," Chang Sŭng-ŏp "],[" chang yŏngsil "," Chang Yŏng-sil "],[" chŏn pongjun "," Chŏn Pong-jun "],[" chŏng tojŏn "," Chŏng To-jŏn "],[" chŏng mongju "," Chŏng Mong-ju "],[" chŏng yagyong "," Chŏng Yag-yong "],[" chŏng unch'an "," Chŏng Un-ch'an "],[" cho kwangjo "," Cho Kwang-jo "],[" cho sik "," Cho Sik "],[" chu sigyŏng "," Chu Si-gyŏng "],[" chi sŏgyŏng "," Chi Sŏg-yŏng "],[" ch'oe musŏn "," Ch'oe Mu-sŏn "],[" ch'oe yŏng "," Ch'oe Yŏng "],[" han sŏkpong "," Han Sŏk-pong "],[" hŏ kyun "," Hŏ Kyun "],[" hŏ nansŏrhŏn "," Hŏ Nansŏrhŏn "],[" hong kyŏngnae "," Hong Kyŏng-nae "],[" hong kildong "," Hong Kil-tong "],[" hwang hŭi "," Hwang Hŭi "]]
   For $i = 0 To Ubound($RulePopN, 1) - 1
	 $Result2 = StringRegExpReplace($Result2,$RulePopN[$i][0],$RulePopN[$i][1])
   Next

   ; FKR065
   Local $Rule1[4][2] = [[" U Wang chwawang "," uwang chwawang "],[" hancha "," Hancha "],[" hanchaŏ "," Hanchaŏ "],[" ch'ŏlchong "," Ch'ŏlchong "]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Result2 = StringRegExpReplace($Result2, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next

   ; FKR066
   $Result2 = StringReplace($Result2,'Q SB','Q  SB')
   Local $Rule[$CountSymb][2] = [[' SB01KQ ',' ! '],[' SB02KQ ',' " '],[' SB03KQ ',' # '],[' SB04KQ ',' $ '],[' SB05KQ ',' % '],[' SB06KQ ',' & '],[' SB07KQ '," ' "],[' SB08KQ ',' ( '],[' SB09KQ ',' ) '],[' SB10KQ ',' * '],[' SB11KQ ',' + '],[' SB12KQ ',' , '],[' SB13KQ ',' - '],[' SB14KQ ',' . '],[' SB15KQ ',' / '],[' SB16KQ ',' : '],[' SB17KQ ',' ; '],[' SB18KQ ',' < '],[' SB19KQ ',' = '],[' SB20KQ ',' > '],[' SB21KQ ',' ? '],[' SB22KQ ',', '],[' SB23KQ ',' ǂ '],[' SB24KQ ',' 「 '],[' SB25KQ ',' 」 '],[' SB26KQ ',' 『 '],[' SB27KQ ',' 』 '],[' SB28KQ ',' @ '],[' SB29KQ ',' [ '],[' SB30KQ ',' \ '],[' SB31KQ ',' ] '],[' SB32KQ ',' ^ '],[' SB33KQ ',' _ '],[' SB34KQ ',' ` '],[' SB35KQ ',' { '],[' SB36KQ ',' | '],[' SB37KQ ',' } '],[' SB38KQ ',' ~ '],[' SB39KQ ',' ‡ '],[' SB40KQ ',' ‰  '],[' SB41KQ ',' ‘ '],[' SB42KQ ',' ’ '],[' SB43KQ ',' “ '],[' SB44KQ ',' ” '],[' SB45KQ ',' – '],[' SB46KQ ',' — '],[' SB47KQ ',' ˜ '],[' SB48KQ ',' © '],[' SB49KQ ',', ']]
   For $i = 0 To Ubound($Rule, 1) - 1
	  $Result2 = StringRegExpReplace($Result2, "\Q" & $Rule[$i][0] & "\E",$Rule[$i][1])
   Next
   Local $Rule[$CountSymb][2] = [[' SB01CQ ',' !'],[' SB02CQ ',' "'],[' SB03CQ ',' #'],[' SB04CQ ',' $'],[' SB05CQ ',' %'],[' SB06CQ ',' &'],[' SB07CQ '," '"],[' SB08CQ ',' ('],[' SB09CQ ',' )'],[' SB10CQ ',' *'],[' SB11CQ ',' +'],[' SB12CQ ',' ,'],[' SB13CQ ',' -'],[' SB14CQ ',' .'],[' SB15CQ ',' /'],[' SB16CQ ',' :'],[' SB17CQ ',' ;'],[' SB18CQ ',' <'],[' SB19CQ ',' ='],[' SB20CQ ',' >'],[' SB21CQ ',' ?'],[' SB22CQ ',','],[' SB23CQ ',' ǂ'],[' SB24CQ ',' 「'],[' SB25CQ ',' 」'],[' SB26CQ ',' 『'],[' SB27CQ ',' 』'],[' SB28CQ ',' @'],[' SB29CQ ',' ['],[' SB30CQ ',' \'],[' SB31CQ ',' ]'],[' SB32CQ ',' ^'],[' SB33CQ ',' _'],[' SB34CQ ',' `'],[' SB35CQ ',' {'],[' SB36CQ ',' |'],[' SB37CQ ',' }'],[' SB38CQ ',' ~'],[' SB39CQ ',' ‡'],[' SB40CQ ',' ‰ '],[' SB41CQ ',' ‘'],[' SB42CQ ',' ’'],[' SB43CQ ',' “'],[' SB44CQ ',' ”'],[' SB45CQ ',' –'],[' SB46CQ ',' —'],[' SB47CQ ',' ˜'],[' SB48CQ ',' ©'],[' SB49CQ ',', ']]
   For $i = 0 To Ubound($Rule, 1) - 1
	  $Result2 = StringRegExpReplace($Result2, "\Q" & $Rule[$i][0] & "\E",$Rule[$i][1])
   Next
   Local $Rule[$CountSymb][2] = [[' SB01TQ ','! '],[' SB02TQ ','" '],[' SB03TQ ','# '],[' SB04TQ ','$ '],[' SB05TQ ','% '],[' SB06TQ ','& '],[' SB07TQ ',"' "],[' SB08TQ ','( '],[' SB09TQ ',') '],[' SB10TQ ','* '],[' SB11TQ ','+ '],[' SB12TQ ',', '],[' SB13TQ ','- '],[' SB14TQ ','. '],[' SB15TQ ','/ '],[' SB16TQ ',': '],[' SB17TQ ','; '],[' SB18TQ ','< '],[' SB19TQ ','= '],[' SB20TQ ','> '],[' SB21TQ ','? '],[' SB22TQ ',', '],[' SB23TQ ','ǂ '],[' SB24TQ ','「 '],[' SB25TQ ','」 '],[' SB26TQ ','『 '],[' SB27TQ ','』 '],[' SB28TQ ','@ '],[' SB29TQ ','[ '],[' SB30TQ ','\ '],[' SB31TQ ','] '],[' SB32TQ ','^ '],[' SB33TQ ','_ '],[' SB34TQ ','` '],[' SB35TQ ','{ '],[' SB36TQ ','| '],[' SB37TQ ','} '],[' SB38TQ ','~ '],[' SB39TQ ','‡ '],[' SB40TQ ','‰  '],[' SB41TQ ','‘ '],[' SB42TQ ','’ '],[' SB43TQ ','“ '],[' SB44TQ ','” '],[' SB45TQ ','– '],[' SB46TQ ','— '],[' SB47TQ ','˜ '],[' SB48TQ ','© '],[' SB49TQ ',', ']]
   For $i = 0 To Ubound($Rule, 1) - 1
	  $Result2 = StringRegExpReplace($Result2, "\Q" & $Rule[$i][0] & "\E",$Rule[$i][1])
   Next
   Local $Rule[$CountSymb][2] = [[' SB01PQ ','!'],[' SB02PQ ','"'],[' SB03PQ ','#'],[' SB04PQ ','$'],[' SB05PQ ','%'],[' SB06PQ ','&'],[' SB07PQ ',"'"],[' SB08PQ ','('],[' SB09PQ ',')'],[' SB10PQ ','*'],[' SB11PQ ','+'],[' SB12PQ ',','],[' SB13PQ ','-'],[' SB14PQ ','.'],[' SB15PQ ','/'],[' SB16PQ ',':'],[' SB17PQ ',';'],[' SB18PQ ','<'],[' SB19PQ ','='],[' SB20PQ ','>'],[' SB21PQ ','?'],[' SB22PQ ',','],[' SB23PQ ','ǂ'],[' SB24PQ ','「'],[' SB25PQ ','」'],[' SB26PQ ','『'],[' SB27PQ ','』'],[' SB28PQ ','@'],[' SB29PQ ','['],[' SB30PQ ','\'],[' SB31PQ ',']'],[' SB32PQ ','^'],[' SB33PQ ','_'],[' SB34PQ ','`'],[' SB35PQ ','{'],[' SB36PQ ','|'],[' SB37PQ ','}'],[' SB38PQ ','~'],[' SB39PQ ','‡'],[' SB40PQ ','‰ '],[' SB41PQ ','‘'],[' SB42PQ ','’'],[' SB43PQ ','“'],[' SB44PQ ','”'],[' SB45PQ ','–'],[' SB46PQ ','—'],[' SB47PQ ','˜'],[' SB48PQ ','©'],[' SB49PQ ',', ']]
   For $i = 0 To Ubound($Rule, 1) - 1
	  $Result2 = StringRegExpReplace($Result2, "\Q" & $Rule[$i][0] & "\E",$Rule[$i][1])
   Next
   ;FKR067

   $Result2 = (StringStripWS($Result2,1+2+4))
   ClipPut ($Result2)

EndFunc

Func KorRom() ; FKR068
   $LEN = StringLen(StringStripWS(ClipGet(),1+2+4))
   $TargetKor = ClipGet()
   $TargetKorOrig = $TargetKor

; FKR069
   Local $ExSet[57][2] = [['학여울역','학여울력'],['값어치','가버치'],['굶기고','굼기고'],['굶기는','굼기는'],['굶기다','굼기다'],['굶기지','굼기지'],['끝음절','끄듬절'],['끝인사','끄딘사'],['넷우익','네두익'],['덧인쇄','더딘쇄'],['삶기고','삼기고'],['삶기는','삼기는'],['삶기다','삼기다'],['삶기지','삼기지'],['옮기고','옴기고'],['옮기는','옴기는'],['옮기다','옴기다'],['옮기지','옴기지'],['웃어른','우더른'],['첫아기','처다기'],['첫아들','처다들'],['첫아이','처다이'],['첫울음','처두름'],['첫음절','처듬절'],['첫인사','처딘사'],['첫인상','처딘상'],['학여울','항녀울'],['헛웃음','허두슴'],['값없','가벖'],['값있','가빘'],['겉옷','거돗'],['굶겨','굼겨'],['굶겼','굼겼'],['굶긴','굼긴'],['굶김','굼김'],['끝없','끄덦'],['넓둥','넙둥'],['넓적','넙적'],['넓죽','넙죽'],['덧없','더없'],['덧옷','더돗'],['맏형','마텽'],['밟고','밥고'],['밟다','밥다'],['밟소','밥소'],['밟지','밥지'],['삶겨','삼겨'],['삶겼','삼겼'],['삶긴','삼긴'],['삶김','삼김'],['셋업','세덥'],['옮겨','옴겨'],['옮겼','옴겼'],['옮긴','옴긴'],['옮김','옴김'],['윗옷','위돗'],['첫애','처대']]
   For $i = 0 To Ubound($ExSet, 1) - 1
	  $TargetKor = StringRegExpReplace($TargetKor, "\Q" & $ExSet[$i][0] & "\E",$ExSet[$i][1])
   Next

; FKR070
   If StringInStr($TargetKor,"+")>0 Then
	  $Niun=StringInStr($TargetKor,"+",0,1)
	  $TargetKor = StringReplace($TargetKor,"+","")
	  $TargetKorOrig = $TargetKor
   Else
	  $Niun=0
   EndIf

   $NonKor = 0
   $NonKorCount = 0 ; UNUSED
   Local $aArray = StringToASCIIArray ($TargetKor)

   Sleep (100)
   For $i=0 to Ubound($aArray, 1)-1
	  If Number($aArray[$i]) < 44032 Then
		 $NonKor = $NonKor+1
		 $TargetKor = StringTrimLeft($TargetKor,1)
	  EndIf
   Next
   Sleep (100)

   Local $aArray = StringToASCIIArray ($TargetKor)

   If StringLen($TargetKor) > 0 Then
	  $ASCII1 = Number($aArray[0])-44032
	  $Target = $ASCII1
	  $Ini1 = "i" & FLOOR(Number($Target)/588)
	  $Med1 = "m" & MOD(FLOOR(Number($Target)/28),21)
	  $Fin1 = "f" & MOD(Number($Target),28)
	  If StringLen($TargetKor) > 1 Then
		 $ASCII2 = Number($aArray[1])-44032
		 $Target = $ASCII2
		 $Ini2 = "i" & FLOOR(Number($Target)/588)
		 $Med2 = "m" & MOD(FLOOR(Number($Target)/28),21)
		 $Fin2 = "f" & MOD(Number($Target),28)
		 If StringLen($TargetKor) > 2 Then
			$ASCII3 = Number($aArray[2])-44032
			$Target = $ASCII3
			$Ini3 = "i" & FLOOR(Number($Target)/588)
			$Med3 = "m" & MOD(FLOOR(Number($Target)/28),21)
			$Fin3 = "f" & MOD(Number($Target),28)
			If StringLen($TargetKor) > 3 Then
			   $ASCII4 = Number($aArray[3])-44032
			   $Target = $ASCII4
			   $Ini4 = "i" & FLOOR(Number($Target)/588)
			   $Med4 = "m" & MOD(FLOOR(Number($Target)/28),21)
			   $Fin4 = "f" & MOD(Number($Target),28)
			   If StringLen($TargetKor) > 4 Then
				  $ASCII5 = Number($aArray[4])-44032
				  $Target = $ASCII5
				  $Ini5 = "i" & FLOOR(Number($Target)/588)
				  $Med5 = "m" & MOD(FLOOR(Number($Target)/28),21)
				  $Fin5 = "f" & MOD(Number($Target),28)
				  If StringLen($TargetKor) > 5 Then
					 $ASCII6 = Number($aArray[5])-44032
					 $Target = $ASCII6
					 $Ini6 = "i" & FLOOR(Number($Target)/588)
					 $Med6 = "m" & MOD(FLOOR(Number($Target)/28),21)
					 $Fin6 = "f" & MOD(Number($Target),28)
					 If StringLen($TargetKor) > 6 Then
						$ASCII7 = Number($aArray[6])-44032
						$Target = $ASCII7
						$Ini7 = "i" & FLOOR(Number($Target)/588)
						$Med7 = "m" & MOD(FLOOR(Number($Target)/28),21)
						$Fin7 = "f" & MOD(Number($Target),28)
						If StringLen($TargetKor) > 7 Then
						   $ASCII8 = Number($aArray[7])-44032
						   $Target = $ASCII8
						   $Ini8 = "i" & FLOOR(Number($Target)/588)
						   $Med8 = "m" & MOD(FLOOR(Number($Target)/28),21)
						   $Fin8 = "f" & MOD(Number($Target),28)
						   If StringLen($TargetKor) > 8 Then
							  $ASCII9 = Number($aArray[8])-44032
							  $Target = $ASCII9
							  $Ini9 = "i" & FLOOR(Number($Target)/588)
							  $Med9 = "m" & MOD(FLOOR(Number($Target)/28),21)
							  $Fin9 = "f" & MOD(Number($Target),28)
							  $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "~" & $Ini5 & "#" & $Med5 & "#" & $Fin5 &  "~" & $Ini6 & "#" & $Med6 & "#" & $Fin6 &  "~" & $Ini7 & "#" & $Med7 & "#" & $Fin7  &  "~" & $Ini8 & "#" & $Med8 & "#" & $Fin8  &  "~" & $Ini9 & "#" & $Med9 & "#" & $Fin9 & "E"
						   Else
							  $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "~" & $Ini5 & "#" & $Med5 & "#" & $Fin5 &  "~" & $Ini6 & "#" & $Med6 & "#" & $Fin6 &  "~" & $Ini7 & "#" & $Med7 & "#" & $Fin7  &  "~" & $Ini8 & "#" & $Med8 & "#" & $Fin8 & "E"
						   EndIf
						Else
						   $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "~" & $Ini5 & "#" & $Med5 & "#" & $Fin5 &  "~" & $Ini6 & "#" & $Med6 & "#" & $Fin6 &  "~" & $Ini7 & "#" & $Med7 & "#" & $Fin7 & "E"
						EndIf
					 Else
						$Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "~" & $Ini5 & "#" & $Med5 & "#" & $Fin5 &  "~" & $Ini6 & "#" & $Med6 & "#" & $Fin6 & "E"
					 EndIf
				  Else
					 $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "~" & $Ini5 & "#" & $Med5 & "#" & $Fin5 & "E"
				  EndIf
			   Else
				  $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "E"
			   EndIf
			Else
			   $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "E"
			EndIf
		 Else
			$Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "E"
		 EndIf
	  Else
		 $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "E"
	  EndIf

; FKR071
If $Niun=0 Then
Else
   $NiunLocation=StringInStr($Rom,"~",0,$Niun-1)
   $RomNiunA = StringLeft($Rom,$NiunLocation-1)
   $RomNiunB = StringTrimLeft($Rom,$NiunLocation)
   If StringInStr($RomNiunB,"i11#m2")=1 Then
	  $RomNiunB = StringReplace($RomNiunB,"i11#m2","i2#m2",1)
	  $Rom = $RomNiunA & "~" & $RomNiunB
   EndIf
   If StringInStr($RomNiunB,"i11#m6")=1 Then
	  $RomNiunB = StringReplace($RomNiunB,"i11#m6","i2#m6",1)
	  $Rom = $RomNiunA & "~" & $RomNiunB
   EndIf
   If StringInStr($RomNiunB,"i11#m12")=1 Then
	  $RomNiunB = StringReplace($RomNiunB,"i11#m12","i2#m12",1)
	  $Rom = $RomNiunA & "~" & $RomNiunB
   EndIf
   If StringInStr($RomNiunB,"i11#m17")=1 Then
	  $RomNiunB = StringReplace($RomNiunB,"i11#m17","i2#m17",1)
	  $Rom = $RomNiunA & "~" & $RomNiunB
   EndIf
   If StringInStr($RomNiunB,"i11#m20")=1 Then
	  $RomNiunB = StringReplace($RomNiunB,"i11#m20","i2#m20",1)
	  $Rom = $RomNiunA & "~" & $RomNiunB
   EndIf
   ; FKR072
   If StringInStr($RomNiunB,"i5#")=1 AND StringRight($RomNiunA,2)="f4" Then
	  $RomNiunB = StringReplace($RomNiunB,"i5#","i2",1)
	  $Rom = $RomNiunA & "~" & $RomNiunB
   EndIf

EndIf


;FKR073
If StringInStr($Rom,"f7~")>0 Then
   Local $Rule1[4][2] = [["f7~i11#m20","f0~i12#m20"],["f7~i11#m6","f0~i12#m6"],["f7~i18#m20","f0~i14#m20"],["f7~i18#m6","f0~i14#m6"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR074
If StringInStr($Rom,"f25~")>0 Then
   Local $Rule1[4][2] = [["f25~i11#m20","f0~i14#m20"],["f25~i11#m6","f0~i14#m6"],["f25~i18#m20","f0~i14#m20"],["f25~i18#m6","f0~i14#m6"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR075
If StringInStr($Rom,"f1~")>0 Then
   Local $Rule1[3][2] = [["f1~i2#","f21~i2#"],["f1~i5#","f21~i2#"],["f1~i6#","f21~i6#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR076
If StringInStr($Rom,"f2~")>0 Then
   Local $Rule1[4][2] = [["f2~i2#","f21~i2#"],["f2~i5#","f21~i2#"],["f2~i6#","f21~i6#"],["f2~i11#","f0~i1#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

If StringInStr($Rom,"f3~")>0 Then
;FKR077
   Local $Rule1[5][2] = [["f3~i0#","k~k"],["f3~i2#","ng~n"],["f3~i5#","ng~n"],["f3~i6#","ng~m"],["f3~i11#","k~s"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR078
If StringInStr($Rom,"f4~")>0 Then
   Local $Rule1[1][2] = [["f4~i5#","f8~i5#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR079
$CountNC = "0" ; This never changes
If StringInStr($Rom,"f5~")>0 Then
   Local $Rule1[4][2] = [["f5~i0#","n~k"],["f5~i2#","n~n"],["f5~i3#","n~t"],["f5~i12#","n~ch"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR080
If StringInStr($Rom,"f6~")>0 Then
   Local $Rule1[4][2] = [["f6~i0#","f4~i15#"],["f6~i2#","f4~i2#"],["f6~i3#","f4~i16#"],["f6~i12#","f4~i14#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR081
If StringInStr($Rom,"f7~")>0 Then
   Local $Rule1[3][2] = [["f7~i2#","f4~i2#"],["f7~i5#","f4~i2#"],["f7~i6#","f4~i6#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR082
If StringInStr($Rom,"f8~")>0 Then
   Local $Rule1[1][2] = [["f8~i2#","f8~i5#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR083
$CountLK = "0" ; This never changes
If StringInStr($Rom,"f9~")>0 Then
   Local $Rule1[4][2] = [["f9~i0#","l~k"],["f9~i2#","ng~n"],["f9~i3#","k~t"],["f9~i12#","k~ch"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR084
$CountLM = "0" ; This never changes
If StringInStr($Rom,"f10~")>0 Then
   Local $Rule1[4][2] = [["f10~i0#","m~k"],["f10~i2#","m~n"],["f10~i3#","m~t"],["f10~i12#","m~ch"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR085
$CountLP = "0" ; This never changes
If StringInStr($Rom,"f11~")>0 Then
   Local $Rule1[4][2] = [["f11~i0#","l~k"],["f11~i2#","m~n"],["f11~i3#","l~t"],["f11~i12#","l~ch"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR086
$CountLTH = "0" ; This never changes
If StringInStr($Rom,"f13~")>0 Then
   Local $Rule1[4][2] = [["f13~i0#","l~k"],["f13~i2#","l~l"],["f13~i3#","l~t"],["f13~i12#","l~ch"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR087
$CountLPH = "0" ; This never changes
If StringInStr($Rom,"f14~")>0 Then
   Local $Rule1[4][2] = [["f14~i0#","p~k"],["f14~i2#","m~n"],["f14~i3#","p~t"],["f14~i12#","p~ch"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR088
If StringInStr($Rom,"f15~")>0 Then
   Local $Rule1[4][2] = [["f15~i0#","f8~i15#"],["f15~i2#","f8~i5#"],["f15~i3#","f8~i16#"],["f15~i12#","f8~i14#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR089
If StringInStr($Rom,"f16~")>0 Then
   Local $Rule1[1][2] = [["f16~i5#","f16~i2#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR090
If StringInStr($Rom,"f17~")>0 Then
   Local $Rule1[3][2] = [["f17~i2#","f16~i2#"],["f17~i5#","f16~i2#"],["f17~i6#","f16~i6#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR091
If StringInStr($Rom,"f18~")>0 Then
   Local $Rule1[8][2] = [["f18~i0#","f17~i0#"],["f18~i2#","f16~i2#"],["f18~i3#","f17~i3#"],["f18~i5#","f16~i2#"],["f18~i6#","f16~i6#"],["f18~i9#","f17~i9#"],["f18~i11#","f17~i9#"],["f18~i12#","f17~i12#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR092
If StringInStr($Rom,"f19~")>0 Then
   Local $Rule1[4][2] = [["f19~i2#","f4~i2#"],["f19~i5#","f4~i2#"],["f19~i6#","f4~i6#"],["f19~i11#","f0~i9#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR093
If StringInStr($Rom,"f20~")>0 Then
   Local $Rule1[4][2] = [["f20~i2#","f4~i2#"],["f20~i5#","f4~i2#"],["f20~i6#","f4~i6#"],["f20~i11#","f0~i10#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR094
If StringInStr($Rom,"f21~")>0 Then
   Local $Rule1[1][2] = [["f21~i5#","f21~i2#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR095
If StringInStr($Rom,"f22~")>0 Then
   Local $Rule1[5][2] = [["f22~i2#","f4~i2#"],["f22~i5#","f4~i2#"],["f22~i6#","f4~i6#"],["f22~i11#","f0~i12#"],["f22~i18#","f0~i14#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR096
If StringInStr($Rom,"f23~")>0 Then
   Local $Rule1[5][2] = [["f23~i2#","f4~i2#"],["f23~i5#","f4~i2#"],["f23~i6#","f4~i6#"],["f23~i11#","f0~i14#"],["f23~i18#","f0~i14#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR097
If StringInStr($Rom,"f24~")>0 Then
   Local $Rule1[2][2] = [["f24~i2#","f21~i2#"],["f24~i6#","f21~i6#"],["f24~i11#","f0~i15#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR098
If StringInStr($Rom,"f25~")>0 Then
   Local $Rule1[3][2] = [["f25~i2#","f4~i2#"],["f25~i6#","f4~i6#"],["f25~i11#","f0~i16#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR099
If StringInStr($Rom,"f26~")>0 Then
   Local $Rule1[3][2] = [["f26~i2#","f16~i2#"],["f26~i6#","f16~i6#"],["f26~i11#","f0~i17#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR100
If StringInStr($Rom,"f27~")>0 Then
   Local $Rule1[8][2] = [["f27~i0#","f0~i15#"],["f27~i2#","f4~i2#"],["f27~i3#","f0~i16#"],["f27~i5#","f4~i2#"],["f27~i6#","f4~i6#"],["f27~i7#","f0~i17#"],["f27~i11#","f0~i11#"],["f27~i12#","f0~i14#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next
EndIf

;FKR101
   Local $Rule1[9][2] = [["f5~i11#","f4~i12#"],["f6~i11#","f4~i11#"],["f9~i11#","f8~i0#"],["f10~i11#","f8~i6#"],["f11~i11#","f8~i7#"],["f12~i11#","f8~i9#"],["f13~i11#","f8~i16#"],["f14~i11#","f8~i17#"],["f15~i11#","f8~i11#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next

;FKR102
   Local $Rule1[8][2] = [["f5~i18#","f4~i14#"],["f6~i18#","f4~i18#"],["f9~i18#","f8~i15#"],["f10~i18#","f16~i18#"],["f11~i18#","f8~i17#"],["f13~i18#","f8~i16#"],["f14~i18#","f8~i17#"],["f15~i18#","f8~i18#"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next

;FKR103
   If $CountLK+$CountLM+$CountLP+$CountLPH+$CountLTH+$CountNC = "0" Then  ; Always true
	  Local $Rule1[18][2] = [["f0~i0#","~g"],["f0~i3#","~d"],["f0~i7#","~b"],["f0~i12#","~j"],["f4~i0#","n~g"],["f4~i3#","n~d"],["f4~i7#","n~b"],["f4~i12#","n~j"],["f8~i0#","l~g"],["f8~i7#","l~b"],["f16~i0#","m~g"],["f16~i3#","m~d"],["f16~i7#","m~b"],["f16~i12#","m~j"],["f21~i0#","ng~g"],["f21~i3#","ng~d"],["f21~i7#","ng~b"],["f21~i12#","ng~j"]]
	  For $i = 0 To Ubound($Rule1, 1) - 1
		 $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
	  Next
   EndIf

;FKR104
   Local $Rule1[4][2] = [["f1~i11#","g~"],["f7~i11#","d~"],["f17~i11#","b~"],["f22~i11#","j~"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next

;FKR105
   If $CountLK+$CountLM+$CountLP+$CountLPH+$CountLTH+$CountNC = "0" Then  ; Always true
	  Local $Rule1[2][2] = [["f8~i3#","l~d"],["f8~i12#","l~j"]]
	  For $i = 0 To Ubound($Rule1, 1) - 1
		 $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
	  Next
   EndIf

;FKR106
   Local $FinRule[27][2] = [["f1E","f1"],["f2E","f1"],["f3E","f1"],["f4E","f4"],["f5E","f4"],["f6E","f4"],["f7E","f7"],["f8E","f8"],["f9E","f1"],["f10E","f16"],["f11E","f8"],["f12E","f8"],["f13E","f8"],["f14E","f17"],["f15E","f8"],["f16E","f16"],["f17E","f17"],["f18E","f17"],["f19E","f7"],["f20E","f7"],["f21E","f21"],["f22E","f7"],["f23E","f7"],["f24E","f1"],["f25E","f7"],["f26E","f17"],["f27E","f7"]]
   For $i = 0 To Ubound($FinRule, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $FinRule[$i][0] & "\E",$FinRule[$i][1])
   Next

;FKR107
   $Rom = StringReplace ($Rom,"i9#m16","shwi")

;FKR108
   $Rom = StringReplace ($Rom,"n~g","n'g")

;FKR109
   Local $Initials[19][2] = [["i10","ss"],["i11",""],["i12","ch"],["i13","tch"],["i14","ch'"],["i15","k'"],["i16","t'"],["i17","p'"],["i18","h"],["i0","k"],["i1","kk"],["i2","n"],["i3","t"],["i4","tt"],["i5","r"],["i6","m"],["i7","p"],["i8","pp"],["i9","s"]]
   For $i = 0 To Ubound($Initials, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Initials[$i][0] & "\E",$Initials[$i][1])
   Next

   Local $Medials[22][2] = [["m10","wae"],["m11","oe"],["m12","yo"],["m13","u"],["m14","wŏ"],["m15","we"],["m16","wi"],["m17","yu"],["m18","ŭ"],["m19","ŭi"],["m20","i"],["m0","a"],["m1","ae"],["m2","ya"],["m3","yae"],["m4","ŏ"],["m5","e"],["m6","yŏ"],["m7","ye"],["m8","o"],["m9","wa"],["f0E","f0"]]
   For $i = 0 To Ubound($Medials, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Medials[$i][0] & "\E",$Medials[$i][1])
   Next

   Local $Finals[28][2] = [["f10","m"],["f11","l"],["f12","l"],["f13","l"],["f14","p"],["f15","l"],["f16","m"],["f17","p"],["f18","p"],["f19","t"],["f20","t"],["f21","ng"],["f22","t"],["f23","t"],["f24","k"],["f25","t"],["f26","p"],["f27","t"],["f1","k"],["f2","k"],["f3","k"],["f4","n"],["f5","n"],["f6","n"],["f7","t"],["f8","l"],["f9","k"],["f0",""]]
   For $i = 0 To Ubound($Finals, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Finals[$i][0] & "\E",$Finals[$i][1])
   Next

;FKR110
$Rom = StringReplace($Rom,"#","")
$Rom = StringReplace($Rom,"~","")

If $NonKor > 0 Then
   $Rom = StringLeft($TargetKorOrig,$NonKor) & "-" & $Rom
EndIf

;FKR111
   Local $Rule1[11][2] = [["la","ra"],["li","ri"],["le","re"],["lo","ro"],["lu","ru"],["lh","rh"],["lŏ","rŏ"],["lŭ","rŭ"],["ly","ry"],["lw","rw"],["lr","ll"]]
   For $i = 0 To Ubound($Rule1, 1) - 1
	  $Rom = StringRegExpReplace($Rom, "\Q" & $Rule1[$i][0] & "\E",$Rule1[$i][1])
   Next

   ; FKR112
   $IsNonKor = 0

;FKR113
   Local $Rule1[61] = ["냐","뉴","니","랃","랏","랙","랜","랟","랠","램","랩","랫","랴","랸","랻","랼","럄","럅","럇","러","럭","런","럴","럼","럽","럿","렁","레","렉","렌","렐","렘","렙","렛","렝","렷","롄","롤","롬","롭","롯","롸","뢴","룀","룩","룬","룰","룸","룹","룻","룽","뤄","뤼","뤽","륀","르","른","릭","릴","릿","링"]
   For $i = 0 To Ubound($Rule1)-1
	  If StringLeft(StringStripWS($TargetKorOrig,8),1)=$Rule1[$i] Then
		 $IsNonKor=$IsNonKor+1
	  EndIf
   Next

   Local $LoanWSet[107] = ['녀석','라디','라마','라미','라스','라오스','라운드','라이','라트비','라틴','래스','레슨','레터','로고스','로그','로댕','로데오','로뎀','로드','로레','로렌','로마','로만','로망','로맨','로미','로미오','로버','로베','로보트','로보틱','로봇','로비스','로빈','로스','로얄','로이','로이드','로자리','로잔','로제타','로즈','로지','로직','로칼','로컬','로터','로테','로펌','록펠','료마','루마니','루미','루벤','루스','루이','루트','리눅','리니','리더','리드','리듬','리디','리딩','리메','리멤','리모델','리모트','리미트','리바','리버','리베','리본','리뷰','리비아','리빙','리빠','리사이','리셋','리스','리싸','리액','리얼','리우','리움','리조트','리즈','리차드','리처드','리커','리코','리콜','리터','리턴','리토피','리투아','리트','리튼','리틀','리퍼','리포터','리포트','리플','리허','리히텐','림프','립스']
   For $i = 0 To Ubound($LoanWSet)-1
	  ; FKR114
	  If StringLen($LoanWSet[$i])=2 Then
		 If StringLeft(StringStripWS($TargetKorOrig,8),2)=$LoanWSet[$i] Then
			$IsNonKor=$IsNonKor+1
		 EndIf
	  EndIf
	  ; FKR115
	  If StringLen($LoanWSet[$i])>2 Then
		 If StringLeft(StringStripWS($TargetKorOrig,8),3)=$LoanWSet[$i] Then
			$IsNonKor=$IsNonKor+1
		 EndIf
	  EndIf
   Next

   ; FKR116
   $IsParticle = 0

   Local $Rule1[12] = ["로부","로서","로써","로는","라는","라면","라든","라고","라도","라서","라야","로의"]
   For $i = 0 To Ubound($Rule1)-1
	  If StringLeft(StringStripWS($TargetKorOrig,8),2)=$Rule1[$i] Then
		 $IsParticle=$IsParticle+1
	  EndIf
   Next

If $Len > 1 and $IsNonKor=0 and $IsParticle=0 Then
   If StringInStr($Rom,"ra")=1 Then
	  $Rom = StringReplace($Rom,"ra","na",1)
   EndIf
   If StringInStr($Rom,"ro")=1 Then
	  $Rom = StringReplace($Rom,"ro","no",1)
   EndIf
   If StringInStr($Rom,"rw")=1 Then
	  $Rom = StringReplace($Rom,"rw","nw",1)
   EndIf
   If StringInStr($Rom,"ru")=1 Then
	  $Rom = StringReplace($Rom,"ru","nu",1)
   EndIf
   If StringInStr($Rom,"ri")=1 Then
	  $Rom = StringReplace($Rom,"ri","i",1)
   EndIf
   If StringInStr($Rom,"ry")=1 Then
	  $Rom = StringReplace($Rom,"ry","y",1)
   EndIf
   If StringInStr($Rom,"ni")=1 Then
	  $Rom = StringReplace($Rom,"ni","i",1)
   EndIf
   If StringInStr($Rom,"ny")=1 Then
	  $Rom = StringReplace($Rom,"ny","y",1)
   EndIf
EndIf

;FKR117
   $IsProperNoun=0

; FKR118
   Local $ProperN[35] = ['강종','경종','고종','광종','단종','덕종','명종','목종','문종','선조','선종','성종','세조','세종','숙종','순조','신종','영조','영종','예종','원종','의종','인조','인종','정조','정종','중종','철종','태조','태종','헌종','현종','혜종','효종','희종']
   $ProperNSuffix = StringRight(StringStripWS($TargetKorOrig,8),1)
   For $i = 0 To Ubound($ProperN)-1
	  If StringStripWS($TargetKorOrig,8)=$ProperN[$i] Then
		 $IsProperNoun=$IsProperNoun+1
	  EndIf
   Next

; FKR119
   Local $ProperN[208] = ['사우디아라비아','오스트레일리아','투르크메니스탄','리히텐슈타인','마다가스카르','미크로네시아','부르키나파소','세인트루시아','아랍에미리트','아제르바이잔','아프가니스탄','앤티가바부다','우즈베키스탄','코트디부아르','키르기즈스탄','파푸아뉴기니','기니비사우','나이지리아','라이베리아','룩셈부르크','리투아니아','마케도니아','말레이시아','모리타니아','몬테네그로','바베이도스','방글라데시','베네주엘라','스와질랜드','스코틀랜드','슬로바키아','슬로베니아','시에라리온','아르메니아','아르헨티나','아이슬란드','에리트레아','에스토니아','에티오피아','엘살바도르','오세아니아','오스트리아','우크라이나','인도네시아','카보베르데','카자흐스탄','코스타리카','크로아티아','타지키스탄','가이아나','과테말라','그레나다','그루지야','나미비아','네덜란드','노르웨이','뉴질랜드','니카라과','도미니카','라트비아','루마니아','모리셔스','모잠비크','바누아투','벨로루시','보스니아','보츠와나','볼리비아','불가리아','브루나이','산마리노','세르비아','소말리아','스리랑카','시베리아','아메리카','아일랜드','아프리카','알바니아','에콰도르','온두라스','우루과이','유라시아','이스라엘','이탈리아','잉글랜드','자메이카','짐바브웨','캄보디아','콜롬비아','쿠웨이트','키리바시','키프로스','타일랜드','탄자니아','파라과이','파키스탄','포르투갈','감비아','고구려','고조선','그리스','나우루','니게르','대가야','덴마크','라오스','러시아','레바논','레소토','르완다','리비아','말라위','멕시코','모나코','모로코','몰도바','몰디브','미얀마','바레인','바하마','베트남','벨기에','벨리즈','부룬디','브라질','사모아','세네갈','세이셸','소가야','솔로몬','수리남','스웨덴','스위스','스페인','시리아','싱가폴','아시아','아이티','안도라','알제리','앙골라','요르단','우간다','웨일즈','이라크','이집트','잠비아','지부티','카메룬','카타르','캐나다','코모로','투발루','튀니지','티모르','파나마','팔라우','폴란드','프랑스','핀란드','필리핀','헝가리','코리아','코리안','코리언','가나','가봉','가야','고려','기니','네팔','대만','독일','동양','말리','말타','몽고','몽골','미국','발해','백제','베냉','부탄','북한','서양','소련','신라','영국','예멘','유럽','일본','조선','중국','차드','체코','칠레','케냐','콩고','쿠바','태국','터키','토고','통가','페루','피지','한국','호주']
   $ProperNSuffix = StringRight(StringStripWS($TargetKorOrig,8),1)
   For $i = 0 To Ubound($ProperN)-1
	  If StringStripWS($TargetKorOrig,8)=$ProperN[$i] Then
		 $IsProperNoun=$IsProperNoun+1
	  EndIf
	  If StringTrimRight(StringStripWS($TargetKorOrig,8),1)=$ProperN[$i] Then
		 If $ProperNSuffix = "말" OR $ProperNSuffix = "인" OR $ProperNSuffix = "제" OR $ProperNSuffix = "어" OR $ProperNSuffix = "학" OR $ProperNSuffix = "사" OR $ProperNSuffix = "식" OR $ProperNSuffix = "산" OR $ProperNSuffix = "령" OR $ProperNSuffix = "행" OR $ProperNSuffix = "군" OR $ProperNSuffix = "계" OR $ProperNSuffix = "화" OR $ProperNSuffix = "적" Then
			$IsProperNoun=$IsProperNoun+1
		 EndIf
	  EndIf
   Next

; FKR120
   Local $ProperN[191] = ['로스앤젤레스','브로드웨이','캘리포니아','필라델피아','그리스도','두물머리','스탠포드','이슬람교','콜럼비아','크리스찬','프린스턴','호놀룰루','가이사','가톨릭','간다라','강화도','경복궁','경회루','경희궁','계동궁','광화문','교태전','국어학','근정전','금강산','기독교','낙동강','남가주','남대문','내장산','누동궁','대서양','대종교','덕수궁','도정궁','독립문','동남아','동대문','동북아','마리아','묘향산','무량사','미시간','바리새','백골단','백두산','밴쿠버','버클리','베이징','보스턴','북극해','사동궁','서대문','서소문','서울역','설악산','소록도','속리산','순화궁','시애틀','시카고','십알단','아방궁','알타이','어의궁','올림픽','운현궁','울릉도','워싱턴','원불교','유태인','의열단','이슬람','인경궁','인도양','자금성','자수궁','전계궁','제주도','조계종','조선족','죽도궁','중공권','지리산','창경궁','창덕궁','천주교','천태종','첨성대','충무공','치악산','카톨릭','탈무드','태평양','토론토','팔공산','포석정','풍경궁','하바드','하와이','한국민','한라산','한문체','한문학','한반도','흥선궁','강릉','강원','경기','경남','경북','경상','경성','경주','고창','과천','광주','국문','국어','극동','근동','김포','김해','남극','남미','남해','노어','뉴욕','대구','대전','도쿄','독도','독어','동경','동해','듀크','라틴','로마','마한','만주','모세','변한','부산','부처','북경','북극','북미','북해','불교','삼한','서울','서해','성서','세종','여수','연변','영어','예수','예일','울산','유다','율곡','인천','전남','전라','전북','전주','제주','중동','진한','청주','충남','충북','충주','충청','퇴계','평안','평양','한글','한류','한문','한성','한시','한식','한약','한양','한인','한자','한학','함경','황해']
   $ProperNSuffix = StringRight(StringStripWS($TargetKorOrig,8),1)
   For $i = 0 To Ubound($ProperN)-1
	  If StringStripWS($TargetKorOrig,8)=$ProperN[$i] Then
		 $IsProperNoun=$IsProperNoun+1
	  EndIf
   Next

   If $IsProperNoun > 0 Then
	  $Rom1 = StringTrimRight($Rom,StringLen($Rom)-1)
	  $Rom2 = StringTrimLeft($Rom,1)
	  $Rom = StringUpper($Rom1) & $Rom2
   EndIf

; FKR121
   $IsL_initial = 0
   Local $R2LSet[45] = [' 라스트 ',' 라오스 ',' 라이프 ',' 라트비아 ',' 라틴 ',' 라틴계 ',' 라틴어 ',' 래스트 ',' 랜드 ',' 랜딩 ',' 랜턴 ',' 램프 ',' 러브 ',' 런던 ',' 레바논 ',' 레슨 ',' 레터 ',' 레프트 ',' 렛 ',' 로고스 ',' 로딩 ',' 로렌스 ',' 로스앤젤레스 ',' 로스트 ',' 로잔 ',' 로직 ',' 로칼 ',' 로칼리티 ',' 로컬 ',' 로컬리티 ',' 룩셈부르크 ',' 리눅스 ',' 리더 ',' 리더쉽 ',' 리더십 ',' 리버럴 ',' 리버티 ',' 리베로 ',' 리비아 ',' 리빙 ',' 리움 ',' 리토피아 ',' 리틀 ',' 립스틱 ',' 링크 ']
   For $i = 0 To Ubound($R2LSet)-1
	  If " "&StringStripWS($TargetKorOrig,8)&" "=$R2LSet[$i] Then
		 $IsL_initial=$IsL_initial+1
	  EndIf
   Next
   If $ConvertR2L = "On" AND $IsL_initial > 0 Then
	  If StringLeft($Rom,1) = "r" Then
		 $Rom = StringReplace($Rom,"r","l",1,1)
	  EndIf
	  If StringLeft($Rom,1) = "R" Then
		 $Rom = StringReplace($Rom,"R","L",1,1)
	  EndIf
   EndIf

ClipPut(StringStripWS($Rom,1+4))

EndIf

EndFunc

; FKR122

;Func Sleep4OCLC()  ; Not used in SS
;   If StringInStr(WinGetTitle("[Active]"),"OCLC Connexion")>0 Then
;	  Sleep(50+400)
;   Else
;	  Sleep(50+50)
;   EndIF
;EndFunc

;Func Rom245C()  ; Not used in SS
;   $F245C = ClipGet()
;   If StringInStr($F245C,"ǂc")>0 OR StringInStr($F245C,"‡c")>0 Then
;	  $Delimiterc = StringLeft($F245C,3)
;	  $F245C = StringTrimLeft($F245C,3)
;   EndIf
;EndFunc

; FKR123 - Not used in SS
;Func YaleRomanizer()
;   _CopyEx()
;
;;FKR124
;   If $ConvertHancha="On" Then
;	  Sleep(50+20)
;	  MARC8Hancha()
;	  Sleep(50+20)
;	  Hancha2Hangul()
;	  Sleep(50+20)
;   EndIf
;
;   $RawClip = ClipGet()
;
;
;   ;FKR125
;   Local $RuleGN[19][2] = [["ㄱ","기역"],["ㄲ","쌍기역"],["ㄴ","니은"],["ㄷ","디귿"],["ㄸ","쌍디귿"],["ㄹ","리을"],["ㅁ","미음"],["ㅂ","비읍"],["ㅃ","쌍비읍"],["ㅅ","시옷"],["ㅆ","쌍시옷"],["ㅇ","이응"],["ㅈ","지읒"],["ㅉ","쌍지읒"],["ㅊ","치읓"],["ㅋ","키읔"],["ㅌ","티읕"],["ㅍ","피읖"],["ㅎ","히읗"]]
;   For $i = 0 To Ubound($RuleGN, 1) - 1
;	 $RawClip = StringRegExpReplace($RawClip,$RuleGN[$i][0],$RuleGN[$i][1])
;   Next
;
;   $Input = StringReplace($RawClip,@CR," ")
;   $Input = StringReplace($Input,@LF," ")
;   ClipPut($Input)
;   TrayTip("Processing:","Yale Korean Romanization",15)
;   Yale()
;   $Output = ClipGet()
;
;   _PasteEx()
;   If StringInStr($Output," ",0,4)=0 Then
;	  TrayTip($TT_Title3,@LF & $Input & @LF & " ↓ " & @LF & $Output,10)
;   Else
;	  TrayTip($TT_Title3,$TT_Text3,10)
;   EndIf
;EndFunc

;Func Yale()
;   $NClipB = " " & ClipGet()
;
;   $ClipB = StringStripWS($NClipB,1+2+4)
;   Sleep(50+20)
;   $Result=""
;   Local $aArray=StringSplit($ClipB," ")
;   For $i = 1 To Ubound($aArray, 1)-1
;	  ClipPut($aArray[$i])
;	  YaleRom()
;	  $Result=$Result & " " & ClipGet()
;   Next
;   $Result1=StringStripWS($Result,1)
;   $Result2 = StringReplace($Result1,"  "," ")
;
;   ClipPut(StringStripWS($Result2,1+4))
;EndFunc

;Func YaleRom()
;   $LEN = StringLen(StringStripWS(ClipGet(),1+2+4))
;   $TargetKor = ClipGet()
;   $TargetKorOrig = $TargetKor
;
;   $NonKor = 0
;   Local $aArray = StringToASCIIArray ($TargetKor)
;
;   Sleep (100)
;   For $i=0 to Ubound($aArray, 1)-1
;	  If Number($aArray[$i]) < 44032 Then
;		 $NonKor = $NonKor+1
;		 $TargetKor = StringTrimLeft($TargetKor,1)
;	  EndIf
;   Next
;   Sleep (100)
;   $Rom =""
;
;   Local $aArray = StringToASCIIArray ($TargetKor)
;
;   If StringLen($TargetKor) > 0 Then
;	  $ASCII1 = Number($aArray[0])-44032
;	  $Target = $ASCII1
;	  $Ini1 = "i" & FLOOR(Number($Target)/588)
;	  $Med1 = "m" & MOD(FLOOR(Number($Target)/28),21)
;	  $Fin1 = "f" & MOD(Number($Target),28)
;	  If StringLen($TargetKor) > 1 Then
;		 $ASCII2 = Number($aArray[1])-44032
;		 $Target = $ASCII2
;		 $Ini2 = "i" & FLOOR(Number($Target)/588)
;		 $Med2 = "m" & MOD(FLOOR(Number($Target)/28),21)
;		 $Fin2 = "f" & MOD(Number($Target),28)
;		 If StringLen($TargetKor) > 2 Then
;			$ASCII3 = Number($aArray[2])-44032
;			$Target = $ASCII3
;			$Ini3 = "i" & FLOOR(Number($Target)/588)
;			$Med3 = "m" & MOD(FLOOR(Number($Target)/28),21)
;			$Fin3 = "f" & MOD(Number($Target),28)
;			If StringLen($TargetKor) > 3 Then
;			   $ASCII4 = Number($aArray[3])-44032
;			   $Target = $ASCII4
;			   $Ini4 = "i" & FLOOR(Number($Target)/588)
;			   $Med4 = "m" & MOD(FLOOR(Number($Target)/28),21)
;			   $Fin4 = "f" & MOD(Number($Target),28)
;			   If StringLen($TargetKor) > 4 Then
;				  $ASCII5 = Number($aArray[4])-44032
;				  $Target = $ASCII5
;				  $Ini5 = "i" & FLOOR(Number($Target)/588)
;				  $Med5 = "m" & MOD(FLOOR(Number($Target)/28),21)
;				  $Fin5 = "f" & MOD(Number($Target),28)
;				  If StringLen($TargetKor) > 5 Then
;					 $ASCII6 = Number($aArray[5])-44032
;					 $Target = $ASCII6
;					 $Ini6 = "i" & FLOOR(Number($Target)/588)
;					 $Med6 = "m" & MOD(FLOOR(Number($Target)/28),21)
;					 $Fin6 = "f" & MOD(Number($Target),28)
;					 If StringLen($TargetKor) > 6 Then
;						$ASCII7 = Number($aArray[6])-44032
;						$Target = $ASCII7
;						$Ini7 = "i" & FLOOR(Number($Target)/588)
;						$Med7 = "m" & MOD(FLOOR(Number($Target)/28),21)
;						$Fin7 = "f" & MOD(Number($Target),28)
;						If StringLen($TargetKor) > 7 Then
;						   $ASCII8 = Number($aArray[7])-44032
;						   $Target = $ASCII8
;						   $Ini8 = "i" & FLOOR(Number($Target)/588)
;						   $Med8 = "m" & MOD(FLOOR(Number($Target)/28),21)
;						   $Fin8 = "f" & MOD(Number($Target),28)
;						   If StringLen($TargetKor) > 8 Then
;							  $ASCII9 = Number($aArray[8])-44032
;							  $Target = $ASCII9
;							  $Ini9 = "i" & FLOOR(Number($Target)/588)
;							  $Med9 = "m" & MOD(FLOOR(Number($Target)/28),21)
;							  $Fin9 = "f" & MOD(Number($Target),28)
;							  $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "~" & $Ini5 & "#" & $Med5 & "#" & $Fin5 &  "~" & $Ini6 & "#" & $Med6 & "#" & $Fin6 &  "~" & $Ini7 & "#" & $Med7 & "#" & $Fin7  &  "~" & $Ini8 & "#" & $Med8 & "#" & $Fin8  &  "~" & $Ini9 & "#" & $Med9 & "#" & $Fin9 & "E"
;						   Else
;							  $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "~" & $Ini5 & "#" & $Med5 & "#" & $Fin5 &  "~" & $Ini6 & "#" & $Med6 & "#" & $Fin6 &  "~" & $Ini7 & "#" & $Med7 & "#" & $Fin7  &  "~" & $Ini8 & "#" & $Med8 & "#" & $Fin8 & "E"
;						   EndIf
;						Else
;						   $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "~" & $Ini5 & "#" & $Med5 & "#" & $Fin5 &  "~" & $Ini6 & "#" & $Med6 & "#" & $Fin6 &  "~" & $Ini7 & "#" & $Med7 & "#" & $Fin7 & "E"
;						EndIf
;					 Else
;						$Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "~" & $Ini5 & "#" & $Med5 & "#" & $Fin5 &  "~" & $Ini6 & "#" & $Med6 & "#" & $Fin6 & "E"
;					 EndIf
;				  Else
;					 $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "~" & $Ini5 & "#" & $Med5 & "#" & $Fin5 & "E"
;				  EndIf
;			   Else
;				  $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "E"
;			   EndIf
;			Else
;			   $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "E"
;			EndIf
;		 Else
;			$Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "E"
;		 EndIf
;	  Else
;		 $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "E"
;	  EndIf
;   EndIf
;   $Result = $Rom
;; FKR126
;   Local $Rule[19][2] = [["i10","ss"],["i11",""],["i12","c"],["i13","cc"],["i14","ch"],["i15","kh"],["i16","th"],["i17","ph"],["i18","h"],["i1","kk"],["i2","n"],["i3","t"],["i4","tt"],["i5","l"],["i6","m"],["i7","p"],["i8","pp"],["i9","s"],["i0","k"]]
;   For $i = 0 To Ubound($Rule, 1) - 1
;	  $Result = StringRegExpReplace($Result, "\Q" & $Rule[$i][0] & "\E",$Rule[$i][1])
;   Next
;; FKR127
;   Local $Rule[21][2] = [["m20","i"],["m10","way"],["m11","oy"],["m12","yo"],["m13","wu"],["m14","we"],["m15","wey"],["m16","wi"],["m17","yu"],["m18","u"],["m19","uy"],["m0","a"],["m1","ay"],["m2","ya"],["m3","yay"],["m4","e"],["m5","ey"],["m6","ye"],["m7","yey"],["m8","o"],["m9","wa"]]
;   For $i = 0 To Ubound($Rule, 1) - 1
;	  $Result = StringRegExpReplace($Result, "\Q" & $Rule[$i][0] & "\E",$Rule[$i][1])
;   Next
;; FKR128
;   Local $Rule[28][2] = [["f20","ss"],["f21","ng"],["f22","c"],["f23","ch"],["f24","kh"],["f25","th"],["f26","ph"],["f27","h"],["f10","lm"],["f11","lp"],["f12","ls"],["f13","lth"],["f14","lph"],["f15","lh"],["f16","m"],["f17","p"],["f18","ps"],["f19","s"],["f0",""],["f1","k"],["f2","kk"],["f3","ks"],["f4","n"],["f5","nc"],["f6","nh"],["f7","t"],["f8","l"],["f9","lk"]]
;   For $i = 0 To Ubound($Rule, 1) - 1
;	  $Result = StringRegExpReplace($Result, "\Q" & $Rule[$i][0] & "\E",$Rule[$i][1])
;   Next
;   $Rom = $Result
;
;; FKR129
;   $Rom = StringReplace($Rom,"#","")
;   $Rom = StringReplace($Rom,"~","")
;   $Rom = StringReplace($Rom,"i-75m-17f-26E",".")
;   $Rom = StringReplace($Rom,"i-75m-17",",")
;   $Rom = StringReplace($Rom,",f-14E",":")
;   $Rom = StringReplace($Rom,"i-75m-18f-11E","!")
;   $Rom = StringReplace($Rom,",f-9E","?")
;   $Rom = StringReplace($Rom,"E","",-1,1)
;   If $NonKor > 0 Then
;	  $Rom = StringLeft($TargetKorOrig,$NonKor) & " " & $Rom
;   EndIf
;
;   ClipPut($Rom)
;EndFunc

; FKR130

; FKR131
;Func ISORomanizer()  ; Not used in SS
;   _CopyEx()
;
;;FKR132
;   If $ConvertHancha="On" Then
;	  Sleep(50+20)
;	  MARC8Hancha()
;	  Sleep(50+20)
;	  Hancha2Hangul()
;	  Sleep(50+20)
;   EndIf
;
;   $RawClip = ClipGet()
;
;
;   ;FKR133
;   Local $RuleGN[19][2] = [["ㄱ","기역"],["ㄲ","쌍기역"],["ㄴ","니은"],["ㄷ","디귿"],["ㄸ","쌍디귿"],["ㄹ","리을"],["ㅁ","미음"],["ㅂ","비읍"],["ㅃ","쌍비읍"],["ㅅ","시옷"],["ㅆ","쌍시옷"],["ㅇ","이응"],["ㅈ","지읒"],["ㅉ","쌍지읒"],["ㅊ","치읓"],["ㅋ","키읔"],["ㅌ","티읕"],["ㅍ","피읖"],["ㅎ","히읗"]]
;   For $i = 0 To Ubound($RuleGN, 1) - 1
;	 $RawClip = StringRegExpReplace($RawClip,$RuleGN[$i][0],$RuleGN[$i][1])
;   Next
;
;   $Input = StringReplace($RawClip,@CR," ")
;   $Input = StringReplace($Input,@LF," ")
;   ClipPut($Input)
;   TrayTip("Processing:","ISO Korean Romanization",15)
;   ISO()
;   $Output = ClipGet()
;
;   _PasteEx()
;   If StringInStr($Output," ",0,4)=0 Then
;	  TrayTip($TT_Title3,@LF & $Input & @LF & " ↓ " & @LF & $Output,10)
;   Else
;	  TrayTip($TT_Title3,$TT_Text3,10)
;   EndIf
;EndFunc

;Func ISO()  ; Not used in SS
;   $NClipB = " " & ClipGet()
;
;   $ClipB = StringStripWS($NClipB,1+2+4)
;   Sleep(50+20)
;   $Result=""
;   Local $aArray=StringSplit($ClipB," ")
;   For $i = 1 To Ubound($aArray, 1)-1
;	  ClipPut($aArray[$i])
;	  ISORom()
;	  $Result=$Result & " " & ClipGet()
;   Next
;   $Result1=StringStripWS($Result,1)
;   $Result2 = StringReplace($Result1,"  "," ")
;
;   ClipPut(StringStripWS($Result2,1+4))
;EndFunc

;Func ISORom()  ; Not used in SS
;   $LEN = StringLen(StringStripWS(ClipGet(),1+2+4))
;   $TargetKor = ClipGet()
;   $TargetKorOrig = $TargetKor
;
;   $NonKor = 0
;   Local $aArray = StringToASCIIArray ($TargetKor)
;
;   Sleep (100)
;   For $i=0 to Ubound($aArray, 1)-1
;	  If Number($aArray[$i]) < 44032 Then
;		 $NonKor = $NonKor+1
;		 $TargetKor = StringTrimLeft($TargetKor,1)
;	  EndIf
;   Next
;   Sleep (100)
;   $Rom =""
;
;   Local $aArray = StringToASCIIArray ($TargetKor)
;
;   If StringLen($TargetKor) > 0 Then
;	  $ASCII1 = Number($aArray[0])-44032
;	  $Target = $ASCII1
;	  $Ini1 = "i" & FLOOR(Number($Target)/588)
;	  $Med1 = "m" & MOD(FLOOR(Number($Target)/28),21)
;	  $Fin1 = "f" & MOD(Number($Target),28)
;	  If StringLen($TargetKor) > 1 Then
;		 $ASCII2 = Number($aArray[1])-44032
;		 $Target = $ASCII2
;		 $Ini2 = "i" & FLOOR(Number($Target)/588)
;		 $Med2 = "m" & MOD(FLOOR(Number($Target)/28),21)
;		 $Fin2 = "f" & MOD(Number($Target),28)
;		 If StringLen($TargetKor) > 2 Then
;			$ASCII3 = Number($aArray[2])-44032
;			$Target = $ASCII3
;			$Ini3 = "i" & FLOOR(Number($Target)/588)
;			$Med3 = "m" & MOD(FLOOR(Number($Target)/28),21)
;			$Fin3 = "f" & MOD(Number($Target),28)
;			If StringLen($TargetKor) > 3 Then
;			   $ASCII4 = Number($aArray[3])-44032
;			   $Target = $ASCII4
;			   $Ini4 = "i" & FLOOR(Number($Target)/588)
;			   $Med4 = "m" & MOD(FLOOR(Number($Target)/28),21)
;			   $Fin4 = "f" & MOD(Number($Target),28)
;			   If StringLen($TargetKor) > 4 Then
;				  $ASCII5 = Number($aArray[4])-44032
;				  $Target = $ASCII5
;				  $Ini5 = "i" & FLOOR(Number($Target)/588)
;				  $Med5 = "m" & MOD(FLOOR(Number($Target)/28),21)
;				  $Fin5 = "f" & MOD(Number($Target),28)
;				  If StringLen($TargetKor) > 5 Then
;					 $ASCII6 = Number($aArray[5])-44032
;					 $Target = $ASCII6
;					 $Ini6 = "i" & FLOOR(Number($Target)/588)
;					 $Med6 = "m" & MOD(FLOOR(Number($Target)/28),21)
;					 $Fin6 = "f" & MOD(Number($Target),28)
;					 If StringLen($TargetKor) > 6 Then
;						$ASCII7 = Number($aArray[6])-44032
;						$Target = $ASCII7
;						$Ini7 = "i" & FLOOR(Number($Target)/588)
;						$Med7 = "m" & MOD(FLOOR(Number($Target)/28),21)
;						$Fin7 = "f" & MOD(Number($Target),28)
;						If StringLen($TargetKor) > 7 Then
;						   $ASCII8 = Number($aArray[7])-44032
;						   $Target = $ASCII8
;						   $Ini8 = "i" & FLOOR(Number($Target)/588)
;						   $Med8 = "m" & MOD(FLOOR(Number($Target)/28),21)
;						   $Fin8 = "f" & MOD(Number($Target),28)
;						   If StringLen($TargetKor) > 8 Then
;							  $ASCII9 = Number($aArray[8])-44032
;							  $Target = $ASCII9
;							  $Ini9 = "i" & FLOOR(Number($Target)/588)
;							  $Med9 = "m" & MOD(FLOOR(Number($Target)/28),21)
;							  $Fin9 = "f" & MOD(Number($Target),28)
;							  $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "~" & $Ini5 & "#" & $Med5 & "#" & $Fin5 &  "~" & $Ini6 & "#" & $Med6 & "#" & $Fin6 &  "~" & $Ini7 & "#" & $Med7 & "#" & $Fin7  &  "~" & $Ini8 & "#" & $Med8 & "#" & $Fin8  &  "~" & $Ini9 & "#" & $Med9 & "#" & $Fin9 & "E"
;						   Else
;							  $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "~" & $Ini5 & "#" & $Med5 & "#" & $Fin5 &  "~" & $Ini6 & "#" & $Med6 & "#" & $Fin6 &  "~" & $Ini7 & "#" & $Med7 & "#" & $Fin7  &  "~" & $Ini8 & "#" & $Med8 & "#" & $Fin8 & "E"
;						   EndIf
;						Else
;						   $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "~" & $Ini5 & "#" & $Med5 & "#" & $Fin5 &  "~" & $Ini6 & "#" & $Med6 & "#" & $Fin6 &  "~" & $Ini7 & "#" & $Med7 & "#" & $Fin7 & "E"
;						EndIf
;					 Else
;						$Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "~" & $Ini5 & "#" & $Med5 & "#" & $Fin5 &  "~" & $Ini6 & "#" & $Med6 & "#" & $Fin6 & "E"
;					 EndIf
;				  Else
;					 $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "~" & $Ini5 & "#" & $Med5 & "#" & $Fin5 & "E"
;				  EndIf
;			   Else
;				  $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "~" & $Ini4 & "#" & $Med4 & "#" & $Fin4 & "E"
;			   EndIf
;			Else
;			   $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "~" & $Ini3 & "#" & $Med3 & "#" & $Fin3 & "E"
;			EndIf
;		 Else
;			$Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "~" & $Ini2 & "#" & $Med2 & "#" & $Fin2 & "E"
;		 EndIf
;	  Else
;		 $Rom = $Ini1 & "#" & $Med1 & "#" & $Fin1 & "E"
;	  EndIf
;   EndIf
;   $Result = $Rom
;; FKR134
;   Local $Rule[19][2] = [["i10","ss"],["i11",""],["i12","j"],["i13","jj"],["i14","c"],["i15","k"],["i16","t"],["i17","p"],["i18","h"],["i1","gg"],["i2","n"],["i3","d"],["i4","dd"],["i5","l"],["i6","m"],["i7","b"],["i8","bb"],["i9","s"],["i0","g"]]
;   For $i = 0 To Ubound($Rule, 1) - 1
;	  $Result = StringRegExpReplace($Result, "\Q" & $Rule[$i][0] & "\E",$Rule[$i][1])
;   Next
;; FKR135
;   Local $Rule[21][2] = [["m20","i"],["m10","wae"],["m11","oe"],["m12","yo"],["m13","u"],["m14","weo"],["m15","we"],["m16","wi"],["m17","yu"],["m18","eu"],["m19","yi"],["m0","a"],["m1","ae"],["m2","ya"],["m3","yae"],["m4","eo"],["m5","e"],["m6","yeo"],["m7","ye"],["m8","o"],["m9","wa"]]
;   For $i = 0 To Ubound($Rule, 1) - 1
;	  $Result = StringRegExpReplace($Result, "\Q" & $Rule[$i][0] & "\E",$Rule[$i][1])
;   Next
;; FKR136
;   Local $Rule[28][2] = [["f20","ss"],["f21","ng"],["f22","j"],["f23","c"],["f24","k"],["f25","t"],["f26","p"],["f27","h"],["f10","lm"],["f11","lb"],["f12","ls"],["f13","lt"],["f14","lp"],["f15","lh"],["f16","m"],["f17","b"],["f18","bs"],["f19","s"],["f0",""],["f1","g"],["f2","gg"],["f3","gs"],["f4","n"],["f5","nj"],["f6","nh"],["f7","d"],["f8","l"],["f9","lg"]]
;   For $i = 0 To Ubound($Rule, 1) - 1
;	  $Result = StringRegExpReplace($Result, "\Q" & $Rule[$i][0] & "\E",$Rule[$i][1])
;   Next
;   $Rom = $Result
;
;; FKR137
;   $Rom = StringReplace($Rom,"#","")
;   $Rom = StringReplace($Rom,"~","")
;   $Rom = StringReplace($Rom,"i-75m-17f-26E",".")
;   $Rom = StringReplace($Rom,"i-75m-17",",")
;   $Rom = StringReplace($Rom,",f-14E",":")
;   $Rom = StringReplace($Rom,"i-75m-18f-11E","!")
;   $Rom = StringReplace($Rom,",f-9E","?")
;   $Rom = StringReplace($Rom,"E","",-1,1)
;   If $NonKor > 0 Then
;	  $Rom = StringLeft($TargetKorOrig,$NonKor) & " " & $Rom
;   EndIf
;
;   ClipPut($Rom)
;EndFunc

; FKR138

;Func HanchaTemp()  ; Not used in SS
;   $Ambig = "No"
;   $AmbigExp = ""
;   _SendEx("{CTRLDOWN}c{CTRLUP}")
;   $OrigHancha = ClipGet()
;   Sleep(50+50)
;   MARC8Hancha()
;   Sleep(50+50)
;   $Hancha =ClipGet()
;   Sleep(50+50)
;   Hancha2Hangul()
;   Sleep(50+50)
;   $Result = StringStripWS(ClipGet(),$STR_STRIPLEADING + $STR_STRIPTRAILING + $STR_STRIPSPACES)
;   Sleep(50+50)
;   ClipPut($Result)
;   Sleep(50+50)
;   If $HanchaDisplay="On" Then
;	  $HanchaHangul=$Hancha & " (" & $Result & ")"
;	  ClipPut($HanchaHangul)
;   EndIf
;   _SendEx("{CTRLDOWN}v{CTRLUP}")
;
;   ;FKR139
;   $2Reading = " may read as "
;   $3Reading = " may read as "
;   ;FKR140
;   If StringInStr($Hancha,"樂")>0 OR StringInStr($Hancha,"樂")>0 OR StringInStr($Hancha,"樂")>0 OR StringInStr($Hancha,"樂")>0 Then
;  	  $Ambig = "Yes"
;	  $AmbigExp = $AmbigExp & @LF & "樂" & $3Reading & "악 / 락 / 요" & @LF
;   EndIf
;
;   ;FKR141
;If StringInStr($Hancha,"契")>0 OR StringInStr($Hancha,"契")>0 OR StringInStr($Hancha,"契")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "契" & $3Reading &"계 / 글 / 설" & @LF
;EndIf
;If StringInStr($Hancha,"寧")>0 OR StringInStr($Hancha,"寧")>0 OR StringInStr($Hancha,"寧")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "寧" & $3Reading &"녕 / 령 / 영" & @LF
;EndIf
;If StringInStr($Hancha,"率")>0 OR StringInStr($Hancha,"率")>0 OR StringInStr($Hancha,"率")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "率" & $3Reading &"솔 / 률 / 율" & @LF
;EndIf
;If StringInStr($Hancha,"說")>0 OR StringInStr($Hancha,"說")>0 OR StringInStr($Hancha,"說")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "說" & $3Reading &"설 / 세 / 열" & @LF
;EndIf
;If StringInStr($Hancha,"龜")>0 OR StringInStr($Hancha,"龜")>0 OR StringInStr($Hancha,"龜")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "龜" & $3Reading &"구 / 귀 / 균" & @LF
;EndIf
;If StringInStr($Hancha,"則")>0 OR StringInStr($Hancha,"則")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "則" & $2Reading &"칙 / 즉" & @LF
;EndIf
;If StringInStr($Hancha,"豈")>0 OR StringInStr($Hancha,"豈")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "豈" & $2Reading &"기 / 개" & @LF
;EndIf
;If StringInStr($Hancha,"更")>0 OR StringInStr($Hancha,"更")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "更" & $2Reading &"경 / 갱" & @LF
;EndIf
;If StringInStr($Hancha,"車")>0 OR StringInStr($Hancha,"車")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "車" & $2Reading &"차 / 거" & @LF
;EndIf
;If StringInStr($Hancha,"賈")>0 OR StringInStr($Hancha,"賈")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "賈" & $2Reading &"가 / 고" & @LF
;EndIf
;If StringInStr($Hancha,"滑")>0 OR StringInStr($Hancha,"滑")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "滑" & $2Reading &"활 / 골" & @LF
;EndIf
;If StringInStr($Hancha,"串")>0 OR StringInStr($Hancha,"串")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "串" & $2Reading &"곶 / 관" & @LF
;EndIf
;If StringInStr($Hancha,"句")>0 OR StringInStr($Hancha,"句")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "句" & $2Reading &"구 / 귀" & @LF
;EndIf
;If StringInStr($Hancha,"金")>0 OR StringInStr($Hancha,"金")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "金" & $2Reading &"김 / 금" & @LF
;EndIf
;If StringInStr($Hancha,"奈")>0 OR StringInStr($Hancha,"奈")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "奈" & $2Reading &"내 / 나" & @LF
;EndIf
;If StringInStr($Hancha,"讀")>0 OR StringInStr($Hancha,"讀")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "讀" & $2Reading &"독 / 두" & @LF
;EndIf
;If StringInStr($Hancha,"丹")>0 OR StringInStr($Hancha,"丹")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "丹" & $2Reading &"단 / 란" & @LF
;EndIf
;If StringInStr($Hancha,"怒")>0 OR StringInStr($Hancha,"怒")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "怒" & $2Reading &"노 / 로" & @LF
;EndIf
;If StringInStr($Hancha,"北")>0 OR StringInStr($Hancha,"北")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "北" & $2Reading &"북 / 배" & @LF
;EndIf
;If StringInStr($Hancha,"磻")>0 OR StringInStr($Hancha,"磻")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "磻" & $2Reading &"반 / 번" & @LF
;EndIf
;If StringInStr($Hancha,"便")>0 OR StringInStr($Hancha,"便")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "便" & $2Reading &"편 / 변" & @LF
;EndIf
;If StringInStr($Hancha,"復")>0 OR StringInStr($Hancha,"復")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "復" & $2Reading &"복 / 부" & @LF
;EndIf
;;~ If StringInStr($Hancha,"不")>0 OR StringInStr($Hancha,"不")>0 Then
;;~ $Ambig = "Yes"
;;~ $AmbigExp = $AmbigExp & @LF & "不" & $2Reading &"부 / 불" & @LF
;;~ EndIf
;If StringInStr($Hancha,"泌")>0 OR StringInStr($Hancha,"泌")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "泌" & $2Reading &"필 / 비" & @LF
;EndIf
;;~ If StringInStr($Hancha,"數")>0 OR StringInStr($Hancha,"數")>0 Then
;;~ $Ambig = "Yes"
;;~ $AmbigExp = $AmbigExp & @LF & "數" & $2Reading &"수 / 삭" & @LF
;;~ EndIf
;If StringInStr($Hancha,"參")>0 OR StringInStr($Hancha,"參")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "參" & $2Reading &"참 / 삼" & @LF
;EndIf
;If StringInStr($Hancha,"塞")>0 OR StringInStr($Hancha,"塞")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "塞" & $2Reading &"새 / 색" & @LF
;EndIf
;If StringInStr($Hancha,"省")>0 OR StringInStr($Hancha,"省")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "省" & $2Reading &"성 / 생" & @LF
;EndIf
;If StringInStr($Hancha,"葉")>0 OR StringInStr($Hancha,"葉")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "葉" & $2Reading &"엽 / 섭" & @LF
;EndIf
;If StringInStr($Hancha,"殺")>0 OR StringInStr($Hancha,"殺")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "殺" & $2Reading &"살 / 쇄" & @LF
;EndIf
;If StringInStr($Hancha,"辰")>0 OR StringInStr($Hancha,"辰")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "辰" & $2Reading &"진 / 신" & @LF
;EndIf
;If StringInStr($Hancha,"沈")>0 OR StringInStr($Hancha,"沈")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "沈" & $2Reading &"침 / 심" & @LF
;EndIf
;If StringInStr($Hancha,"拾")>0 OR StringInStr($Hancha,"拾")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "拾" & $2Reading &"습 / 십" & @LF
;EndIf
;If StringInStr($Hancha,"咽")>0 OR StringInStr($Hancha,"咽")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "咽" & $2Reading &"인 / 열" & @LF
;EndIf
;If StringInStr($Hancha,"瑩")>0 OR StringInStr($Hancha,"瑩")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "瑩" & $2Reading &"형 / 영" & @LF
;EndIf
;If StringInStr($Hancha,"惡")>0 OR StringInStr($Hancha,"惡")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "惡" & $2Reading &"악 / 오" & @LF
;EndIf
;If StringInStr($Hancha,"暈")>0 OR StringInStr($Hancha,"暈")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "暈" & $2Reading &"훈 / 운" & @LF
;EndIf
;If StringInStr($Hancha,"阮")>0 OR StringInStr($Hancha,"阮")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "阮" & $2Reading &"완 / 원" & @LF
;EndIf
;If StringInStr($Hancha,"易")>0 OR StringInStr($Hancha,"易")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "易" & $2Reading &"역 / 이" & @LF
;EndIf
;If StringInStr($Hancha,"狀")>0 OR StringInStr($Hancha,"狀")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "狀" & $2Reading &"상 / 장" & @LF
;EndIf
;If StringInStr($Hancha,"炙")>0 OR StringInStr($Hancha,"炙")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "炙" & $2Reading &"자 / 적" & @LF
;EndIf
;If StringInStr($Hancha,"識")>0 OR StringInStr($Hancha,"識")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "識" & $2Reading &"식 / 지" & @LF
;EndIf
;If StringInStr($Hancha,"什")>0 OR StringInStr($Hancha,"什")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "什" & $2Reading &"십 / 집" & @LF
;EndIf
;If StringInStr($Hancha,"茶")>0 OR StringInStr($Hancha,"茶")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "茶" & $2Reading &"다 / 차" & @LF
;EndIf
;If StringInStr($Hancha,"切")>0 OR StringInStr($Hancha,"切")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "切" & $2Reading &"절 / 체" & @LF
;EndIf
;If StringInStr($Hancha,"度")>0 OR StringInStr($Hancha,"度")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "度" & $2Reading &"도 / 탁" & @LF
;EndIf
;If StringInStr($Hancha,"拓")>0 OR StringInStr($Hancha,"拓")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "拓" & $2Reading &"척 / 탁" & @LF
;EndIf
;If StringInStr($Hancha,"糖")>0 OR StringInStr($Hancha,"糖")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "糖" & $2Reading &"당 / 탕" & @LF
;EndIf
;If StringInStr($Hancha,"宅")>0 OR StringInStr($Hancha,"宅")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "宅" & $2Reading &"댁 / 택" & @LF
;EndIf
;If StringInStr($Hancha,"洞")>0 OR StringInStr($Hancha,"洞")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "洞" & $2Reading &"동 / 통" & @LF
;EndIf
;If StringInStr($Hancha,"暴")>0 OR StringInStr($Hancha,"暴")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "暴" & $2Reading &"폭 / 포" & @LF
;EndIf
;If StringInStr($Hancha,"輻")>0 OR StringInStr($Hancha,"輻")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "輻" & $2Reading &"복 / 폭" & @LF
;EndIf
;If StringInStr($Hancha,"行")>0 OR StringInStr($Hancha,"行")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "行" & $2Reading &"행 / 항" & @LF
;EndIf
;If StringInStr($Hancha,"降")>0 OR StringInStr($Hancha,"降")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "降" & $2Reading &"강 / 항" & @LF
;EndIf
;If StringInStr($Hancha,"見")>0 OR StringInStr($Hancha,"見")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "見" & $2Reading &"견 / 현" & @LF
;EndIf
;If StringInStr($Hancha,"廓")>0 OR StringInStr($Hancha,"廓")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "廓" & $2Reading &"곽 / 확" & @LF
;EndIf
;If StringInStr($Hancha,"諸")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "諸" & $2Reading &"제 / 저" & @LF
;EndIf
;If StringInStr($Hancha,"羨")>0 OR StringInStr($Hancha,"羡")>0 Then
;$Ambig = "Yes"
;$AmbigExp = $AmbigExp & @LF & "羨" & $2Reading &"선 / 연" & @LF
;EndIf
;
;   If $Ambig="Yes" AND $TrayTip = "ON" Then
;	  If StringLen($AmbigExp)>255 Then
;		 TrayTip("CONSIDER",StringLeft($AmbigExp,234)&@LF&@LF&"TOO MANY TO DISPLAY",30,2)
;	  Else
;		 TrayTip("CONSIDER",$AmbigExp,30,2)
;	  EndIf
;   EndIf
;EndFunc

;===============================================================================
; _UnicodeURLEncode()
; Description: : Encodes an unicode string to be URL-friendly
; Parameter(s): : $UnicodeURL - The Unicode String to Encode
; Return Value(s): : The URL encoded string
; Author(s): : Dhilip89
;===============================================================================

;Func _UnicodeURLEncode($UnicodeURL)  ; Not used in SS
;    $UnicodeBinary = StringToBinary ($UnicodeURL, 4)
;    $UnicodeBinary2 = StringReplace($UnicodeBinary, '0x', '', 1)
;    $UnicodeBinaryLength = StringLen($UnicodeBinary2)
;    Local $EncodedString
;    For $i = 1 To $UnicodeBinaryLength Step 2
;        $UnicodeBinaryChar = StringMid($UnicodeBinary2, $i, 2)
;        If StringInStr("$-_.+!*'(),;/?:@=&abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", BinaryToString ('0x' & $UnicodeBinaryChar, 4)) Then
;            $EncodedString &= BinaryToString ('0x' & $UnicodeBinaryChar)
;        Else
;            $EncodedString &= '%' & $UnicodeBinaryChar
;        EndIf
;    Next
;    Return $EncodedString
;EndFunc   ;==>_UnicodeURLEncode

;===============================================================================
; _UnicodeURLDecode()
; Description: : Tranlates a URL-friendly string to a normal string
; Parameter(s): : $toDecode - The URL-friendly string to decode
; Return Value(s): : The URL decoded string
; Author(s): : nfwu, Dhilip89
; Note(s): : Modified from _URLDecode() that's only support non-unicode.
;===============================================================================
;Func _UnicodeURLDecode($toDecode)  ; Not used in SS
;    Local $strChar = "", $iOne, $iTwo
;    Local $aryHex = StringSplit($toDecode, "")
;    For $i = 1 To $aryHex[0]
;        If $aryHex[$i] = "%" Then
;            $i = $i + 1
;            $iOne = $aryHex[$i]
;            $i = $i + 1
;            $iTwo = $aryHex[$i]
;            $strChar = $strChar & Chr(Dec($iOne & $iTwo))
;        Else
;            $strChar = $strChar & $aryHex[$i]
;        EndIf
;    Next
;    $Process = StringToBinary (StringReplace($strChar, "+", " "))
;    $DecodedString = BinaryToString ($Process, 4)
;    Return $DecodedString
; EndFunc   ;==>_UnicodeURLDecode

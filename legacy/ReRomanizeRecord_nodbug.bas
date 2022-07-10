Attribute VB_Name = "ReRomanize"
Option Explicit

#Const EvaluateFirstCharacterDebug = 0 ' -1 ' 0 ' -1 ' 0 ' -1
#Const FindFieldCurrentlyPointedToDebug = 0 ' -1
#Const ReRomanizeAdjustNFIDebug = 0 ' -1
#Const ReRomanizeTextDebug = 0 ' -1 ' 0 ' -1  ' 0 ' -1 ' 0 ' -1 ' 0 ' -1
#Const ReRomanizeTextDetailsDebug = 0 ' -1 ' 0 ' -1 ' 0 ' -1 ' 0 ' -1 ' 0 ' -1 ' 0 ' -1 ' 0 ' -1
#Const ReRomanizeTextDetailsBasicsDebug = 0 ' -1 ' 0 ' -1 ' 0 ' -1 ' 0 ' -1 ' 0 ' -1 ' 0 ' -1
#Const RomanizationAssistanceDebug = 0 ' -1 ' 0 ' -1 ' 0 ' -1 ' 0 ' -1
#Const RomanizeHighlightedTextDebug = 0 ' -1
#Const RomanizeWholeRecordDebug = 0 ' -1 ' 0 '-1

' 20180926 Bucknum: added Unicode-compliant font constants for RTF formatting
Private Const ArialUnicodeMS$ = "Arial Unicode MS"       ' Monotype
Private Const LucidaSansUnicode$ = "Lucida Sans Unicode" ' Microsoft
Private Const NotoSans$ = "Noto Sans"   ' Google
Private Const NotoSerif$ = "Noto Serif" ' Google
Private Const TextFormattedDefaultFont$ = ArialUnicodeMS$

Private Const sAuthorityNonfilingString$ = "130:2 430:2 530:2"
Private Const sBibliographicNonfilingString$ = "130:1 240:2 242:2 243:2 245:2 440:2 630:1 730:1 740:1 830:2"
Private Const sCommunityInfoNonfilingString$ = "245:2 440:2 630:1 730:1 740:1"

Private prvsRightToLeftMarker$, prvsLeftToRightMarker$

Private Const CHARACTERSET_CODES_FOR_880_BasicAsG0$ = "(B"
Private Const CHARACTERSET_CODES_FOR_880_HebrewAsG0$ = "(2"
Private Const CHARACTERSET_CODES_FOR_880_BasicCyrillicAsG0$ = "(N"
Private Const CHARACTERSET_CODES_FOR_880_BasicArabicAsG0$ = "(3"
Private Const CHARACTERSET_CODES_FOR_880_GreekAsG0$ = "(S"
Private Const CHARACTERSET_CODES_FOR_880_CJKAsG0$ = "$1"
Private Const CHARACTERSET_CODES_FOR_880_ExtendedCyrillicAsG1$ = ")Q"
Private Const CHARACTERSET_CODES_FOR_880_ExtendedArabicAsG1$ = ")4"
Private Const CHARACTERSET_CODES_FOR_880_ExtendedLatinAsG1$ = ")!E"
' convert this constant into its ASCII value subtract 48; and multiply this
'   remainder by 6 to transform it into an offset into the following hyphen-delimited string
' the first character (0) is the MARC-8'code table' number; same as above, with extensions
' the second character (1) is the code to use for the set in non-880 fields after escape ("?"=illegal in non-880);
' 4rd-5th chars (3-4) are the code to use after escape in 880 field
' ignore other characters--turned out not to be needed
'                                             1      2      3      4      5      6      7      8      9      :      ;
'                                             012345 012345 012345 012345 012345 012345 012345 012345 012345 012345 012345
Private Const CharSetU2MTranslation$ = "*****-1s s  -2g*g *-3b b  -4p p  -5? (2 -6? (N -7? (3 -8g*(S*-9? $1 -:? (Q -;? (4 "

Global Const ROMANIZATIONACTION_DisplayMarcRecord% = 1
Global Const ROMANIZATIONACTION_RomanizeHighlightedText% = 2
Global Const ROMANIZATIONACTION_RomanizeWholeRecord% = 3
Global Const ROMANIZATIONACTION_UCaseWord% = 4
Global Const ROMANIZATIONACTION_LCaseWord% = 5
Global Const ROMANIZATIONACTION_ReplaceText% = 6
Global Const ROMANIZATIONACTION_UCaseEach% = 7
Global Const ROMANIZATIONACTION_Define% = 8

Enum RomanizationAction
    DefineSubstitution = ROMANIZATIONACTION_Define%
    DisplayMarcRecord = ROMANIZATIONACTION_DisplayMarcRecord%
    LowercaseWord = ROMANIZATIONACTION_LCaseWord%
    ReplaceText = ROMANIZATIONACTION_ReplaceText%
    RomanizeHighlightedText = ROMANIZATIONACTION_RomanizeHighlightedText%
    RomanizeWholeRecord = ROMANIZATIONACTION_RomanizeWholeRecord%
    UppercaseWord = ROMANIZATIONACTION_UCaseWord%
    UppercaseEachWord = ROMANIZATIONACTION_UCaseEach%
End Enum

Global Const ROMANIZATIONRESULT_Success% = 0
Global Const ROMANIZATIONRESULT_TextNotHighlighted% = 1
Global Const ROMANIZATIONRESULT_HighlightedTextBecomesNothing% = 2
Global Const ROMANIZATIONRESULT_TextNotFindable% = 3
Global Const ROMANIZATIONRESULT_ActionUnclear% = 4
Global Const ROMANIZATIONRESULT_FieldNotFound% = 5
Global Const ROMANIZATIONRESULT_880WithNoSubfield6% = 6
Global Const ROMANIZATIONRESULT_880NotAllowed% = 7
Global Const ROMANIZATIONRESULT_880AlreadyPresent% = 8
Global Const ROMANIZATIONRESULT_NoCharacterToDefine% = 9
Global Const ROMANIZATIONRESULT_FileOpen% = 10

Global Const ROMANIZATIONDIRECTION_Unknown% = 0
Global Const ROMANIZATIONDIRECTION_Roman2Vernacular% = 1
Global Const ROMANIZATIONDIRECTION_Vernacular2Roman% = 2

Type ROMANIZATIONDETAILTYPE
    FullString As String
    Equivalent As String
    EquivalentUpperCase As String
    FullStringLengthInCharacters As Integer
    FullStringLengthInBytes As Integer
    EquivalentUpperCasePresent As Boolean
    InitialOnly As Boolean
    TerminalOnly As Boolean
    MedialOnly As Boolean
End Type

Type ROMANIZATIONDETAILARRAY
    Detail() As ROMANIZATIONDETAILTYPE
    DetailLast As Long
    DetailMax As Long
End Type

Type ROMANIZATIONTABLETYPE
    Vernacular2Roman As Object
    Roman2Vernacular As Object
    Name As String
    FullFileName As String
    Vernacular() As ROMANIZATIONDETAILARRAY
    Roman() As ROMANIZATIONDETAILARRAY
    VernacularLast As Long
    VernacularMax As Long
    RomanLast As Long
    RomanMax As Long
    AllowCaseVariation As Boolean
    AllowDefineButton As Boolean
    ApostropheCharacters As String
    ApostropheCharactersPresent As Boolean
    BySyllables As Boolean
    DoNotUse880Field As Boolean
    FontName As String
    NoRomanization As Boolean
    ' things that pertain only to romanized-to-vernacular
    R2VCreateEmpty880s As Boolean
    R2VFieldsIncluded As String
    R2VIncludeFormattingCharactersLcPattern As Boolean
    R2VOtherSubfieldsExcludedByTag As String
    R2VSubfieldsAlwaysExcluded As String
    R2VSubfield6Code As String
    R2VVowelMarker As String
    ' things that pertain only to vernacular-to-romanized
    V2RCreateEmptyFields As Boolean
    V2RFieldsIncluded As String
    V2ROtherSubfieldsExcludedByTag As String
    V2RSubfieldsAlwaysExcluded As String
    V2RUppercaseFirstCharacterInSubfield As String
    V2RPersonalNameUppercase As Boolean
End Type

Type RESEQUENCETABLETYPE
    Tag As String * 3
    LinkTag As String * 3
    Field As String
    Field880 As String
    Sequence As Integer
    Sequence880 As Integer
End Type

Public Type ROMANIZATIONSCRIPTTYPE
    Name As String
    LoadScript As Boolean
    FileSize As Long
End Type

Global gblaReSequenceTable() As RESEQUENCETABLETYPE
Global gblaRomanizationScript() As ROMANIZATIONSCRIPTTYPE
Global gblaRomanizationTable() As ROMANIZATIONTABLETYPE
Global gbliReSequenceTableLast%
Global gbliRomanizationScriptLast%
Global gbliRomanizationTableLast%, gbliRomanizationTableMax%
Global gbliRomanizationTablesBytes#

Public Function ReRomanizeText(ByVal sRecordType$, ByVal sTag$, ByVal sText$, ByVal iRomanizationTable%, ByRef LocalMarcRecordObject As Utf8MarcRecordClass, ByRef LocalMarcCharacter As Utf8CharClass, Optional ByRef iRomanizationDirection% = -1, Optional ByVal sSubfieldCode$ = "") As String

    Dim sOut$, sLeft$, sRight$, sWord$
    Dim iLength%
    
    Dim lPtr As Long, lLength As Long
    
    Dim bFound As Boolean
    
    
    On Error GoTo 0
        

    If iRomanizationTable% < 1 Or iRomanizationTable% > gbliRomanizationTableLast% Then

        sOut$ = sText$
    Else
        If iRomanizationDirection% = -1 Then
            iRomanizationDirection% = EvaluateFirstCharacter(sText$, iRomanizationTable%, LocalMarcCharacter)

        End If
        Select Case iRomanizationDirection%
            Case ROMANIZATIONDIRECTION_Unknown%
                sOut$ = sText$
            Case ROMANIZATIONDIRECTION_Roman2Vernacular%
                sOut$ = ReRomanizeTextDetails(sText$, gblaRomanizationTable(iRomanizationTable%).Roman2Vernacular, gblaRomanizationTable(iRomanizationTable%).Roman(), LocalMarcRecordObject, LocalMarcCharacter, True, iRomanizationTable%)
            Case ROMANIZATIONDIRECTION_Vernacular2Roman%
                sOut$ = ReRomanizeTextDetails(sText$, gblaRomanizationTable(iRomanizationTable%).Vernacular2Roman, gblaRomanizationTable(iRomanizationTable%).Vernacular(), LocalMarcRecordObject, LocalMarcCharacter, False, iRomanizationTable%)

                If gblaRomanizationTable(iRomanizationTable%).V2RPersonalNameUppercase Then
                    ' todo: in reality, we should *only* add the comma if the first
                    '   indicator is one or two (regardless of indicator, we should
                    '   uppercase every word in the string)
                    Select Case sRecordType$
                        Case "A"
                            If InStr("100 400 500", sTag$) > 0 Then
ReRomanizeTextPersonalNameHandling:

                                lPtr = InStr(sOut$, LocalMarcRecordObject.MarcDelimiter + "a")

                                If lPtr > 0 Then
                                    sLeft$ = Mid(sOut$, 1, lPtr + 1)
                                    sOut$ = Mid(sOut$, lPtr + 2)
                                ElseIf Mid(sOut$, 1, 1) = LocalMarcRecordObject.MarcDelimiter Then

                                    GoTo ReRomanizeTextNoPNH
                                Else
                                    sLeft$ = ""
                                End If
                                lPtr = InStr(sOut$, LocalMarcRecordObject.MarcDelimiter)
                                If lPtr > 0 Then
                                    sRight$ = Mid(sOut$, lPtr)
                                    sOut$ = Mid(sOut$, 1, lPtr - 1)
                                Else
                                    sRight$ = ""
                                End If
                                sOut$ = Trim(sOut$)

                                ' first "word" in the heading remains as such
                                lPtr = InStr(sOut$, " ")
                                If lPtr > 0 Then
                                    sLeft$ = sLeft$ + LocalMarcRecordObject.UCaseFirstWord(Mid(sOut$, 1, lPtr - 1) + ",")
                                    sOut$ = Trim(Mid(sOut$, lPtr + 1))
                                    Do While Len(sOut$) > 0
                                        GetNextPiece sOut$, sWord$, " "
                                        sLeft$ = sLeft$ + " " + LocalMarcRecordObject.UCaseFirstWord(sWord$)
                                    Loop
                                End If
                                sOut$ = sLeft$ + sOut$ + sRight$
                            End If
ReRomanizeTextNoPNH:        ' NOTE label in left margin
                        Case "B"
                            If InStr("100 400 600 700 800", sTag$) > 0 Then
                                GoTo ReRomanizeTextPersonalNameHandling
                            End If
                    End Select
                End If
                If Len(gblaRomanizationTable(iRomanizationTable%).V2RUppercaseFirstCharacterInSubfield) > 0 Then
                    If InStr(gblaRomanizationTable(iRomanizationTable%).V2RUppercaseFirstCharacterInSubfield, sTag$) > 0 Then
                        If InStr(sOut$, LocalMarcRecordObject.MarcDelimiter) > 0 Then
                            ' potentially interesting
                            For lPtr = Len(sOut$) - 2 To 1 Step -1
                                If Mid(sOut$, lPtr, 1) = LocalMarcRecordObject.MarcDelimiter Then
                                    If InStr(gblaRomanizationTable(iRomanizationTable%).V2RUppercaseFirstCharacterInSubfield, sTag$ + "/" + Mid(sOut$, lPtr + 1, 1)) > 0 Then
                                        sOut$ = Mid(sOut$, 1, lPtr + 1) + LocalMarcRecordObject.UCaseFirstWord(Mid(sOut$, lPtr + 2))
                                    End If
                                End If
                            Next ' lptr
                        ElseIf Len(sSubfieldCode$) > 0 Then
                            If InStr(gblaRomanizationTable(iRomanizationTable%).V2RUppercaseFirstCharacterInSubfield, sTag$ + "/" + sSubfieldCode$) > 0 Then
                                sOut$ = LocalMarcRecordObject.UCaseFirstWord(sOut$)
                            End If
                        End If
                    End If
                End If
        End Select

    End If
    
    ReRomanizeText = LocalMarcRecordObject.RemoveRepeatedCharacters(sOut$, " ")
    
    'DumpRomanizationTables
    
End Function

Public Sub LoadOneRomanizationTable(ByVal sFileNameIncludingPath$, ByRef LocalMarcRecordObject As Utf8MarcRecordClass, ByRef LocalCharacterObject As Utf8CharClass, ByRef sDefaultFieldsIncluded$, Optional ByRef ProgressBarCtrl As Control = Nothing)

    ' we're going to read the file line-by-line, even though it has the
    '   general appearance of an INI file, because it may be more than
    '   32K (for Chinese)
    
    Dim iIn%, iMode%, iElement%, iRc%, iRc2%, iRc3%
    
    Dim sRight$, sLeft$, sUpperCase$, sTruncation$, sOriginal$
    
    Dim bLeft As Boolean, bRight As Boolean
    
    sTruncation$ = "%"
    
    iIn% = FreeFile
    On Error GoTo LRFT_FileOpenError
    Open sFileNameIncludingPath$ For Input As #iIn%
    On Error GoTo 0
    
    ' if we get this far we must have *something*
    gbliRomanizationTableLast% = gbliRomanizationTableLast% + 1
    If gbliRomanizationTableLast% > gbliRomanizationTableMax% Then
        gbliRomanizationTableMax% = gbliRomanizationTableMax% + 5
        ReDim Preserve gblaRomanizationTable(0 To gbliRomanizationTableMax%)
    End If
    
    With gblaRomanizationTable(gbliRomanizationTableLast%)
        
        ' save the file name, in case we need to add to it later
        .FullFileName = sFileNameIncludingPath$
        
        ' by default, include everything 100 through 840
        .R2VFieldsIncluded = sDefaultFieldsIncluded$
        .V2RFieldsIncluded = sDefaultFieldsIncluded$
        ' these subfields are always excluded
        .R2VSubfieldsAlwaysExcluded = "uvxy0123456789"
        .V2RSubfieldsAlwaysExcluded = "uvxy0123456789"
        ' there is no additional tag-based exclusion of subfields
        .R2VOtherSubfieldsExcludedByTag = ""
        .V2ROtherSubfieldsExcludedByTag = ""
        ' 20070703: added IncludeFormattingCharactersLcPattern; default False
        .R2VIncludeFormattingCharactersLcPattern = False
        ' set default script identification code
        .R2VSubfield6Code = ""
        ' 20100809 Bucknum added: VowelMarker
        ' set default script vowel marker
        .R2VVowelMarker = ""
        
        Set .Roman2Vernacular = CreateObject("Scripting.Dictionary")
        Set .Vernacular2Roman = CreateObject("Scripting.Dictionary")
        
        .AllowDefineButton = False
        .FontName = ""
        
        Do While Not EOF(iIn%)
            Line Input #iIn%, sRight$

            '20090322 added by Bucknum:
            'monitor progress of romanization table load
            If Not ProgressBarCtrl Is Nothing Then
                DoEvents
                'add 2 to the line input for line-feed characters
                LoadRomanizationTablesProgress Len(sRight$) + 2, ProgressBarCtrl
            End If
            
            If Len(sRight$) > 0 Then
                If Mid(sRight$, 1, 1) <> "#" Then
                    If Mid(sRight$, 1, 1) = "[" Then
                        Select Case Trim(UCase(sRight$))
                            Case "[GENERAL]"
                                iMode% = 1
                            Case "[ROMANTOSCRIPT]"
                                iMode% = 2
                            Case "[SCRIPTTOROMAN]"
                                iMode% = 3
                            Case Else
                                If .NoRomanization Then ' 20070830 added
                                    Exit Do
                                End If
                                iMode% = 4 ' we'll ignore all of this!
                        End Select
                        
                    Else
                    
                        Select Case iMode%
                        
                            Case 1 ' general stanza: options and switches
                                GetNextPiece sRight$, sLeft$, "="
                                Select Case sLeft$
                                    Case "Name"
                                        .Name = sRight$
                                    Case "FontName"
                                        ' 20180928 added for font customization by language/script
                                        '   for Swiss-type, proportionally-spaced, sans-serif fonts
                                        .FontName = sRight$
                                    Case "NoRomanization"
                                        ' 20070830 added NoRomanization concept
                                        .NoRomanization = LocalMarcRecordObject.IsTrue(sRight$)
                                    Case "DoNotUse880Field"
                                        .DoNotUse880Field = LocalMarcRecordObject.IsTrue(sRight$)
                                    Case "AllowCaseVariation"
                                        .AllowCaseVariation = LocalMarcRecordObject.IsTrue(sRight$)
                                    Case "ApostropheCharacters"
                                        'Debug.Print "RA 2"
                                        .ApostropheCharacters = RomanizeConvertText(sRight$, LocalMarcRecordObject, LocalCharacterObject)
                                        If Len(.ApostropheCharacters) > 0 Then
                                            .ApostropheCharactersPresent = True
                                        End If
                                    Case "AllowDefineButton"
                                        .AllowDefineButton = LocalMarcRecordObject.IsTrue(sRight$)
                                    Case "BySyllables"
                                        .BySyllables = LocalMarcRecordObject.IsTrue(sRight$)
                                    Case "Truncation"
                                        sTruncation$ = sRight$
                                End Select
                                
                            Case 2 ' roman to vernacular script (including Wade-Giles to Pinyin)
                            
                                If InStr(sRight$, "=") > 0 Then
                                    GetNextPiece sRight$, sLeft$, "="
                                    Select Case sLeft$
                                        Case "FieldsIncluded"
                                            .R2VFieldsIncluded = sRight$
                                            GoTo LORT_NextLine
                                        Case "IncludeFormattingCharactersLcPattern"
                                            ' 20070703: added
                                            .R2VIncludeFormattingCharactersLcPattern = True
                                            GoTo LORT_NextLine
                                        Case "CreateEmpty880s"
                                            .R2VCreateEmpty880s = True
                                            GoTo LORT_NextLine
                                        Case "Subfield6Code"
                                            .R2VSubfield6Code = sRight$
                                            GoTo LORT_NextLine
                                        Case "SubfieldsAlwaysExcluded"
                                            .R2VSubfieldsAlwaysExcluded = sRight$
                                            GoTo LORT_NextLine
                                        Case "OtherSubfieldsExcludedByTag"
                                            .R2VOtherSubfieldsExcludedByTag = sRight$
                                            GoTo LORT_NextLine
                                        Case "VowelMarker"
                                            ' 20100809 Bucknum added:
                                            .R2VVowelMarker = sRight$
                                            GoTo LORT_NextLine
                                    End Select
LORT_RTV_ContinueWithDividedLine:   ' NOTE label in left margin
                                    bLeft = False
                                    bRight = False
                                    If Mid(sLeft$, 1, 1) = sTruncation$ Then
                                        bLeft = True
                                        sLeft$ = Mid(sLeft$, 2)
                                    End If
                                    If Right(sLeft$, 1) = sTruncation$ Then
                                        bRight = True
                                        sLeft$ = Mid(sLeft$, 1, Len(sLeft$) - 1)
                                    End If
                                    'Debug.Print "RA 3"
                                    sRight$ = RomanizeConvertText(sRight$, LocalMarcRecordObject, LocalCharacterObject)
                                    sLeft$ = RomanizeConvertText(sLeft$, LocalMarcRecordObject, LocalCharacterObject)
                                    'If Mid(sLeft$, 1, 1) = "v" Then
                                    '    Debug.Print "After 3: >" + sLeft$ + "< >" + sRight$ + "<"
                                    'End If
                                    
                                    iRc% = InStr(sRight$, "/")
                                    If iRc% > 0 Then
                                        sUpperCase$ = Mid(sRight$, 1, iRc% - 1)
                                        sRight$ = Mid(sRight$, iRc% + 1)
                                    Else
                                        sUpperCase$ = ""
                                    End If
                                    LocalCharacterObject.Utf8Char = sLeft$ ' isolating the first character
                                    If .Roman2Vernacular.Exists(LocalCharacterObject.Utf8Char) Then
                                        iElement% = .Roman2Vernacular.item(LocalCharacterObject.Utf8Char)
                                    Else
                                        .RomanLast = .RomanLast + 1
                                        If .RomanLast > .RomanMax Then
                                            .RomanMax = .RomanMax + 10
                                            ReDim Preserve .Roman(0 To .RomanMax)
                                        End If
                                        iElement% = .RomanLast
                                        .Roman2Vernacular.Add LocalCharacterObject.Utf8Char, iElement%
                                    End If
                                    .Roman(iElement%).DetailLast = .Roman(iElement%).DetailLast + 1
                                    If .Roman(iElement%).DetailLast > .Roman(iElement%).DetailMax Then
                                        .Roman(iElement%).DetailMax = .Roman(iElement%).DetailMax + 5
                                        ReDim Preserve .Roman(iElement%).Detail(0 To .Roman(iElement%).DetailMax)
                                    End If
                                    If .AllowCaseVariation Then
                                        .Roman(iElement%).Detail(.Roman(iElement%).DetailLast).FullString = LocalMarcRecordObject.SafeLCase(sLeft$)
                                        'Debug.Print "Before and after: >" + sLeft$ + "< >" + .Roman(iElement%).Detail(.Roman(iElement%).DetailLast).FullString + "<"
                                    Else
                                        .Roman(iElement%).Detail(.Roman(iElement%).DetailLast).FullString = sLeft$
                                    End If
                                    .Roman(iElement%).Detail(.Roman(iElement%).DetailLast).FullStringLengthInCharacters = LocalMarcRecordObject.SafeLen(sLeft$)
                                    .Roman(iElement%).Detail(.Roman(iElement%).DetailLast).FullStringLengthInBytes = Len(sLeft$)
                                    .Roman(iElement%).Detail(.Roman(iElement%).DetailLast).Equivalent = sRight$
                                    .Roman(iElement%).Detail(.Roman(iElement%).DetailLast).EquivalentUpperCasePresent = False
                                    If Len(sUpperCase$) > 0 Then
                                        .Roman(iElement%).Detail(.Roman(iElement%).DetailLast).EquivalentUpperCase = sUpperCase$
                                        .Roman(iElement%).Detail(.Roman(iElement%).DetailLast).EquivalentUpperCasePresent = True
                                    End If
                                    If bLeft Then
                                        If bRight Then
                                            .Roman(iElement%).Detail(.Roman(iElement%).DetailLast).MedialOnly = True
                                        Else
                                            .Roman(iElement%).Detail(.Roman(iElement%).DetailLast).TerminalOnly = True
                                        End If
                                    ElseIf bRight Then
                                        .Roman(iElement%).Detail(.Roman(iElement%).DetailLast).InitialOnly = True
                                    End If
                                
                                ElseIf InStr(sRight$, vbTab) > 0 Then
                                                        
                                    GetNextPiece sRight$, sLeft$, vbTab
                                    GoTo LORT_RTV_ContinueWithDividedLine
                                                                                        
                                End If
                                
                            Case 3 ' vernacular script to roman
                                
                                If InStr(sRight$, "=") > 0 Then
                                
                                    GetNextPiece sRight$, sLeft$, "="

                                    Select Case sLeft$
                                        Case "CreateEmptyFields" ' added 20070830
                                            .V2RCreateEmptyFields = True
                                            GoTo LORT_NextLine
                                        Case "FieldsIncluded"
                                            .V2RFieldsIncluded = sRight$
                                            GoTo LORT_NextLine
                                        Case "SubfieldsAlwaysExcluded"
                                            .V2RSubfieldsAlwaysExcluded = sRight$
                                            GoTo LORT_NextLine
                                        Case "OtherSubfieldsExcludedByTag"
                                            .V2ROtherSubfieldsExcludedByTag = sRight$
                                            GoTo LORT_NextLine
                                        Case "UppercaseFirstCharacterInSubfield"
                                            .V2RUppercaseFirstCharacterInSubfield = sRight$
                                            GoTo LORT_NextLine
                                        Case "PersonalNameHandling"
                                            .V2RPersonalNameUppercase = LocalMarcRecordObject.IsTrue(sRight$)
                                            GoTo LORT_NextLine
                                    End Select
LORT_VTR_ContinueWithDividedLine:
                                    bLeft = False
                                    bRight = False
                                    If Mid(sLeft$, 1, 1) = sTruncation$ Then
                                        bLeft = True
                                        sLeft$ = Mid(sLeft$, 2)
                                    End If
                                    If Right(sLeft$, 1) = sTruncation$ Then
                                        bRight = True
                                        sLeft$ = Mid(sLeft$, 1, Len(sLeft$) - 1)
                                    End If
                                    'Debug.Print "RA 4"
                                    sRight$ = RomanizeConvertText(sRight$, LocalMarcRecordObject, LocalCharacterObject)
                                    sLeft$ = RomanizeConvertText(sLeft$, LocalMarcRecordObject, LocalCharacterObject)
                                    iRc% = InStr(sRight$, "/")
                                    If iRc% > 0 Then
                                        sUpperCase$ = Mid(sRight$, 1, iRc% - 1)
                                        sRight$ = Mid(sRight$, iRc% + 1)
                                    Else
                                        sUpperCase$ = ""
                                    End If
                                    LocalCharacterObject.Utf8Char = sLeft$ ' isolating the first character
                                                                        
                                    If .Vernacular2Roman.Exists(LocalCharacterObject.Utf8Char) Then
                                        iElement% = .Vernacular2Roman.item(LocalCharacterObject.Utf8Char)
                                    Else
                                        .VernacularLast = .VernacularLast + 1
                                        If .VernacularLast > .VernacularMax Then
                                            .VernacularMax = .VernacularMax + 10
                                            ReDim Preserve .Vernacular(0 To .VernacularMax)
                                        End If
                                        iElement% = .VernacularLast
                                        .Vernacular2Roman.Add LocalCharacterObject.Utf8Char, iElement%
                                    End If
                                    .Vernacular(iElement%).DetailLast = .Vernacular(iElement%).DetailLast + 1
                                    If .Vernacular(iElement%).DetailLast > .Vernacular(iElement%).DetailMax Then
                                        .Vernacular(iElement%).DetailMax = .Vernacular(iElement%).DetailMax + 5
                                        ReDim Preserve .Vernacular(iElement%).Detail(0 To .Vernacular(iElement%).DetailMax)
                                    End If
                                    .Vernacular(iElement%).Detail(.Vernacular(iElement%).DetailLast).FullString = sLeft$
                                    .Vernacular(iElement%).Detail(.Vernacular(iElement%).DetailLast).FullStringLengthInCharacters = LocalMarcRecordObject.SafeLen(sLeft$)
                                    .Vernacular(iElement%).Detail(.Vernacular(iElement%).DetailLast).FullStringLengthInBytes = Len(sLeft$)
                                    .Vernacular(iElement%).Detail(.Vernacular(iElement%).DetailLast).Equivalent = sRight$
                                    .Vernacular(iElement%).Detail(.Vernacular(iElement%).DetailLast).EquivalentUpperCasePresent = False
                                    If bLeft Then
                                        If bRight Then
                                            .Vernacular(iElement%).Detail(.Vernacular(iElement%).DetailLast).MedialOnly = True
                                        Else
                                            .Vernacular(iElement%).Detail(.Vernacular(iElement%).DetailLast).TerminalOnly = True
                                        End If
                                    ElseIf bRight Then
                                        .Vernacular(iElement%).Detail(.Vernacular(iElement%).DetailLast).InitialOnly = True
                                    End If
                            
                                ' main condition is: contains equals sign?
                                ElseIf InStr(sRight$, vbTab) > 0 Then
                                    GetNextPiece sRight$, sLeft$, vbTab
                                    GoTo LORT_VTR_ContinueWithDividedLine
                                End If
                        
                        End Select
                    End If
                End If
            End If
LORT_NextLine:
        Loop
        If Len(.Name) = 0 Then
            .Name = "Unknown script #" + Trim(str(gbliRomanizationTableLast%))
        End If
        


    End With
    
    Close #iIn%
    
LRFT_FileOpenErrorresume:

    Exit Sub
    
LRFT_FileOpenError:

    Resume LRFT_FileOpenErrorresume
    
End Sub

Public Function RomanizeConvertText(ByVal sIn$, ByRef LocalMarcRecordObject As Utf8MarcRecordClass, ByRef LocalCharacterObject As Utf8CharClass) As String

    ' convert "&H notations to the equivalent, leaving other stuff as you find it
    Dim lPtr As Long
    
    Dim sLeader$, sOriginal$
    
    Dim bShow As Boolean
    
    
'    If InStr(sIn$, "U+") > 0 Then
'        bShow = True
'        sOriginal$ = sIn$
'    End If

    sIn$ = LocalMarcRecordObject.ReplaceCharacters(sIn$, "_", " ")
    
    sLeader$ = "&H"
    
    Do
        lPtr = InStr(sIn$, sLeader$)
        Do While lPtr > 0
            LocalCharacterObject.UcsHex = Mid(sIn$, lPtr + 2, 4)
            sIn$ = LocalMarcRecordObject.SafeStuff(sIn$, lPtr, 6, LocalCharacterObject.Utf8Char)
            lPtr = InStr(sIn$, sLeader$)
        Loop
        Select Case sLeader$
            Case "&H"
                sLeader$ = "U+"
            Case "U+"
                sLeader$ = "&x"
            Case "&x"
                sLeader$ = "&X"
            Case "&X"
                sLeader$ = "&h"
            Case "&h"
                Exit Do
        End Select
    Loop
    
'    If bShow Then
'        Debug.Print "RCT >" + sOriginal$ + "< >" + sIn$ + "<"
'    End If
    
    RomanizeConvertText = sIn$
    
End Function

Public Sub LoadRomanizationTables(ByVal sConfigurationFilePath$, ByRef LocalMarcRecordObject As Utf8MarcRecordClass, ByRef LocalCharacterObject As Utf8CharClass, Optional ByRef ProgressBarCtrl As Control = Nothing)

    Dim sMasterFile$, sFile$, sDefaultFieldsIncluded$
    
    Dim iCtr%
    
'    Static bLoaded As Boolean
    
    Dim bDebug As Boolean
    
    ' 20090322 changed by Bucknum:
    ' removed bLoaded to allow reloading tables
'    If bLoaded Then
'        Exit Sub
'    End If
    
    'prvsRightToLeftMarker$ , prvsLeftToRightMarker$
    
    'prvsRightToLeftMarker$ = LocalMarcRecordObject.MarcRightToLeftMarker
    'prvsLeftToRightMarker$ = LocalMarcRecordObject.MarcLeftToRightMarker
    
    For iCtr% = 100 To 840
        sDefaultFieldsIncluded$ = sDefaultFieldsIncluded$ + " " + Trim(str(iCtr%))
    Next ' irc%
    
    sMasterFile$ = sConfigurationFilePath$ + "RomanizationMaster.cfg"
    
    bDebug = LocalMarcRecordObject.IsTrue(ReadIniFile(sMasterFile$, "Files", "Debug", "False", 15))
        
    iCtr% = 1
    Do
        sFile$ = ReadIniFileOrNothing(sMasterFile$, "Files", Trim(str(iCtr%)), 250)
        If Len(sFile$) = 0 Then
            If bDebug Then
                MsgBox "For " + Trim(str(iCtr%)) + " read: >" + sFile$ + "<"
            End If
            Exit Do
        End If
        If InStr(sFile$, "\") = 0 Then
            If LenB(Dir$(sConfigurationFilePath$ + sFile$)) > 0 And gblaRomanizationScript(iCtr%).LoadScript Then
                LoadOneRomanizationTable sConfigurationFilePath$ + sFile$, LocalMarcRecordObject, LocalCharacterObject, sDefaultFieldsIncluded$, ProgressBarCtrl
                If bDebug Then
                    MsgBox "For " + Trim(str(iCtr%)) + " read: >" + sConfigurationFilePath$ + sFile$ + "< vernacular entries " + str(gblaRomanizationTable(gbliRomanizationTableLast%).VernacularLast) + " roman entries " + str(gblaRomanizationTable(gbliRomanizationTableLast%).RomanLast)
                End If
            End If
        Else
            If LenB(Dir$(sFile$)) > 0 And gblaRomanizationScript(iCtr%).LoadScript Then
                LoadOneRomanizationTable sFile$, LocalMarcRecordObject, LocalCharacterObject, sDefaultFieldsIncluded$, ProgressBarCtrl
                If bDebug Then
                    MsgBox "For " + Trim(str(iCtr%)) + " read: >" + sFile$ + "< vernacular entries " + str(gblaRomanizationTable(gbliRomanizationTableLast%).VernacularLast) + " roman entries " + str(gblaRomanizationTable(gbliRomanizationTableLast%).RomanLast)
                End If
            End If
        End If
        iCtr% = iCtr% + 1
    Loop
    
'    bLoaded = True
    
End Sub

Public Sub DumpRomanizationTables()

    Dim iCtr%, iCtr2%, iCtr3%
    
    For iCtr% = 1 To gbliRomanizationTableLast%
        With gblaRomanizationTable(iCtr%)
            Debug.Print "Name: " + .Name
            Debug.Print "Roman to vernacular"
            For iCtr2% = 1 To .RomanLast
                With .Roman(iCtr2%)
                    For iCtr3% = 1 To .DetailLast
                        Debug.Print vbTab + .Detail(iCtr3%).FullString + vbTab + .Detail(iCtr3%).Equivalent
                    Next ' ictr3%
                End With
            Next ' ictr2%
            Debug.Print "Vernacular to roman"
            For iCtr2% = 1 To .VernacularLast
                With .Vernacular(iCtr2%)
                    For iCtr3% = 1 To .DetailLast
                        Debug.Print vbTab + .Detail(iCtr3%).FullString + vbTab + .Detail(iCtr3%).Equivalent
                    Next ' ictr3%
                End With
            Next ' ictr2%
        End With
    Next ' ictr%
    
End Sub

Public Sub LoadListOfScriptsIntoControl(ByRef c As Control)

    Dim iCtr%

    With c
        If c.style = vbListBoxCheckbox Then
            c.Clear
            For iCtr% = 1 To gbliRomanizationScriptLast%
                .AddItem gblaRomanizationScript(iCtr%).Name
                .Selected(iCtr% - 1) = gblaRomanizationScript(iCtr%).LoadScript
            Next ' ictr%
        Else
            If .ListCount = 0 Then
                For iCtr% = 1 To gbliRomanizationTableLast%
                    .AddItem gblaRomanizationTable(iCtr%).Name
                Next ' ictr%
                If .ListCount > 0 Then
                    .ListIndex = 0
                End If
            End If
        End If
    End With

End Sub

Private Function ReRomanizeTextDetails(ByVal sText$, ByRef oRomanizationTable As Object, ByRef RomanizationTable() As ROMANIZATIONDETAILARRAY, ByRef LocalMarcRecordObject As Utf8MarcRecordClass, ByRef LocalMarcCharacter As Utf8CharClass, ByVal bRoman2Vernacular As Boolean, ByVal iRomanizationTable%)

    Dim iLen%, iLengthBeforeApostropheSubstitution%
    
    Dim lPtr As Long, lPtr2 As Long, lMember As Long, lCtr As Long, lEnd As Long
    
    Dim sOut$, sPreviousCharacter$, sSyllable$, sChar1$, sChar2$, sOriginalSyllable$
    
    Dim bFound As Boolean, bFirstCharacter As Boolean, bFirstCharacterIsUppercase As Boolean
    Dim bApostrophes As Boolean, bWholeThingIsUppercase As Boolean, bChanged As Boolean
    Dim bAllowCaseVariation
    
    ' we have to manipulate pointers directly, ourselves, because
    '   of varying character length
    lPtr = 1
    lEnd = Len(sText$)
        
    bApostrophes = gblaRomanizationTable(iRomanizationTable%).ApostropheCharactersPresent
    

    
    If gblaRomanizationTable(iRomanizationTable%).AllowCaseVariation Then
        bAllowCaseVariation = True
    End If
    
    If Not gblaRomanizationTable(iRomanizationTable%).BySyllables Then
    
        ' we're working by characters
        bFirstCharacter = True
        Do While lPtr <= lEnd
            bFound = False
            If lPtr > 1 Then
                sPreviousCharacter$ = LocalMarcCharacter.Utf8Char
                If sPreviousCharacter$ = " " Then
                    bFirstCharacterIsUppercase = False
                End If
            End If
            LocalMarcCharacter.Utf8Char = Mid(sText$, lPtr)
            ' 20061129: if we're going to be ignoring case, then
            '   convert to lowercase
            If bAllowCaseVariation Then
                If LocalMarcCharacter.Utf8CharCategory = "Lu" Then
                    LocalMarcCharacter.Utf8Char = LocalMarcRecordObject.SafeLCase(LocalMarcCharacter.Utf8Char)
                    If bFirstCharacter Or sPreviousCharacter$ = " " Then
                        bFirstCharacterIsUppercase = True
                    End If
                End If
            End If
            If InStr("Lu Ll Lo", LocalMarcCharacter.Utf8CharCategory) > 0 Then
                bFirstCharacter = False
            End If

            If LocalMarcCharacter.Utf8Char = LocalMarcCharacter.MarcDelimiter Then
                sOut$ = sOut$ + Mid(sText$, lPtr, 2) ' delimiter and subfield code
                lPtr = lPtr + 1 ' we'll add one more at the bottom of the loop as per usual
                iLen% = 1 ' make sure we only skip one more!
            Else ' not at a delimiter: must be some character worthy of inspection
                iLen% = LocalMarcCharacter.Utf8CharOctets
                If oRomanizationTable.Exists(LocalMarcCharacter.Utf8Char) Then
                    lMember = oRomanizationTable.item(LocalMarcCharacter.Utf8Char)

                    With RomanizationTable(lMember)
                        For lCtr = 1 To .DetailLast

                            If .Detail(lCtr).InitialOnly Then
                                ' 20100103 added by Bucknum:
                                '  we are expecting more character(s) to follow, so the
                                '  following 2 statements check for end of the word
                                If lPtr + .Detail(lCtr).FullStringLengthInBytes >= lEnd Then
                                    ' this is the end of the word; so no dice
                                    GoTo RRTD_NextDetail
                                ElseIf InStr(" -.?,;:!""])" + LocalMarcRecordObject.MarcDelimiter, Mid(sText$, lPtr + .Detail(lCtr).FullStringLengthInBytes, 1)) > 0 Then
                                    ' this is also the end of the word; so no dice
                                    GoTo RRTD_NextDetail
                                ElseIf lPtr = 1 Then
                                    ' this is OK: first character in the string is taken
                                    '   to be start of a word
                                    ' 20180801: Bucknum added left bracket and parenthesis
                                ElseIf InStr(" -""[(", Mid(sText$, lPtr - 1, 1)) > 0 Then
                                    ' this is OK, too: previous character is a word-breaker
                                    '   (following space, hyphen, quote, bracket or parenthesis), so current
                                    '   character is the first in this word
                                ElseIf lPtr > 2 Then
                                    If Mid(sText$, lPtr - 2, 1) = LocalMarcRecordObject.MarcDelimiter Then
                                        ' this is OK, too: character is first in its subfield
                                    Else
                                        GoTo RRTD_NextDetail
                                    End If
                                Else
                                    ' not at the beginning of a word
                                    GoTo RRTD_NextDetail
                                End If
                            ElseIf .Detail(lCtr).TerminalOnly Then
                                ' 20070731: we were using iLen% here as the length; but we should be using
                                '   the length of the character(s) in the defined terminal-only string
                                '   (for example, the current character may be "o" but if we're looking for
                                '   terminal "ot" then we need to compare and skip over 2 characters, not 1)
                                ' fortunately, we already have FullStringLengthInBytes giving the length of
                                '   the string to be found in the original record

                                If lPtr + .Detail(lCtr).FullStringLengthInBytes > lEnd Then
                                    ' this is OK: must be last character in the string
                                ElseIf InStr(" -.?,;:!""])" + LocalMarcRecordObject.MarcDelimiter, Mid(sText$, lPtr + .Detail(lCtr).FullStringLengthInBytes, 1)) > 0 Then
                                    ' this is OK, too: next character is a word-breaker,
                                    '   so current character is the last in this word
                                Else
                                    ' not at the end of a word
                                    GoTo RRTD_NextDetail
                                End If
                                ' if we get here then we're at the end of the word and so ready
                                '   to test the characters
                            ElseIf .Detail(lCtr).MedialOnly Then
                                ' can not be either the beginning or the ending of a word
                                ' we'll simply reverse all of the above tests; in this case the
                                '   leftovers are the things that aren't either beginning or
                                '   end--they must be medial
                                If lPtr = 1 Then
                                    ' initial: so no dice
                                    GoTo RRTD_NextDetail
                                ElseIf InStr(" -""[(", Mid(sText$, lPtr - 1, 1)) > 0 Then
                                    ' initial (following space, hyphen, quote, bracket or parenthesis): so no dice
                                    ' 20180801: Bucknum added left bracket and parenthesis
                                    GoTo RRTD_NextDetail
                                ElseIf lPtr > 2 Then
                                    If Mid(sText$, lPtr - 2, 1) = LocalMarcRecordObject.MarcDelimiter Then
                                        ' beginning of a subfield: so no dice
                                        GoTo RRTD_NextDetail
                                    End If
                                ' 20070731: see comment above (at TerminalOnly) regarding the
                                '   length to be used in the following 2 statements
                                ElseIf lPtr + .Detail(lCtr).FullStringLengthInBytes >= lEnd Then
                                    ' this is the end of the word; so no dice
                                    GoTo RRTD_NextDetail
                                ElseIf InStr(" -.?,;:!""])" + LocalMarcRecordObject.MarcDelimiter, Mid(sText$, lPtr + .Detail(lCtr).FullStringLengthInBytes, 1)) > 0 Then
                                    ' this is also the end of the word; so no dice
                                    GoTo RRTD_NextDetail
                                End If
                                ' if we get here, then we're somewhere within a word and ready to
                                '   test the characters
                            End If
                            ' if we get here, either we don't care what position the character
                            '   bears within its word, or whatever conditions were specified have
                            '   been met
                            If bRoman2Vernacular Then
                                If LocalMarcCharacter.Utf8CharCategory = "Lu" Then

                                    If Not bApostrophes Then
                                        If Mid(sText, lPtr, .Detail(lCtr).FullStringLengthInBytes) = .Detail(lCtr).FullString Then
                                            bFound = True
                                            If .Detail(lCtr).EquivalentUpperCasePresent Then
                                                If Len(sPreviousCharacter$) = 0 Then
                                                    sOut$ = sOut$ + .Detail(lCtr).Equivalent
                                                Else
                                                    LocalMarcCharacter.Utf8Char = sPreviousCharacter$
                                                    If LocalMarcCharacter.Utf8CharCategory = "Lu" Then
                                                        sOut$ = sOut$ + .Detail(lCtr).EquivalentUpperCase
                                                    Else
                                                        sOut$ = sOut$ + .Detail(lCtr).Equivalent
                                                    End If
                                                End If
                                                bChanged = True
                                                iLen% = .Detail(lCtr).FullStringLengthInBytes
                                            Else
                                                If bFirstCharacterIsUppercase Then
                                                    sOut$ = sOut$ + LocalMarcRecordObject.UCaseFirstWord(.Detail(lCtr).Equivalent)
                                                    bFirstCharacterIsUppercase = False
                                                Else
                                                    sOut$ = sOut$ + .Detail(lCtr).Equivalent
                                                End If
                                                bChanged = True
                                                iLen% = .Detail(lCtr).FullStringLengthInBytes
                                            End If
                                            Exit For
                                        End If
                                    Else ' apostrophes were defined

                                        If ReRomanizeTextDetailsReplaceApostrophes(LocalMarcRecordObject.SafeUCase(LocalMarcRecordObject.SafeMid(sText, lPtr, .Detail(lCtr).FullStringLengthInCharacters)), iRomanizationTable%, LocalMarcCharacter, iLengthBeforeApostropheSubstitution%) = .Detail(lCtr).FullString Then

                                            bFound = True
                                            If .Detail(lCtr).EquivalentUpperCasePresent Then
                                                If Len(sPreviousCharacter$) = 0 Then
                                                    sOut$ = sOut$ + .Detail(lCtr).Equivalent
                                                Else
                                                    LocalMarcCharacter.Utf8Char = sPreviousCharacter$
                                                    If LocalMarcCharacter.Utf8CharCategory = "Lu" Then
                                                        sOut$ = sOut$ + .Detail(lCtr).EquivalentUpperCase
                                                    Else
                                                        sOut$ = sOut$ + .Detail(lCtr).Equivalent
                                                    End If
                                                End If
                                                bChanged = True
                                                iLen% = iLengthBeforeApostropheSubstitution% '.Detail(lCtr).FullStringLengthInCharacters
                                            Else
                                                If bFirstCharacterIsUppercase Then
                                                    sOut$ = sOut$ + LocalMarcRecordObject.UCaseFirstWord(.Detail(lCtr).Equivalent)
                                                    bFirstCharacterIsUppercase = False
                                                Else
                                                    sOut$ = sOut$ + .Detail(lCtr).Equivalent
                                                End If
                                                bChanged = True
                                                iLen% = iLengthBeforeApostropheSubstitution% '.Detail(lCtr).FullStringLengthInCharacters
                                            End If
                                            Exit For
                                        End If
                                    End If
                                Else ' category is not letter/uppercase

                                    If Not bApostrophes Then
                                        If Mid(sText, lPtr, .Detail(lCtr).FullStringLengthInBytes) = .Detail(lCtr).FullString Or (bAllowCaseVariation And LCase(Mid(sText, lPtr, .Detail(lCtr).FullStringLengthInBytes)) = .Detail(lCtr).FullString) Then
                                        'If Mid(sText, lPtr, .Detail(lCtr).FullStringLengthInBytes) = .Detail(lCtr).FullString Then
                                            bFound = True
                                            If .Detail(lCtr).EquivalentUpperCasePresent Then
                                                If Len(sPreviousCharacter$) = 0 Then
                                                    sOut$ = sOut$ + .Detail(lCtr).Equivalent
                                                Else
                                                    LocalMarcCharacter.Utf8Char = sPreviousCharacter$
                                                    'Debug.Print "Previous " + sPreviousCharacter$ + " category " + LocalMarcCharacter.Utf8CharCategory
                                                    If LocalMarcCharacter.Utf8CharCategory = "Lu" Then
                                                        sOut$ = sOut$ + .Detail(lCtr).EquivalentUpperCase
                                                    Else
                                                        sOut$ = sOut$ + .Detail(lCtr).Equivalent
                                                    End If
                                                End If
                                                bChanged = True
                                                iLen% = .Detail(lCtr).FullStringLengthInBytes
                                            Else
                                                If bFirstCharacterIsUppercase Then
                                                    sOut$ = sOut$ + LocalMarcRecordObject.UCaseFirstWord(.Detail(lCtr).Equivalent)
                                                    bFirstCharacterIsUppercase = False
                                                Else
                                                    sOut$ = sOut$ + .Detail(lCtr).Equivalent
                                                End If
                                                bChanged = True
                                                iLen% = .Detail(lCtr).FullStringLengthInBytes
                                            End If
                                            Exit For
                                        End If
                                    Else ' apostrophes are defined

                                        If ReRomanizeTextDetailsReplaceApostrophes(LocalMarcRecordObject.SafeLCase(LocalMarcRecordObject.SafeMid(sText, lPtr, .Detail(lCtr).FullStringLengthInCharacters)), iRomanizationTable%, LocalMarcCharacter, iLengthBeforeApostropheSubstitution%) = .Detail(lCtr).FullString Then
                                            bFound = True

                                            If .Detail(lCtr).EquivalentUpperCasePresent Then
                                                If Len(sPreviousCharacter$) = 0 Then
                                                    sOut$ = sOut$ + .Detail(lCtr).Equivalent
                                                Else
                                                    LocalMarcCharacter.Utf8Char = sPreviousCharacter$
                                                    'Debug.Print "Previous " + sPreviousCharacter$ + " category " + LocalMarcCharacter.Utf8CharCategory
                                                    If LocalMarcCharacter.Utf8CharCategory = "Lu" Then
                                                        sOut$ = sOut$ + .Detail(lCtr).EquivalentUpperCase
                                                    Else
                                                        sOut$ = sOut$ + .Detail(lCtr).Equivalent
                                                    End If
                                                End If
                                                iLen% = iLengthBeforeApostropheSubstitution% '.Detail(lCtr).FullStringLengthInCharacters
                                            Else
                                                If bFirstCharacterIsUppercase Then
                                                    sOut$ = sOut$ + LocalMarcRecordObject.UCaseFirstWord(.Detail(lCtr).Equivalent)
                                                    bFirstCharacterIsUppercase = False
                                                Else
                                                    sOut$ = sOut$ + .Detail(lCtr).Equivalent
                                                End If
                                                iLen% = iLengthBeforeApostropheSubstitution% ' .Detail(lCtr).FullStringLengthInCharacters
                                            End If
                                            Exit For
                                        End If
                                    End If
                                End If
                            Else ' vernacular to roman
                                'Debug.Print "Considering " + str(.Detail(lCtr).FullStringLengthInBytes) + "< and >" + .Detail(lCtr).FullString + "<"
                                If Mid(sText, lPtr, .Detail(lCtr).FullStringLengthInBytes) = .Detail(lCtr).FullString Then
                                    bFound = True
                                    sOut$ = sOut$ + .Detail(lCtr).Equivalent

                                    iLen% = .Detail(lCtr).FullStringLengthInBytes
                                    If Right(sOut$, 1) = " " Then
                                        lPtr2 = lPtr + iLen%
                                        If lPtr2 <= lEnd Then
                                            LocalMarcCharacter.Utf8Char = Mid(sText$, lPtr2)
                                            If Mid(LocalMarcCharacter.Utf8CharCategory, 1, 1) = "P" Then
                                                sOut$ = RTrim(sOut$)
                                            End If
                                        End If
                                    End If
                                    Exit For
                                End If
                            End If
RRTD_NextDetail:            ' NOTE label in left margin
                        Next ' lctr
                    End With
                Else

                    bFound = False
                End If
                If Not bFound Then
                    sOut$ = sOut$ + LocalMarcCharacter.Utf8Char
                End If
                'Debug.Print "Disposition: " + str(bFound) + " >" + LocalMarcCharacter.Utf8Char + "< >" + sOut$ + "<"
            End If
            lPtr = lPtr + iLen%
            
        Loop

        'Debug.Print "LC PATTERN? " + str(gblaRomanizationTable(iRomanizationTable%).R2VIncludeFormattingCharactersLcPattern) + " " + str(bChanged)
        ' 20070703: it seems simplest to throw this on at the end
        ' LC wants a RTL marker before and after each delimiter,
        '   EXCEPT immediately following the $6 marker itself
        ' note that this can ONLY apply to things done character-by-character; doesn't apply
        '   to "by syllables" (I think!)
        If gblaRomanizationTable(iRomanizationTable%).R2VIncludeFormattingCharactersLcPattern And bChanged Then
            For lPtr = Len(sOut$) - 1 To 1 Step -1
                If Mid(sOut$, lPtr, 1) = LocalMarcRecordObject.MarcDelimiter Then
                    lPtr2 = InStr(Mid(sOut$, lPtr + 1), LocalMarcRecordObject.MarcDelimiter)
                    'Debug.Print "At delim: " + str(lPtr) + " " + str(lPtr2) + " >" + sOut$ + "< marker >" + LocalMarcRecordObject.MarcRightToLeftMarker + "< " + str(Len(LocalMarcRecordObject.MarcRightToLeftMarker))
                    If lPtr2 <> 0 Then
                        sOut$ = LocalMarcRecordObject.SafeStuff(sOut$, lPtr + lPtr2, 0, LocalMarcRecordObject.MarcRightToLeftMarker)
                    End If
                    ' there should not be a $6 in the text!
                    If Mid(sOut$, lPtr + 1, 1) <> "6" Then
                        sOut$ = LocalMarcRecordObject.SafeStuff(sOut$, lPtr + 2, 0, LocalMarcRecordObject.MarcRightToLeftMarker)
                    End If
                    'Debug.Print "After:  >" + sOut$ + "<"
                End If
            Next ' lptr
        End If
        
    Else ' we *are* proceeding by syllables
            
        ' move any troublesome lead characters to the output, so we end up pointed
        '   to the first "real" character in the first syllable--as close as we can
        '   determine it, anyway
        ' we'll include the apostrophe here, because it's only *internal* ones that
        '   we need to pay attention to
        ' todo: this might be better if done via the character object, and with
        '   character categories ...
        bFirstCharacter = True
        Do
            Select Case Mid(sText$, lPtr, 1)
                Case "-", " ", ".", ";", ":", "(", ")", "[", "]", "!", "?", "'", Chr(34)
                    lPtr = lPtr + 1
                Case LocalMarcRecordObject.MarcDelimiter
                    lPtr = lPtr + 2
                Case Else
                    Exit Do
            End Select
            If lPtr > lEnd Then
                Exit Do
            End If
        Loop
        ' attach any skipped characters to the output
        If lPtr > 1 Then
            sOut$ = Mid(sText$, 1, lPtr - 1)
        End If
        
        ' when we arrive here, lPtr points to the first character of real interest
        
        Do While lPtr <= lEnd
            ' starting from the character pointed to by lPtr, which we will assume
            '   to be the first character in a "syllable", find the end of the
            '   next syllable
            iLen% = 0
            ' do NOT here break at a hyphen!
            For lPtr2 = lPtr + 1 To lEnd
                If InStr("- .;:)([]!?" + Chr(34) + LocalMarcRecordObject.MarcDelimiter, Mid(sText, lPtr2, 1)) > 0 Then
                    iLen% = lPtr2 - lPtr
                    Exit For
                End If
            Next ' lptr2
            ' if we didn't find any more words, we assume that
            '   we're at the end of the string altogether
            If iLen% = 0 Then
                iLen% = Len(Mid(sText$, lPtr))
            End If
            sSyllable$ = Mid(sText, lPtr, iLen%)
            If Right(sSyllable$, 1) = "'" Then
                iLen% = iLen% - 1
                lPtr2 = lPtr2 - 1
                sSyllable$ = Mid(sSyllable$, 1, Len(sSyllable$) - 1)
            End If

            sOriginalSyllable$ = sSyllable$
            
            ' in the next paragraph, we're determining whether the first character
            '   is uppercase, or the whole thing is uppercase--we'll preserve
            '   case in the finished string to the extent possible
#If True Then
            ' 20070109: paradigm changed (now much simpler); changed mostly because
            '   the old one didn't work properly anyway
            If sSyllable$ = LocalMarcRecordObject.SafeUCase(sSyllable$) Then
                ' the only way this can happen is if it's all uppercase
                bWholeThingIsUppercase = True
                bFirstCharacterIsUppercase = False
                If gblaRomanizationTable(iRomanizationTable%).AllowCaseVariation Then
                    sSyllable$ = LocalMarcRecordObject.SafeLCase(sSyllable$)
                End If
            ElseIf sSyllable$ = LocalMarcRecordObject.SafeLCase(sSyllable$) Then
                bWholeThingIsUppercase = False
                bFirstCharacterIsUppercase = False
            Else
                ' there is some difference between the lowercase and uppercase versions:
                '   for Wade-Giles, we *should* be able to assume that the difference
                '   is on the first character
                bWholeThingIsUppercase = False
                bFirstCharacterIsUppercase = True
                If gblaRomanizationTable(iRomanizationTable%).AllowCaseVariation Then
                    sSyllable$ = LocalMarcRecordObject.SafeLCase(sSyllable$)
                End If
            End If
            LocalMarcCharacter.Utf8Char = sSyllable$

#Else
            ' get the first character of this syllable
            LocalMarcCharacter.Utf8Char = sSyllable$
            If gblaRomanizationTable(iRomanizationTable%).AllowCaseVariation Then
                If LocalMarcCharacter.Utf8CharCategory = "Lu" Then
                    bFirstCharacterIsUppercase = True
                    bWholeThingIsUppercase = True
                    Do
                        sSyllable$ = Mid(sSyllable$, LocalMarcCharacter.Utf8CharOctets + 1)
                        If Len(sSyllable$) = 0 Then
                            Exit Do
                        End If
                        'Debug.Print "Remaining syllable: >" + sSyllable$ + "<"
                        LocalMarcCharacter.Utf8Char = sSyllable$
                        'Debug.Print "Category: >" + LocalMarcCharacter.Utf8CharCategory + "<"
                        If LocalMarcCharacter.Utf8CharCategory <> "Lu" Then
                            bWholeThingIsUppercase = False
                            Exit Do
                        End If
                    Loop
                    ' re-get the whole syllable
                    sSyllable$ = Mid(sText, lPtr, iLen%)
                    LocalMarcCharacter.Utf8Char = sSyllable$
                End If
                ' in any case, because case variation is allowed, we'll
                '   convert the syllable to lowercase
                sSyllable$ = LocalMarcRecordObject.SafeLCase(sSyllable$)
                LocalMarcCharacter.Utf8Char = sSyllable$
            End If
#End If ' alternative methods for determining casing of the existing syllable
            
            ' deal with things that look like apostrophes
            If bApostrophes Then
                sSyllable$ = ReRomanizeTextDetailsReplaceApostrophes(sSyllable$, iRomanizationTable%, LocalMarcCharacter, iLengthBeforeApostropheSubstitution%)
            End If
            
            bFound = False
            If oRomanizationTable.Exists(LocalMarcCharacter.Utf8Char) Then
                lMember = oRomanizationTable.item(LocalMarcCharacter.Utf8Char)
                With RomanizationTable(lMember)
                    For lCtr = 1 To .DetailLast
                        If bRoman2Vernacular Then
                            If sSyllable$ = .Detail(lCtr).FullString Then
                                bFound = True
                                If bWholeThingIsUppercase Then
                                    sOut$ = sOut$ + LocalMarcRecordObject.SafeUCase(.Detail(lCtr).Equivalent)
                                    bFirstCharacterIsUppercase = False
                                ElseIf bFirstCharacterIsUppercase Then
                                    sOut$ = sOut$ + LocalMarcRecordObject.UCaseFirstWord(.Detail(lCtr).Equivalent)
                                    bFirstCharacterIsUppercase = False
                                Else
                                    sOut$ = sOut$ + .Detail(lCtr).Equivalent
                                End If
                                Exit For
                            End If
                        Else ' vernacular to roman
                            If sSyllable$ = .Detail(lCtr).FullString Then
                                bFound = True
                                sOut$ = sOut$ + .Detail(lCtr).Equivalent
                                Exit For
                            End If
                        End If
                    Next ' lctr
                End With
            Else

                sSyllable$ = sOriginalSyllable$
                bFound = False
            End If
            If Not bFound Then
                sOut$ = sOut$ + sSyllable$
            End If
            
            ' skip the syllable in input
            lPtr = lPtr + iLen%
            If lPtr > lEnd Then
                ' no more input: all done
                Exit Do
            End If
            ' move additional characters to the output string until
            '   you hit the first that's not a "division" character
            Do
                Select Case Mid(sText$, lPtr, 1)
                    Case "-", " ", ".", ";", ":", "(", ")", "[", "]", "!", "?", "'", Chr(34)
                        sOut$ = sOut$ + Mid(sText$, lPtr, 1)
                        lPtr = lPtr + 1
                        If lPtr > lEnd Then
                            Exit Do
                        End If
                    Case LocalMarcRecordObject.MarcDelimiter
                        sOut$ = sOut$ + Mid(sText$, lPtr, 2)
                        lPtr = lPtr + 2
                        If lPtr > lEnd Then
                            Exit Do
                        End If
                    Case Else
                            Exit Do
                End Select
            Loop
            If lPtr > lEnd Then
                Exit Do
            End If
            
        Loop ' for each syllable
        
    End If
    
    'DumpRomanizationTables
    


    ReRomanizeTextDetails = sOut$
    
End Function

Public Function EvaluateFirstCharacter(ByVal sText$, ByVal iRomanizationTable%, ByRef LocalMarcCharacter As Utf8CharClass) As Integer

    Dim lPtr As Long, lLength As Long
        
    Dim iLength%
    
        

    EvaluateFirstCharacter = ROMANIZATIONDIRECTION_Unknown%
        
    If iRomanizationTable% < 1 Or iRomanizationTable% > gbliRomanizationTableLast% Then
        ' do nothing: already set to unknown
    Else
        With gblaRomanizationTable(iRomanizationTable%)

            ' first determination: are we converting script from vernacular into
            '   roman or from roman into vernacular: the first charcter will tell
            '   us everything we need to know
            lPtr = 1
            lLength = Len(sText$)
            Do While lPtr <= lLength
                LocalMarcCharacter.Utf8Char = Mid(sText$, lPtr)
                If LocalMarcCharacter.Utf8Char = LocalMarcCharacter.MarcDelimiter Then
                    ' we'll skip this, and the following character, but do nothing
                    '   about either of 'em
                    iLength% = 2
                Else
                    iLength% = LocalMarcCharacter.Utf8CharOctets
    #If EvaluateFirstCharacterDebug = -1 Then
                    Debug.Print "Char: >" + LocalMarcCharacter.Utf8Char + "< " + str(iLength%)
    #End If
                    If .Roman2Vernacular.Exists(LocalMarcCharacter.Utf8Char) Then
                        EvaluateFirstCharacter = ROMANIZATIONDIRECTION_Roman2Vernacular%
                        Exit Do
                    ElseIf .Vernacular2Roman.Exists(LocalMarcCharacter.Utf8Char) Then
                        EvaluateFirstCharacter = ROMANIZATIONDIRECTION_Vernacular2Roman%
                        Exit Do
                    End If
                End If
                lPtr = lPtr + iLength%
            Loop
        End With
    End If
    
End Function

Public Function ReRomanizeTextDetailsReplaceApostrophes(ByVal sString$, ByVal iRomanizationTable%, ByRef LocalCharacterObject As Utf8CharClass, ByRef iLengthBeforeApostropheSubstitution%) As String

    Dim lPtr As Long
    
    Dim iLen%
    
    Dim sSaveIncomingCharacter$, sOut$
    
    'Debug.Print "RRTDRA received: >" + sString$ + "<"
    iLengthBeforeApostropheSubstitution% = Len(sString$)
    
    If Not gblaRomanizationTable(iRomanizationTable%).ApostropheCharactersPresent Then
        sOut$ = sString$
    Else
        sSaveIncomingCharacter$ = LocalCharacterObject.Utf8Char
        lPtr = 1
        Do While lPtr <= iLengthBeforeApostropheSubstitution%
            LocalCharacterObject.Utf8Char = Mid(sString$, lPtr)
            If InStr(gblaRomanizationTable(iRomanizationTable%).ApostropheCharacters, LocalCharacterObject.Utf8Char) > 0 Then
                sOut$ = sOut$ + "'"
            Else
                sOut$ = sOut$ + LocalCharacterObject.Utf8Char
            End If
            lPtr = lPtr + LocalCharacterObject.Utf8CharOctets
        Loop
        LocalCharacterObject.Utf8Char = sSaveIncomingCharacter$
    End If

    ReRomanizeTextDetailsReplaceApostrophes = sOut$

    'Debug.Print "RRTDRA output: >" + sOut$ + "<"
    
End Function

Public Function RomanizationAssistance(ByVal iAction As RomanizationAction, ByRef LocalRichTextBox As Control, ByVal iScript%, ByRef LocalMarcRecordObjectAlreadyLoadedWithRecord As Utf8MarcRecordClass, ByRef LocalMarcCharacterObject As Utf8CharClass, ByVal iFldTextFormattedOption%, Optional ByVal sFontNameForDisplay$ = TextFormattedDefaultFont$, Optional ByVal iFontSizeForDisplay% = 10, Optional ByVal iFixedFieldDisplayConvention% = 2) As Integer

    Dim sField$, sTag$, sTagToFind$, sIndicators$, s880Indicators$, sNative6$, s8806$, sLeftEnd$, sRecord$, sSubfield6Code$
    Dim sSelText$, sLeft$, sLeft2$, sRight$, sRight2$, sRightAfterSelection$, sWholeField$
    Dim sWord$, sNewField$, sOldField$, sFile$, sTempFile$, sLine$, sNewCharacter$
    Dim sFieldRemainderRight$, sFieldRemainderLeft$, s6$, sOriginalField$, sType$
    Dim sTagToCopy$, sIndicatorsToCopy$, sFieldToCopy$, sNewFields$, sOldFields$
    Dim sSubfieldsExcludedUniversally$, sSubfieldsExcludedByTag$, sOriginalLeft$, sOriginalRight$
    Dim sNonfilingString$, sIntermediate$
    Dim sRLM$, sLRE$, sPDF$
    Dim sRtfFontName$
    
    Dim iRc%, iRc2%, iRepeat%, iNext6%, iRomanizationStyle%, iDirection%, iIn%, iOut%, iElement%
    Dim iLen%
    
    Dim lPtr As Long, lPtr2 As Long, lSelLength As Long, lSelStart As Long, lStart As Long
    Dim lFldPointer As Long, lFldPointer2 As Long, lEnd As Long, lOriginalSelStart As Long
        
    Dim bFound As Boolean, bSkipTagTest As Boolean, bStringHasTerminalSpace As Boolean
    Dim bOnlyMarc8 As Boolean, bCreateEmpty880s As Boolean, bLcPattern As Boolean
    
    'Const sLineEnd = "\line"
    Const sLineEnd$ = "\par"
    Const iLineEndLen% = 5
    
    ' 20180926 Bucknum: check for and use custom language/script font for RTF display
    '   overrides the default Unicode font setting
    sRtfFontName$ = gblaRomanizationTable(iScript%).FontName
    If LenB(sRtfFontName$) = 0 Or Not IsFontInstalled(sRtfFontName$) Then
        sRtfFontName$ = sFontNameForDisplay$
    End If

    If gblaRomanizationTable(iScript%).R2VCreateEmpty880s Then
        ' 20070425: pick up a script identification code if it's been defined
        '   otherwise, we'll attempt to match it to the language code in 008/35-37
        '   we'll include this in $6 of "empty" 880 fields
        ' 20070830: LC addition: if there is no such code, pick up
        '   a transmogrification of the langauge code instead; area reorganized
        sSubfield6Code$ = gblaRomanizationTable(iScript%).R2VSubfield6Code
        If LenB(sSubfield6Code$) = 0 Then
            sSubfield6Code$ = Language2ScriptCode(LocalMarcRecordObjectAlreadyLoadedWithRecord.Get008Value(35, 3))
        End If
        If LenB(sSubfield6Code$) > 0 Then
            If sSubfield6Code$ = CHARACTERSET_CODES_FOR_880_HebrewAsG0$ Or _
               sSubfield6Code$ = CHARACTERSET_CODES_FOR_880_BasicArabicAsG0$ Then
                ' add R2L orientation code
                sSubfield6Code$ = sSubfield6Code$ & "/r"
            End If
            ' add "/" prefix
            sSubfield6Code$ = "/" + sSubfield6Code$
        End If
    End If

    If gblaRomanizationTable(iScript%).R2VIncludeFormattingCharactersLcPattern Or _
       InStr(sSubfield6Code$, "/r") > 0 Then
        ' set IncludeFormattingCharactersLcPattern = True to insert UFCs
        ' 20070830: Bucknum code forces value of this here; but we think
        '   this should come from the configuration file
        ' instead, we're going to set directly what DB was using this
        '   as a proxy for
        'gblaRomanizationTable(iScript%).R2VIncludeFormattingCharactersLcPattern = True
        bLcPattern = True
        ' 20070710: set a variable for the MarcRightToLeftMarker
        '   LC wants a RTL marker before and after each delimiter,
        '   EXCEPT immediately following the $6 code itself
        With LocalMarcRecordObjectAlreadyLoadedWithRecord
            sRLM$ = .MarcRightToLeftMarker
            sLRE$ = .MarcLeftToRightEmbedding
            sPDF$ = .MarcPopDirectionalFormatting
        End With
    Else
        ' set IncludeFormattingCharactersLcPattern = False to not insert UFCs
        ' 20070830: Bucknum code forces value of this here; but we think
        '   this should come from the configuration file
        ' instead, we're going to leave sRLM at its ground state of null,
        '   which seems to be the point of all of this, anyway
        'gblaRomanizationTable(iScript%).R2VIncludeFormattingCharactersLcPattern = False
        bLcPattern = False
    End If
    


    sType$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcRecordFormat
    
    ' assume everything will be OK
    RomanizationAssistance = ROMANIZATIONRESULT_Success%
    
    Select Case iAction

        Case ROMANIZATIONACTION_RomanizeHighlightedText%, ROMANIZATIONACTION_LCaseWord%, ROMANIZATIONACTION_UCaseWord%, ROMANIZATIONACTION_ReplaceText%, ROMANIZATIONACTION_UCaseEach%, ROMANIZATIONACTION_Define%
        
            ' 20070830: NoRomanization added
            If gblaRomanizationTable(iScript%).NoRomanization Then
                If iAction = ROMANIZATIONACTION_Define% Then
                    GoTo RomanizationAssistanceNoFileOpenResume
                End If
            End If
        
            ' these have similar complicated beginnings, so we'll do some code-sharing
            
            ' get the current state of the MARC record
            
            ' isolate the selected text, remove any carriage returns and line feeds
            sField$ = LocalRichTextBox.SelRTF


            ' for some reason, delimiters are getting converted to something we don't recognize ...
            sField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.ReplaceCharacters(sField$, "\'87", "\u8225?")
            ' 20180926 added by Bucknum: for some reason, the rich text box is inserting alternating font codes
            '   (e.g., "\f0") into the selected text, which is corrupting it, so we're going to strip them out
            If InStr(sField$, "\f0 ") Or InStr(sField$, "\f1 ") Then
                sField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.ReplaceCharacters(LocalMarcRecordObjectAlreadyLoadedWithRecord.ReplaceCharacters(sField$, "\f0 "), "\f1 ")
            ElseIf InStr(sField$, "\f0") Or InStr(sField$, "\f1") Then
                sField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.ReplaceCharacters(LocalMarcRecordObjectAlreadyLoadedWithRecord.ReplaceCharacters(sField$, "\f0"), "\f1")
            End If
            'Debug.Print "Initial extraction of field: >" + sField$ + "< len " + str(LocalRichTextBox.SelLength)
            If Len(sField$) = 0 Or LocalRichTextBox.SelLength = 0 Then
                'Debug.Print "Action: " + str(ROMANIZATIONACTION_RomanizeHighlightedText%)
                If iAction = ROMANIZATIONACTION_RomanizeHighlightedText% Then
                    ' 20070830: if we are clicked somewhere within a field and the selection length
                    '   is zero, we'll assume that what we really want to do is convert the
                    '   whole field
                    lPtr = FindFieldCurrentlyPointedTo(LocalRichTextBox, LocalMarcRecordObjectAlreadyLoadedWithRecord)
                    'Debug.Print "Ptr: " + str(lPtr)
                    ' 20100402 changed by Bucknum to allow for returned default of -1 (i.e. no text selected):
                    'If lPtr = 0 Then
                    If lPtr <= 0 Then
                        RomanizationAssistance = ROMANIZATIONRESULT_TextNotHighlighted%
                        Exit Function
                    End If
                Else
                    RomanizationAssistance = ROMANIZATIONRESULT_TextNotHighlighted%
                    Exit Function
                End If
                ' if we get here, we've found the field of interest
                LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer = lPtr
                sFieldRemainderLeft$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag + LocalMarcRecordObjectAlreadyLoadedWithRecord.FldInd
                sFieldRemainderRight$ = ""
                sWholeField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText
                ' 20100202 added by Bucknum: to enable
                '  non-empty field transliteration below
                sTag$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag
                sIndicators$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldInd
                sField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText
                GoTo RA_WeHaveOurFieldTheEasyWay
            End If
            
            ' if we ended up with carriage returns or line feeds, remove them (inserting no space)
            sField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.ReplaceCharacters(LocalMarcRecordObjectAlreadyLoadedWithRecord.ReplaceCharacters(sField$, vbCr, ""), vbLf, "")
            
            ' we'll use these two values in a bit, to find the field
            '   within the non-RTF version of the record
            ' NOTE that the TextRTF returns delimiters correctly (as opposed to SelRTF, as
            '   shown above) so we don't need to do any conversion here; in any case, this
            '   step appears to be irrelevant, because we replace this value of sRecord with
            '   a fresh copy of the TextFormatted(rtf) version of the record before we
            '   ever use sRecord for anything; go figure
            ' see note below about the contents of SelStart for rich text boxes
            lSelStart = LocalRichTextBox.SelStart
            lOriginalSelStart = lSelStart
            
RomanizationAssistanceReloop:
            
            sRecord$ = LocalRichTextBox.TextRTF
            
            ' remove the closing brace from the selected text
            If Right(sField$, 1) = "}" Then
                sField$ = Mid(sField$, 1, Len(sField$) - 1)
            End If
            ' remove the RTF prefix from the selected text
            iRc% = InStr(sField$, "}}")
            If iRc% > 0 Then
                sField$ = Trim(Mid(sField$, iRc% + 2))
            End If
            ' text should now start with some additional 'slash' commands, which
            '   we will proceed to remove
            Do While Mid(sField$, 1, 1) = "\"
                If Mid(sField$, 1, 2) = "\u" Then
                    If InStr("0123456789", Mid(sField$, 3, 1)) > 0 Then
                        Exit Do
                    End If
                End If
                sField$ = Mid(sField$, 2)
                iRc% = InStr(sField$, "\")
                If iRc% = 0 Then
                    iRc% = InStr(sField$, " ")
                    If iRc% > 0 Then
                        sField$ = Mid(sField$, iRc% + 1)
                        Exit Do
                    End If
                Else
                    iRc2% = InStr(sField$, " ")
                    If iRc2% > 0 Then
                        If iRc% < iRc2% Then
                            sField$ = Mid(sField$, iRc%)
                        Else
                            sField$ = Mid(sField$, iRc2% + 1)
                            Exit Do
                        End If
                    Else
                        sField$ = Mid(sField$, iRc%)
                    End If
                End If
            Loop
            ' remove any trailing 'par' command
            iRc% = LocalMarcRecordObjectAlreadyLoadedWithRecord.Rat(sField$, "\par")
            If iRc% > 0 Then
                sField$ = Mid(sField$, 1, iRc% - 1)
            End If
            If Len(sField$) = 0 Then
                RomanizationAssistance = ROMANIZATIONRESULT_HighlightedTextBecomesNothing%
                Exit Function
            End If
            ' wrapping spaces are irrelevant
            sField$ = Trim(sField$)

            ' we should now have the raw text of interest, isolated in sField$
            
            ' oddly enough, the SelStart property of the rich text box
            '   refers to the plain text version
            '   of the field; there doesn't seem to be a corresponding SelStartRtf
            '   or anything else useful; so we're going to use the supplied SelStart
            '   property as a rough guide for finding the selection ourselves
            ' remembering that SelStart is zero-based (so we don't have to back up 1
            '   from lSelStart to find the "real" end of the preceding text, and we
            '   have to add 1 to the combined start and length to find the beginning
            '   of whatever follows the text (which is, from our point of view, possibly
            '   irrelevant)
            sFieldRemainderLeft$ = Mid(LocalRichTextBox.Text, 1, lSelStart)
            lPtr = LocalMarcRecordObjectAlreadyLoadedWithRecord.Rat(sFieldRemainderLeft$, vbLf)

            If lPtr > 0 Then
                sFieldRemainderLeft$ = Trim(Mid(sFieldRemainderLeft$, lPtr + 1) + sField$)
                sTagToFind$ = Mid(sFieldRemainderLeft$, 1, 3)
            Else
                RomanizationAssistance = ROMANIZATIONRESULT_TextNotFindable%
                Exit Function
            End If
            
            Select Case LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcRecordFormat
                Case "A"
                    sNonfilingString$ = sAuthorityNonfilingString$
                Case "B", "D", "F", "M", "P", "S", "U"
                    sNonfilingString$ = sBibliographicNonfilingString$
                'Case else: ignore the whole issue
            End Select
            
            ' to help us find the highlighted text within the record,
            '   give us the RTF version of the whole MARC record again
            ' we don't need to worry here about specification for fixed fields or
            '   font size, because they don't affect what we're up to here
            sRecord$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.TextFormatted(rtfText)

            lStart = 1
            Do
                ' find the next occurrence of our text in the record
                lSelStart = InStr(lStart, sRecord$, sField$)
                DoEvents

                If lSelStart = 0 Then
                    If lStart = 1 Then
                        RomanizationAssistance = ROMANIZATIONRESULT_TextNotFindable%
                        Exit Function
                    End If
                    ' we found at least one place already; so let's back up to find
                    '   the first one (assuming that the first one is the right one!)
                    lSelStart = InStr(1, sRecord$, sField$)
                    If lSelStart = 0 Then
                        RomanizationAssistance = ROMANIZATIONRESULT_TextNotFindable%
                        Exit Function
                    End If
                    bSkipTagTest = True
                Else
                    lStart = lSelStart + 1
                End If
                sLeft$ = Mid(sRecord$, 1, lSelStart - 1)
                sRight$ = Mid(sRecord$, lSelStart + Len(sField$))

                ' sLeft$ = all of the record up to our selected text
                ' sRight$ = and all of the record that follows the selected text
                ' we want to back up in sLeft to the beginning of the current "line" (i.e., variable field)
                lSelStart = LocalMarcRecordObjectAlreadyLoadedWithRecord.Rat(sLeft$, sLineEnd$)
                If lSelStart > 0 Then
                    sFieldRemainderLeft$ = LTrim(Mid(sLeft$, lSelStart + 5))
                    If Mid(sFieldRemainderLeft$, 1, 2) = "\f" Then
                        sLeft$ = sLeft$ + Mid(sFieldRemainderLeft$, 1, 4)
                        sFieldRemainderLeft$ = Mid(sFieldRemainderLeft$, 5)
                    End If
                Else
                    sFieldRemainderLeft$ = ""
                End If

                If Mid(LTrim(sFieldRemainderLeft$ + sField$), 1, 3) = sTagToFind$ Or bSkipTagTest Then
                    ' we want to include from sRight any remainder of the current line (i.e., the
                    '   remainder of our variable field)
                    lSelStart = InStr(sRight$, sLineEnd$)
                    If lSelStart > 1 Then
                        sFieldRemainderRight$ = Mid(sRight$, 1, lSelStart - 1)
                    Else
                        sFieldRemainderRight$ = ""
                    End If
                    sFieldRemainderLeft$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.TranslateRTF2Marc(sFieldRemainderLeft$)
                    sField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.RemoveSpacesAroundDelimiters(LocalMarcRecordObjectAlreadyLoadedWithRecord.TranslateRTF2Marc(sField$))
                    sFieldRemainderRight$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.TranslateRTF2Marc(sFieldRemainderRight$)
                    sWholeField$ = Trim(sFieldRemainderLeft$ + sField$ + sFieldRemainderRight$)
                    Exit Do
                End If
            Loop

            'Debug.Print "Easy way"


            Select Case iAction
            
                Case ROMANIZATIONACTION_RomanizeHighlightedText%
                    sTag$ = Mid(sWholeField$, 1, 3) ' the tag of the current field
                    sIndicators$ = Mid(sWholeField$, 5, 2)
                    sWholeField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.RemoveSpacesAroundDelimiters(Trim(Mid(sWholeField$, 8)))
                    If Mid(sWholeField$, 1, 2) = "\f" Then
                        sWholeField$ = Mid(sWholeField$, 4)
                    End If
RA_WeHaveOurFieldTheEasyWay:
                    'Debug.Print "Pieces: >" + sTag$ + "< >" + sIndicators$ + "< >" + sWholeField$ + "<"
    
                    ' change 880 $6 6xx-xx 2nd indicator to "4" (source not specified)
                    If sTag$ >= 600 And sTag$ <= 651 Then
                        s880Indicators$ = Mid$(sIndicators$, 1, 1) & "4"
                    Else
                        s880Indicators$ = sIndicators$
                    End If
                    
                    iRc% = InStr(sWholeField$, LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6")
                    If iRc% > 0 Then
                        ' 20070830: NoRomanization added
                        If gblaRomanizationTable(iScript%).NoRomanization Then
                            ' if we we're not actually converting text then there's nothing for us to do
                            '   if $6 is present
                            GoTo RomanizationAssistanceNoFileOpenResume
                        End If
                        s6$ = Mid(sWholeField$, iRc% + 2)
                        iRc% = InStr(s6$, LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter)
                        If iRc% > 0 Then
                            s6$ = Mid(s6$, 1, iRc% - 1)
                        End If
                    Else
                        ' field does not yet contain $6
                        ' calculate the next value for sequence of subfield $6
                        LocalMarcRecordObjectAlreadyLoadedWithRecord.FldMoveTop
                        Do While LocalMarcRecordObjectAlreadyLoadedWithRecord.FldMoveNext
                            If LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdFindFirst("6") Then
                                iRc% = InStr(LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText, "-")
                                If iRc% > 0 Then
                                    iRepeat% = Val(Trim(Mid(LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText, iRc% + 1)))
                                    If iRepeat% > iNext6% Then
                                        iNext6% = iRepeat%
                                    End If
                                End If
                            End If
                        Loop
                        iNext6% = iNext6% + 1
                        ' 20070830: NoRomanization added
                        If gblaRomanizationTable(iScript%).NoRomanization Then
                            ' if we're not actually converting text, then (until we hear more
                            '   from David B. at LC) we're going to add $6 to the current field and
                            '   copy the current field to 880
                            ' we can do this much, now that we've got the next repeat number
                            '   calculated
                            bFound = False
                            LocalMarcRecordObjectAlreadyLoadedWithRecord.FldMoveTop
                            Do While LocalMarcRecordObjectAlreadyLoadedWithRecord.FldFindNext(sTag$)
                                If LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText = sWholeField$ Then
                                    lFldPointer = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer
                                    bFound = True
                                End If
                            Loop
                            If Not bFound Then
                                RomanizationAssistance = ROMANIZATIONRESULT_FieldNotFound%
                                Exit Function
                            End If
                            LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer = lFldPointer
                            sTag$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag
                            sIndicators$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldInd
                            ' change 880 $6 6xx-xx 2nd indicator to "4" (source not specified)
                            If sTag$ >= 600 And sTag$ <= 651 Then
                                s880Indicators$ = Mid$(sIndicators$, 1, 1) & "4"
                            Else
                                s880Indicators$ = sIndicators$
                            End If
                            sField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText
                            LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdMoveFirst
                            
                            bOnlyMarc8 = LocalMarcRecordObjectAlreadyLoadedWithRecord.Utf8TextContainsOnlyMarc8Characters(sField$)
                            'Debug.Print "Only marc 8? " + str(bOnlyMarc8)
                            ' 20100412 changed by David Bucknum: since we're romanizing the field above
                            ' original version:
                            'LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdAdd "6", "880-" + Right("00" + Trim(str(iNext6%)), 2)
                            ' replacement:
                            With LocalMarcRecordObjectAlreadyLoadedWithRecord
                                .FldDelete
                                .FldAdd .FldTag, .FldInd, .MarcDelimiter + "6" + "880-" + Right("00" + Trim(str(iNext6%)), 2) + sField$
                            End With
                            ' adding subfield $6 has the effect of deleting the original field and replacing
                            '   it with a new one; so we need to reset the pointer too
                            lFldPointer = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer
                            ' 20100412 changed by David Bucknum: since we're romanizing the field above
                            ' original version:
                            'LocalMarcRecordObjectAlreadyLoadedWithRecord.FldAdd "880", s880Indicators$, sField$
                            'LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdAdd "6", sTag$ + "-" + Right("00" + Trim(str(iNext6%)), 2)
                            ' replacement:
                            With LocalMarcRecordObjectAlreadyLoadedWithRecord
                                .FldAdd .FldTag, .FldInd, .MarcDelimiter + "6" + sTag$ + "-" + Right("00" + Trim(str(iNext6%)), 2) + sField$
                            End With
                            lFldPointer2 = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer
                            ' now, the matrix of options
                            If bOnlyMarc8 Then
                                ' the field we copied into the 880 contains only MARC-8 characters; so
                                '   we assume that this is romanized text for which we need to
                                '   supply the vernacular form
                                'Debug.Print "Create empty 1? " + str(gblaRomanizationTable(iScript%).R2VCreateEmpty880s)
                                If gblaRomanizationTable(iScript%).R2VCreateEmpty880s Then
                                    LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer = lFldPointer2
                                    LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdMoveFirst
                                    Do While True
                                        If InStr("68", LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdCode) = 0 Then
                                        ' include this subfield, but change it to a plus sign
                                            ' 20070831: in the new "empty" 880 field:
                                            '   add RLMs before and after the delimiter/subfield codes,
                                            '   as appropriate, but *only* if the Right2LeftMark variable is set
                                            If bLcPattern Then
                                                ' 20070831: add a LeftToRightEmbedding character (LRE) only before
                                                '   and add a POPDirectionalFormatting character (PDF) only
                                                '   at the end of the 880 $6 260-xx $c [dates]
                                                ' 20121121: added 264 (RDA) to logic
                                                If sTag$ Like "26[04]" And LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdCode = "c" Then
                                                    ' if the 260 ends with a period, place the period after the PDF
                                                    If Right(LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText, 1) = "." Then
                                                        LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText = sRLM$ + sLRE$ + "+" + sPDF$ + "."
                                                    Else
                                                        LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText = sRLM$ + sLRE$ + "+" + sPDF$
                                                    End If
                                                Else
                                                    LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText = sRLM$ + "+" + sRLM$
                                                End If
                                            Else
                                                LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText = "+"
                                            End If
                                        Else
                                            ' 20070831: add an RLM at the end of $6 as appropriate
                                            If bLcPattern Then
                                                LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText = LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText + sSubfield6Code$ + sRLM$
                                            Else
                                                LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText = LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText + sSubfield6Code$
                                            End If
                                        End If
                                        If Not LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdMoveNext Then
                                            ' 20070831: remove the final RLM at the end of the field
                                            If bLcPattern And Right(LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText, 3) = sRLM$ Then
                                                LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText = Left(LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText, Len(LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText) - 3)
                                            End If
                                            Exit Do
                                        End If
                                    Loop
                                End If
                            Else
                                ' the field we copied into the 880 contains non-MARC-8 characters; so
                                '   we assume that this is vernacular text and the original field
                                '   needs to be romanized
                                'Debug.Print "Create empty 2? " + str(gblaRomanizationTable(iScript%).V2RCreateEmptyFields)
                                If gblaRomanizationTable(iScript%).V2RCreateEmptyFields Then
                                    LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer = lFldPointer
                                    LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdMoveFirst
                                    sField$ = ""
                                    Do While True
                                        If InStr("68", LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdCode) = 0 Then
                                            ' include this subfield, but change it to a plus sign
                                            sField$ = sField$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdCode + "+"
                                        Else
                                            sField$ = sField$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdCode + LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText
                                        End If
                                        If Not LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdMoveNext Then
                                            Exit Do
                                        End If
                                    Loop
                                    LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText = sField$
                                End If
                            End If
'                            LocalMarcRecordObjectAlreadyLoadedWithRecord.DumpArray "100 880", True
                            GoTo RomanAssist_DisplayTheFinishedRecord
                        End If
                    End If
                    

                    iRomanizationStyle% = EvaluateFirstCharacter(sField$, iScript%, LocalMarcCharacterObject)

                    If iRomanizationStyle% = ROMANIZATIONDIRECTION_Unknown% Then

                        RomanizationAssistance = ROMANIZATIONRESULT_ActionUnclear%
                        Exit Function
                    End If
                    

                    ' at this point we need to make the critical determination: are we converting
                    '   romanized text into vernacular, or are we converting vernacular text into romanized?
                    ' here go the scenarios we've developed, based on a
                    '   matrix of these factors:
                    '   1) whether the field is 880, or something else
                    '   2) whether the field already contains subfield $6
                    '   3) whether the highlighted text is vernacular or romanized
                    If sTag$ <> "880" Then
                        If Len(s6$) = 0 Then
                            ' we need lFldPointer regardless of what happens
                            '   to remaining scenarios here
                            bFound = False
                            LocalMarcRecordObjectAlreadyLoadedWithRecord.FldMoveTop
                            Do While LocalMarcRecordObjectAlreadyLoadedWithRecord.FldFindNext(sTag$)
                                'Debug.Print "Comparing: >" + LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText + "< >" + sWholeField$ + "<"
                                If LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText = sWholeField$ Then
                                    lFldPointer = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer
                                    bFound = True
                                End If
                            Loop
                            If Not bFound Then
                                RomanizationAssistance = ROMANIZATIONRESULT_FieldNotFound%
                                Exit Function
                            End If
                            If iRomanizationStyle% = ROMANIZATIONDIRECTION_Vernacular2Roman% Then
                                ' not an 880 field; no $6 yet; we're moving from vernacular to romanized
                                ' copy the current field as 880 (which adds $6 to the
                                '   original field and also the new 880 field); otherwise
                                '   leave the 880 field alone
                                iRc% = InStr(sWholeField$, sField$)
                                If iRc% > 0 Then ' it sure better be!
RomanAssist_ReplayWithSubstitution:
                                    ' find the original field (again!) and get a copy of it
                                    LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer = lFldPointer
                                    LocalMarcRecordObjectAlreadyLoadedWithRecord.FldLoadInfo sTagToCopy$, sIndicatorsToCopy$, sFieldToCopy$
                                    lFldPointer2 = lFldPointer
                                    ' copy the field as it stands to an 880, with $6 added
                                    LocalMarcRecordObjectAlreadyLoadedWithRecord.FldAdd "880", sIndicatorsToCopy$, LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6" + sTagToCopy$ + "-" + Right("00" + Trim(str(iNext6%)), 2) + sSubfield6Code$ + sFieldToCopy$
                                    ' save the pointer to the new 880 field for later use in resolving
                                    '   the nonfiling characters indicator
                                    lFldPointer = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer
                                    
                                    ' isolate the bits that we're NOT going to romanize
                                    sLeft$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6880-" + Right("00" + Trim(str(iNext6%)), 2) + Mid(sWholeField$, 1, iRc% - 1)

                                    If Right(sLeft$, 1) = LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter Then
                                        sLeft$ = Mid(sLeft$, 1, Len(sLeft$) - 1)
                                        sIntermediate$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter
                                    ElseIf Mid(Right(sLeft$, 2), 1, 1) = LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter Then
                                        sIntermediate$ = Right(sLeft$, 2)
                                        sLeft$ = Mid(sLeft$, 1, Len(sLeft$) - 2)
                                    End If

                                    sRight$ = Mid(sWholeField$, iRc% + Len(sField$))
                                    sField$ = sIntermediate$ + sField$

                                    ' change the text of the native field to match
                                    LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer = lFldPointer2
                                    If Right(sField$, 1) = " " Then
                                        bStringHasTerminalSpace = True
                                    Else
                                        bStringHasTerminalSpace = False
                                    End If
                                    ' 20070731: make sure first word is uppercased
                                    sField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.UCaseFirstWord(ReRomanizeText(sType$, LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag, sField$, iScript%, LocalMarcRecordObjectAlreadyLoadedWithRecord, LocalMarcCharacterObject))
                                    If Not bStringHasTerminalSpace Then
                                        sField$ = RTrim(sField$)
                                    End If
                                    LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText = sLeft$ + sField$ + sRight$
                                    ' just in case we've done a delete/re-add
                                    lFldPointer2 = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer
                                    
                                    ' adjust nonfiling characters as necessary
#If RomanizationAssistanceDebug = -1 Then
                                    Debug.Print "Adjust NON #1"
#End If
                                    ReRomanizeAdjustNonfilingIndicators iScript%, sNonfilingString$, lFldPointer, lFldPointer2, LocalMarcRecordObjectAlreadyLoadedWithRecord, LocalMarcCharacterObject
                                    
                                    GoTo RomanAssist_DisplayTheFinishedRecord
                                    
                                Else
                                    iRc% = InStr(sField$, sWholeField$)
                                    If iRc% > 0 Then
                                        sField$ = sWholeField$
                                        iRc% = InStr(sWholeField$, sField$)
                                        If iRc% > 0 Then
                                            GoTo RomanAssist_ReplayWithSubstitution
                                        End If
                                    End If
                                    ' todo: if we get here, nothing is going to happen; tell the operator?
                                End If
                            Else ' not an 880 field; no $6 yet; we're moving from romanized to vernacular
                                ' find the field in the bib record
                                ' INCLUDES Wade-Giles to Pinyin
                                iRc% = InStr(sWholeField$, sField$)

                                If iRc% > 0 Then ' it sure better be!
RomanAssist_ReplayWithSubstitution2:
                                    ' isolate the bits that we're NOT going to romanize
                                    sRight$ = Mid(sWholeField$, iRc% + Len(sField$))
                                    LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer = lFldPointer

                                    sTagToCopy$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag
                                    If gblaRomanizationTable(iScript%).DoNotUse880Field Then
                                        ' probably wade-giles to pinyin
                                        sLeft$ = Mid(sWholeField$, 1, iRc% - 1)
                                        LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText = sLeft$ + ReRomanizeText(sType$, LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag, sField$, iScript%, LocalMarcRecordObjectAlreadyLoadedWithRecord, LocalMarcCharacterObject) + sRight$
                                    Else
                                        sLeft$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6" + sTag$ + "-" + Right("00" + Trim(str(iNext6%)), 2) + sSubfield6Code$ + Mid(sWholeField$, 1, iRc% - 1)
                                        ' add subfield $6 to the original field (to make things easier, we'll
                                        '   actually achieve this with a delete/insert operation)
                                        'Debug.Print "Text before delete: " + LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText
                                        LocalMarcRecordObjectAlreadyLoadedWithRecord.FldDelete
                                        ' 20070703: in the original version (retained here as a comment), we use the text of the new field
                                        '   as run through the ReRomanize function. the reason for this is not clear, and
                                        '   at least in the Hebrew stuff we're testing with just now this results in
                                        '   a field with uppercase letters rendered as lowercase
                                        ' the obvious solution appears to be to use the original field text in the
                                        '   new field, without any changes
                                        ' perhaps only time will reveal the need that led to our use of ReRomanize
                                        '   here in the first place ...
                                        ' original version:
                                        'LocalMarcRecordObjectAlreadyLoadedWithRecord.FldInsertAfter sTagToCopy$, sIndicators$, LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6" + "880-" + Right("00" + Trim(str(iNext6%)), 2) + ReRomanizeText(sType$, LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag, LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText, iScript%, LocalMarcRecordObjectAlreadyLoadedWithRecord, LocalMarcCharacterObject, 2)
                                        ' replacement:
                                        ' 20100809 Bucknum added: remove temporary VowelMarker character before export
                                        If LenB(gblaRomanizationTable(iScript%).R2VVowelMarker) > 0 Then
                                            LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText = LocalMarcRecordObjectAlreadyLoadedWithRecord.ReplaceCharacters(LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText, gblaRomanizationTable(iScript%).R2VVowelMarker)
                                        End If
                                        LocalMarcRecordObjectAlreadyLoadedWithRecord.FldInsertAfter sTagToCopy$, sIndicators$, LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6" + "880-" + Right("00" + Trim(str(iNext6%)), 2) + LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText
                                        ' pointer to the "changed" field
                                        lFldPointer = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer
                                        ' 20070719: convert the text for the 880 here, instead of below
                                        sField$ = ReRomanizeText(sType$, sTagToCopy$, sField$, iScript%, LocalMarcRecordObjectAlreadyLoadedWithRecord, LocalMarcCharacterObject)
                                        ' add right-to-left marker to the end of subfield $6 as appropriate
                                        If bLcPattern Then
                                            lPtr = InStr(sLeft$, LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6")
                                            If lPtr > 0 Then
                                                sLeft$ = sLeft$ & LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcRightToLeftMarker
                                            End If
                                            ' add LRE and PDF markers to the 880 $6 260-xx $c [dates]
                                            '   after the $c RLM and at the end of the subfield
                                            ' 20121121: added 264 (RDA) to logic
                                            lPtr2 = InStr(sField$, LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "c")
                                            If lPtr2 <> 0 And sTagToCopy$ Like "26[04]" Then
                                                sField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.SafeStuff(sField$, lPtr2 + 5, 0, LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcLeftToRightEmbedding)
                                                ' if the subfield ends with a period, place the period after the PDF
                                                If Right(sField$, 1) = "." Then
                                                    sField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.SafeStuff(sField$, InStrRev(sField$, "."), 1, LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcPopDirectionalFormatting + ".")
                                                Else
                                                    sField$ = sField$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcPopDirectionalFormatting
                                                End If
                                            End If
                                        End If
                                        ' create an 880 field with text converted
                                        

                                        ' 20070719 changed by David Bucknum: since we're romanizing the field above
                                        ' original version:
                                        'LocalMarcRecordObjectAlreadyLoadedWithRecord.FldInsertAfter "880", s880Indicators$, sLeft$ + ReRomanizeText(sType$, sTagToCopy$, sField$, iScript%, LocalMarcRecordObjectAlreadyLoadedWithRecord, LocalMarcCharacterObject) + sRight$
                                        ' replacement:
                                        LocalMarcRecordObjectAlreadyLoadedWithRecord.FldInsertAfter "880", s880Indicators$, sLeft$ + sField$ + sRight$
                                        ' this is, for our purposes, the "original" field
                                        lFldPointer2 = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer

                                        'LocalMarcRecordObjectAlreadyLoadedWithRecord.DumpArray "", False
#If RomanizationAssistanceDebug = -1 Then
                                        Debug.Print "Adjust NON #2"
#End If
                                        ReRomanizeAdjustNonfilingIndicators iScript%, sNonfilingString$, lFldPointer, lFldPointer2, LocalMarcRecordObjectAlreadyLoadedWithRecord, LocalMarcCharacterObject
                                        ' does this achieve anything at all?
                                        LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer = lFldPointer

                                    End If
                                    GoTo RomanAssist_DisplayTheFinishedRecord
                                Else
                                    iRc% = InStr(sField$, sWholeField$)
                                    If iRc% > 0 Then
                                        sField$ = sWholeField$
                                        iRc% = InStr(sWholeField$, sField$)
                                        If iRc% > 0 Then
                                            GoTo RomanAssist_ReplayWithSubstitution2
                                        End If
                                    End If
                                    ' todo: if we get here, nothing is going to happen; tell the operator?
                                End If
                            End If
                        Else ' tag not 880, subfield $6 is present

                            If iRomanizationStyle% = ROMANIZATIONDIRECTION_Vernacular2Roman% Then
                                ' not an 880 field; already contains $6; moving from vernacular to roman
                                ' todo: romanize the text in place, leaving the 880 field alone
                                ' NOTE that if field already contains $6, we're not going to
                                '   do anything about initial articles
RomanAssist_ReRomanizeInPlace:
                                bFound = False
                                sTag$ = Mid(sFieldRemainderLeft$, 1, 3)
                                LocalMarcRecordObjectAlreadyLoadedWithRecord.FldMoveTop
                                Do While LocalMarcRecordObjectAlreadyLoadedWithRecord.FldFindNext(sTag$)
                                    If LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText = sWholeField$ Then
                                        lFldPointer = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer
                                        bFound = True
                                    End If
                                Loop
                                If Not bFound Then
                                    RomanizationAssistance = ROMANIZATIONRESULT_FieldNotFound%
                                    Exit Function
                                Else
                                    LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer = lFldPointer
                                    If Len(sFieldRemainderLeft$) > 0 Then
                                        lFldPointer = InStr(sFieldRemainderLeft$, LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter)
                                        If lFldPointer > 0 Then
                                            sFieldRemainderLeft$ = Mid(sFieldRemainderLeft$, lFldPointer)
                                        End If
                                    End If
                                    LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText = sFieldRemainderLeft$ + ReRomanizeText(sType$, LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag, sField$, iScript%, LocalMarcRecordObjectAlreadyLoadedWithRecord, LocalMarcCharacterObject) + sFieldRemainderRight$
                                    GoTo RomanAssist_DisplayTheFinishedRecord
                                End If
                            Else
                                ' not an 880 field; already contains $6; we're moving from romanized to vernacular
                                ' todo: find the parallel text in the 880 field, and vernacularize the
                                '   parallel text in the 880 field; leave the user-marked field alone
                            End If
                        End If
                    Else
                        ' the operator selected text within an 880 field
                        If Len(s6$) = 0 Then
                            RomanizationAssistance = ROMANIZATIONRESULT_880WithNoSubfield6%
                            Exit Function
                        Else
                            ' 880 field; field already contains $6
                            GoTo RomanAssist_ReRomanizeInPlace
                        End If
                    End If
        
                Case ROMANIZATIONACTION_LCaseWord%, ROMANIZATIONACTION_UCaseWord%, ROMANIZATIONACTION_ReplaceText%, ROMANIZATIONACTION_UCaseEach%, ROMANIZATIONACTION_Define%

                    sTag$ = Mid(sWholeField$, 1, 3) ' the tag of the current field
                    sIndicators$ = Mid(sWholeField$, 5, 2)
                    sWholeField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.RemoveSpacesAroundDelimiters(Trim(Mid(sWholeField$, 8)))
                    If Mid(sWholeField$, 1, 2) = "\f" Then
                        sWholeField$ = Mid(sWholeField$, 4)
                    End If
        
                    LocalMarcRecordObjectAlreadyLoadedWithRecord.FldMoveTop
                    Do While LocalMarcRecordObjectAlreadyLoadedWithRecord.FldFindNext(sTag$)
                        If LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText = sWholeField$ Then
                            lFldPointer = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer
                            bFound = True
                        End If
                    Loop
                    If Not bFound Then
                        RomanizationAssistance = ROMANIZATIONRESULT_FieldNotFound%
                        Exit Function
                    End If
                
                    iRc% = InStr(sWholeField$, sField$)
                    If iRc% > 0 Then ' it sure better be!
                    
                        iRc% = InStr(sWholeField$, sField$)
                        If iRc% > 0 Then ' it sure better be!
                            ' find the original field (again!) and get a copy of it
                            LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer = lFldPointer
                            LocalMarcRecordObjectAlreadyLoadedWithRecord.FldLoadInfo sTagToCopy$, sIndicatorsToCopy$, sFieldToCopy$
                            ' isolate the bits that we're NOT going to romanize
                            sLeft$ = Mid(sWholeField$, 1, iRc% - 1)


                            If Right(sLeft$, 1) = LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter Then
                                sLeft$ = Mid(sLeft$, 1, Len(sLeft$) - 1)
                                sIntermediate$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter
                            ElseIf Mid(Right(sLeft$, 2), 1, 1) = LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter Then
                                sIntermediate$ = Right(sLeft$, 2)
                                sLeft$ = Mid(sLeft$, 1, Len(sLeft$) - 2)
                            End If

                            sRight$ = Mid(sWholeField$, iRc% + Len(sField$))
                            sField$ = sIntermediate$ + sField$

                            sOriginalField$ = sField$
                    
                            Select Case iAction
                                Case ROMANIZATIONACTION_LCaseWord%
                                    LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText = sLeft$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.LCaseFirstWord(sField$) + sRight$
                                Case ROMANIZATIONACTION_UCaseWord%
                                    LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText = sLeft$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.UCaseFirstWord(sField$) + sRight$
                                Case ROMANIZATIONACTION_ReplaceText%, ROMANIZATIONACTION_Define%
                                    sNewField$ = ""
                                    sOriginalLeft$ = sLeft$
                                    sOriginalRight$ = sRight$
                                    
                                    Do While Len(sField$) > 0
                                        If Asc(Mid(sField$, 1, 1)) > 127 Then
                                            LocalMarcCharacterObject.Utf8Char = sField$
                                            sField$ = Mid(sField$, LocalMarcCharacterObject.Utf8CharOctets + 1)
                                            sNewField$ = sNewField$ + "{U+" + LocalMarcCharacterObject.UcsHex + "}"
                                        Else
                                            sNewField$ = sNewField$ + Mid(sField$, 1, 1)
                                            sField$ = Mid(sField$, 2)
                                        End If
                                    Loop
                                    If iAction = ROMANIZATIONACTION_Define% Then
                                        sFile$ = gblaRomanizationTable(iScript%).FullFileName
                                        sTempFile$ = sFile$
                                        iRc2% = LocalMarcRecordObjectAlreadyLoadedWithRecord.Rat(sTempFile$, "\")
                                        If iRc2% = 0 Then
                                            Exit Function
                                        End If
                                        sTempFile$ = Mid(sTempFile$, 1, iRc2%) + "Temp.$$$"
                                        On Error GoTo RomanizationAssistanceNoFileOpen
                                        iOut% = FreeFile
                                        Open sTempFile$ For Output As #iOut%
                                        On Error GoTo 0
                                        iIn% = FreeFile
                                        Open sFile$ For Input As #iIn%
                                        
                                        iRc% = InStr(sNewField$, "{U+")
                                        If iRc% = 0 Then
                                            RomanizationAssistance = ROMANIZATIONRESULT_NoCharacterToDefine%
                                            Exit Function
                                        End If
                                        ' iRc% points to the character in question
                                        ' PRESERVE THE VALUE OF iRC!
                                        sField$ = InputBox("Please supply the replacement text for U+" + Mid(sNewField$, iRc% + 3, 4) + ".  (Supply empty text to cancel.)", "Define replacement for vernacular character", "")
                                        If Len(sField$) = 0 Then
                                            Close #iIn%
                                            Close #iOut%
                                            Exit Function ' operation canceled
                                        End If
                                        ' iRc% still points to the character in question
                                        ' PRESERVE THE VALUE OF iRC!
                                        If sField$ = Mid(sNewField$, iRc% + 3, 4) Then
                                            Close #iIn%
                                            Close #iOut%
                                            Exit Function ' operator didn't make a change: nothing to do
                                        End If
                                        ' iRc% still points to the character in question
                                        ' PRESERVE THE VALUE OF iRC!
                                        ' todo: if we need to allow for the possibility of Unicode
                                        '   notations within the replacement text, handle them here
                                        '   (not needed for Chinese, which is the object of this
                                        '   exercise)
                                        ' add a new line to the configuration file,
                                        '   defining this new character (we opened the files
                                        '   above, so we could make sure we're allowed to do this
                                        '   before we actually go to work)
                                        '
                                        ' 20070606 added by David Bucknum
                                        sField$ = Trim(sField$) & " "
                                        Do While Not EOF(iIn%)
                                            DoEvents
                                            Line Input #iIn%, sLine$
                                            Print #iOut%, sLine$
                                            ' 20070727 (comment only; no change) this puts the new
                                            '   character at the top of the stanza, whether we want
                                            '   it there or somewhere else; this is "probably" good
                                            '   enough, given the context ...
                                            If sLine$ = "[ScriptToRoman]" Then
                                                Print #iOut%, "U+" + Mid(sNewField$, iRc% + 3, 4) + "=" + LocalMarcRecordObjectAlreadyLoadedWithRecord.ReplaceCharacters(sField$, " ", "_")
                                            End If
                                        Loop
                                        Close #iIn%
                                        Close #iOut%
                                        On Error GoTo RomanizationAssistanceBadKill
                                        Kill sFile$
                                        DoEvents
                                        FileCopy sTempFile$, sFile$
                                        DoEvents
                                        Kill sTempFile$
                                        ' add the character to the current version of the
                                        '   romanization tables in memory
                                        'sField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.ReplaceCharacters(sField$, "_", " ")
                                        ' this is the "native" representation of the whole raw string (which should
                                        '   just be one character)
                                        'Debug.Print "RA 1"
                                        sNewCharacter$ = RomanizeConvertText("U+" + Mid(sNewField$, iRc% + 3, 4), LocalMarcRecordObjectAlreadyLoadedWithRecord, LocalMarcCharacterObject)
                                        LocalMarcCharacterObject.UcsHex = Mid(sNewField$, iRc% + 3, 4) ' isolating the first character (there should only be the one)
                                        If gblaRomanizationTable(iScript%).Vernacular2Roman.Exists(LocalMarcCharacterObject.Utf8Char) Then
                                            iElement% = gblaRomanizationTable(iScript%).Vernacular2Roman.item(LocalMarcCharacterObject.Utf8Char)
                                        Else
                                            gblaRomanizationTable(iScript%).VernacularLast = gblaRomanizationTable(iScript%).VernacularLast + 1
                                            If gblaRomanizationTable(iScript%).VernacularLast > gblaRomanizationTable(iScript%).VernacularMax Then
                                                gblaRomanizationTable(iScript%).VernacularMax = gblaRomanizationTable(iScript%).VernacularMax + 10
                                                ReDim Preserve gblaRomanizationTable(iScript%).Vernacular(0 To gblaRomanizationTable(iScript%).VernacularMax)
                                            End If
                                            iElement% = gblaRomanizationTable(iScript%).VernacularLast
                                            gblaRomanizationTable(iScript%).Vernacular2Roman.Add LocalMarcCharacterObject.Utf8Char, iElement%
                                        End If
                                        gblaRomanizationTable(iScript%).Vernacular(iElement%).DetailLast = gblaRomanizationTable(iScript%).Vernacular(iElement%).DetailLast + 1
                                        If gblaRomanizationTable(iScript%).Vernacular(iElement%).DetailLast > gblaRomanizationTable(iScript%).Vernacular(iElement%).DetailMax Then
                                            gblaRomanizationTable(iScript%).Vernacular(iElement%).DetailMax = gblaRomanizationTable(iScript%).Vernacular(iElement%).DetailMax + 5
                                            ReDim Preserve gblaRomanizationTable(iScript%).Vernacular(iElement%).Detail(0 To gblaRomanizationTable(iScript%).Vernacular(iElement%).DetailMax)
                                        End If
                                        sField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.ReplaceCharacters(sField$, "_", " ")
                                        gblaRomanizationTable(iScript%).Vernacular(iElement%).Detail(gblaRomanizationTable(iScript%).Vernacular(iElement%).DetailLast).FullStringLengthInCharacters = LocalMarcRecordObjectAlreadyLoadedWithRecord.SafeLen(sNewCharacter$)
                                        gblaRomanizationTable(iScript%).Vernacular(iElement%).Detail(gblaRomanizationTable(iScript%).Vernacular(iElement%).DetailLast).FullStringLengthInBytes = Len(sNewCharacter$)
                                        gblaRomanizationTable(iScript%).Vernacular(iElement%).Detail(gblaRomanizationTable(iScript%).Vernacular(iElement%).DetailLast).FullString = sNewCharacter$
                                        gblaRomanizationTable(iScript%).Vernacular(iElement%).Detail(gblaRomanizationTable(iScript%).Vernacular(iElement%).DetailLast).Equivalent = sField$
                                        gblaRomanizationTable(iScript%).Vernacular(iElement%).Detail(gblaRomanizationTable(iScript%).Vernacular(iElement%).DetailLast).EquivalentUpperCasePresent = False
                                        'Debug.Print "Defined equivalent >" + gblaRomanizationTable(iScript%).Vernacular(iElement%).Detail(gblaRomanizationTable(iScript%).Vernacular(iElement%).DetailLast).Equivalent + "< for >" + "Y" + "<"

                                        If Right(sField$, 1) = " " Then
                                            sOriginalField$ = sOriginalLeft$ + sOriginalField$ + sOriginalRight$
                                            iRc% = InStr(sOriginalField$, sNewCharacter$)
                                            Do While iRc% > 0
                                                Select Case Mid(sOriginalField$, iRc% + Len(sNewCharacter$), 1)
                                                    Case " "
                                                        sOriginalField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.SafeStuff(sOriginalField$, iRc%, Len(sNewCharacter$), sField$)
                                                    Case Chr(34), "'", ";", ":", ",", ".", "/", "<", ">", "?", "[", "]", "\", "{", "}", "|", "-", "=", "!", "@", "#", "$%", "^", "&", "*", "(", ")", "_", "+", ""
                                                        sOriginalField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.SafeStuff(sOriginalField$, iRc%, Len(sNewCharacter$), Trim(sField$))
                                                    Case Else
                                                        sOriginalField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.SafeStuff(sOriginalField$, iRc%, Len(sNewCharacter$), sField$)
                                                End Select
                                                iRc% = InStr(sOriginalField$, sNewCharacter$)
                                            Loop
                                            LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText = LocalMarcRecordObjectAlreadyLoadedWithRecord.RemoveRepeatedCharacters(sOriginalField$, " ")
                                        Else
                                            LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText = LocalMarcRecordObjectAlreadyLoadedWithRecord.RemoveRepeatedCharacters(LocalMarcRecordObjectAlreadyLoadedWithRecord.ReplaceCharacters(sOriginalLeft$ + sOriginalField$ + sOriginalRight$, sNewCharacter$, sField$), " ")
                                        End If
                                    Else
                                        sNewField$ = InputBox("Please supply the replacement text.  Non-ASCII characters are shown as Unicode(TM) values within curly braces." + vbLf + "Original: " + sNewField$, "Replace text", sNewField$)
                                        If Len(sNewField$) > 0 Then
                                            Do
                                                iRc% = InStr(sNewField$, "{U+")
                                                If iRc% = 0 Then
                                                    Exit Do
                                                End If
                                                sLeft2$ = Mid(sNewField$, 1, iRc% - 1)
                                                sNewField$ = Mid(sNewField$, iRc% + 3)
                                                iRc% = InStr(sNewField$, "}")
                                                If iRc% > 1 Then
                                                    sRight2$ = Mid(sNewField$, iRc% + 1)
                                                    LocalMarcCharacterObject.UcsHex = Mid(sNewField$, 1, iRc% - 1)
                                                    sNewField$ = LocalMarcCharacterObject.Utf8Char
                                                Else
                                                    sRight2$ = ""
                                                End If
                                                sNewField$ = sLeft2$ + sNewField$ + sRight2$
                                            Loop
                                            LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText = sLeft$ + sNewField$ + sRight$
                                        End If
                                    End If
                                Case ROMANIZATIONACTION_UCaseEach%
                                    sNewField$ = ""
                                    Do While Len(sField$) > 0
                                        GetNextPiece sField$, sWord$, " "
                                        sNewField$ = Trim(sNewField$ + " " + LocalMarcRecordObjectAlreadyLoadedWithRecord.UCaseFirstWord(sWord$))
                                    Loop
                                    LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText = sLeft$ + sNewField$ + sRight$
                            End Select
                            
                            GoTo RomanAssist_DisplayTheFinishedRecord
                        End If
                        
                    End If
        
            End Select
            
        Case ROMANIZATIONACTION_RomanizeWholeRecord%
            
            ' 20070830: NoRomanization added
'            If gblaRomanizationTable(iScript%).NoRomanization Then
'                GoTo RomanizationAssistanceNoFileOpenResume
'            End If
            
            iRc% = RomanizationAssistanceConvertWholeRecord(sType$, iScript%, LocalMarcRecordObjectAlreadyLoadedWithRecord, LocalMarcCharacterObject)

            If iRc% <> 0 Then
                RomanizationAssistance = iRc%
                Exit Function
            End If
            
            GoTo RomanAssist_DisplayTheFinishedRecord
    
        Case ROMANIZATIONACTION_DisplayMarcRecord%
    
RomanAssist_DisplayTheFinishedRecord:
            

            If iFldTextFormattedOption% = 99 Then
                Select Case iFixedFieldDisplayConvention%
                    Case 2 ' FixedFieldDisplay_OCLCMonospaced%
                        LocalRichTextBox.TextRTF = LocalMarcRecordObjectAlreadyLoadedWithRecord.TextFormatted(rtfText, OclcMonospaced, "", True, sRtfFontName$, iFontSizeForDisplay%)
                    Case 1 ' FixedFieldDisplay_OCLC
                        LocalRichTextBox.TextRTF = LocalMarcRecordObjectAlreadyLoadedWithRecord.TextFormatted(rtfText, oclc, "", True, sRtfFontName$, iFontSizeForDisplay%)
                    Case Else ' zero; notis
                        LocalRichTextBox.TextRTF = LocalMarcRecordObjectAlreadyLoadedWithRecord.TextFormatted(rtfText, notis, "", True, sRtfFontName$, iFontSizeForDisplay%)
                End Select
            Else
                Select Case iFixedFieldDisplayConvention%
                    Case 2 ' FixedFieldDisplay_OCLCMonospaced%
                        LocalRichTextBox.TextRTF = LocalMarcRecordObjectAlreadyLoadedWithRecord.TextFormatted(rtfTextwithlabels, OclcMonospaced, "", True, sRtfFontName$, iFontSizeForDisplay%)
                    Case 1 ' FixedFieldDisplay_OCLC
                        LocalRichTextBox.TextRTF = LocalMarcRecordObjectAlreadyLoadedWithRecord.TextFormatted(rtfTextwithlabels, oclc, "", True, sRtfFontName$, iFontSizeForDisplay%)
                    Case Else ' zero; notis
                        LocalRichTextBox.TextRTF = LocalMarcRecordObjectAlreadyLoadedWithRecord.TextFormatted(rtfTextwithlabels, notis, "", True, sRtfFontName$, iFontSizeForDisplay%)
                End Select
            End If
            
    End Select
    
RomanizationAssistanceNoFileOpenResume:

    Exit Function
    
RomanizationAssistanceBadKill:
RomanizationAssistanceNoFileOpen:


    RomanizationAssistance = ROMANIZATIONRESULT_FileOpen%
    On Error GoTo 0
    Resume RomanizationAssistanceNoFileOpenResume
    
End Function

Public Function FindFieldCurrentlyPointedTo(ByRef cRichTextBox As Control, ByRef LocalMarcRecord As Utf8MarcRecordClass, Optional ByVal bSearch As Boolean = False) As Long

    ' 20070207: created (so OK for Unicode already)
    
    ' find in a MARC record the field that corresponds to the field-currently-clicked-on
    '   in the rich text box
    ' return the pointer to that field (if the pointer is nonzero, the MARC record object also
    '   is currently pointed to that field, but the caller should probably not assume this)
    
    Dim lSelStart As Long, lOriginalSelStart As Long, lPtr As Long, lStart As Long
    
    Dim sField$, sRecord$, sFieldRemainderLeft$, sFieldRemainderRight$
    Dim sTagToFind$, sNonfilingString$
    Dim sLeft$, sRight$, sLineEnd$, sWholeField$
    
    Dim iRc%, iRc2%
    
    Dim bSkipTagTest As Boolean
    
    
    ' assume that we didn't find anything
    FindFieldCurrentlyPointedTo = -1
    
    ' this is a useful thing to have, either way
    lSelStart = cRichTextBox.SelStart
            
    If Len(cRichTextBox.SelText) > 0 Then
    
        ' the easier way out: at least one character is highlighted (we've
        '   already figured this out for the toolkit's re-romanization button, so we'll
        '   just translate that bit of business for the context here)
        lOriginalSelStart = lSelStart
        sField$ = cRichTextBox.SelRTF
        sRecord$ = cRichTextBox.TextRTF
            
        ' remove the closing brace from the selected text
        If Right(sField$, 1) = "}" Then
            sField$ = Mid(sField$, 1, Len(sField$) - 1)
        End If
        ' remove the RTF prefix from the selected text
        iRc% = InStr(sField$, "}}")
        If iRc% > 0 Then
            sField$ = Trim(Mid(sField$, iRc% + 2))
        End If
        ' text should now start with some additional 'slash' commands, which
        '   we will proceed to remove
        Do While Mid(sField$, 1, 1) = "\"
            If Mid(sField$, 1, 2) = "\u" Then
                If InStr("0123456789", Mid(sField$, 3, 1)) > 0 Then
                    Exit Do
                End If
            End If
            sField$ = Mid(sField$, 2)
            iRc% = InStr(sField$, "\")
            If iRc% = 0 Then
                iRc% = InStr(sField$, " ")
                If iRc% > 0 Then
                    sField$ = Mid(sField$, iRc% + 1)
                    Exit Do
                End If
            Else
                iRc2% = InStr(sField$, " ")
                If iRc2% > 0 Then
                    If iRc% < iRc2% Then
                        sField$ = Mid(sField$, iRc%)
                    Else
                        sField$ = Mid(sField$, iRc2% + 1)
                        Exit Do
                    End If
                Else
                    sField$ = Mid(sField$, iRc%)
                End If
            End If
        Loop
        ' remove any trailing 'par' command
        iRc% = LocalMarcRecord.Rat(sField$, "\par")
        If iRc% > 0 Then
            sField$ = Mid(sField$, 1, iRc% - 1)
        End If
        ' wrapping spaces are irrelevant
        sField$ = Trim(sField$)
        If Len(sField$) = 0 Then
            ' maybe we can work this out using just the
            '   SelStart pointer?
            GoTo FFCPT_UseJustSelStart
        End If
        
        ' in sField$ we should now have the raw RTF text of interest minus the wrapper
        
        ' oddly enough, the SelStart property of the rich text box
        '   refers to the plain text version
        '   of the field; there doesn't seem to be a corresponding SelStartRtf
        '   or anything else useful; so we're going to use the supplied SelStart
        '   property as a rough guide for finding the selection ourselves
        ' remembering that SelStart is zero-based (so we don't have to back up 1
        '   from lSelStart to find the "real" end of the preceding text, and we
        '   have to add 1 to the combined start and length to find the beginning
        '   of whatever follows the text (which is, from our point of view, possibly
        '   irrelevant)
        sFieldRemainderLeft$ = Mid(cRichTextBox.Text, 1, lSelStart)
        lPtr = LocalMarcRecord.Rat(sFieldRemainderLeft$, vbLf)
        If lPtr > 0 Then
            sFieldRemainderLeft$ = Trim(Mid(sFieldRemainderLeft$, lPtr + 1) + sField$)
            sTagToFind$ = Mid(sFieldRemainderLeft$, 1, 3)
        Else
            GoTo FFCPT_UseJustSelStart
        End If
        
        Select Case LocalMarcRecord.MarcRecordFormat
            Case "A"
                sNonfilingString$ = sAuthorityNonfilingString$
            Case "B", "D", "F", "M", "P", "S", "U"
                sNonfilingString$ = sBibliographicNonfilingString$
            'Case else: ignore the whole issue
        End Select
        
        ' to help us find the highlighted text within the record,
        '   give us the RTF version of the whole MARC record again
        ' we don't need to worry here about specification for fixed fields or
        '   font size, because they don't affect what we're up to here
        sRecord$ = LocalMarcRecord.TextFormatted(rtfText, OclcMonospaced)
        lStart = 1
        Do
            ' find the next occurrence of our text in the record
            lSelStart = InStr(lStart, sRecord$, sField$)
            DoEvents
            If lSelStart = 0 Then
                If lStart = 1 Then
                    GoTo FFCPT_UseJustSelStart
                End If
                ' we found at least one place already; so let's back up to find
                '   the first one (assuming that the first one is the right one!)
                lSelStart = InStr(1, sRecord$, sField$)
                If lSelStart = 0 Then
                    GoTo FFCPT_UseJustSelStart
                End If
                bSkipTagTest = True
            Else
                lStart = lSelStart + 1
            End If
            sLeft$ = Mid(sRecord$, 1, lSelStart - 1)
            sRight$ = Mid(sRecord$, lSelStart + Len(sField$))
            ' sLeft$ = all of the record up to our selected text
            ' sRight$ = and all of the record that follows the selected text
            ' we want to back up in sLeft to the beginning of the current "line" (i.e., variable field)
            lSelStart = LocalMarcRecord.Rat(sLeft$, sLineEnd$)
            If lSelStart > 0 Then
                sFieldRemainderLeft$ = LTrim(Mid(sLeft$, lSelStart + 5))
                If Mid(sFieldRemainderLeft$, 1, 2) = "\f" Then
                    sLeft$ = sLeft$ + Mid(sFieldRemainderLeft$, 1, 4)
                    sFieldRemainderLeft$ = Mid(sFieldRemainderLeft$, 5)
                End If
            Else
                sFieldRemainderLeft$ = ""
            End If
            If Mid(LTrim(sFieldRemainderLeft$ + sField$), 1, 3) = sTagToFind$ Or bSkipTagTest Then
                ' this is the field we want!  hooray!
                FindFieldCurrentlyPointedTo = LocalMarcRecord.FldPointer

                Exit Function
            End If
        
        Loop
        
        ' if we get here, we didn't find what we wanted, given the text highlighted by the
        '   operator
        ' we'll fall through and try the second method, using just the starting point of the
        '   highlight
        
    End If
    
    ' if we get here, either the operator didn't highlight any text at all, or
    '   we failed in the above attempt to find the highlighted text
    
FFCPT_UseJustSelStart:

    ' if we *branch to* here, there was something amiss with the text selected by the
    '   operator--maybe the operator just selected a space?
    
    ' no matter how we get here, we're going to try a second and more difficult/complicated
    '   operation, using just the start of the selection
    ' this is a bit more difficult, because the SelStart pointer relates to
    '   the plain-text version, not the RTF version; and in the plain text
    '   the fancy characters are all replaced by question marks
    


    ' isolate the text of the field
    ' put the text to the right of the insert point into sRight, and
    '   the text to the left of the insert point into sLeft
    sLeft$ = Mid(cRichTextBox.Text, 1, lSelStart)
    sRight$ = Mid(cRichTextBox.Text, lSelStart + 1)
    
    'Debug.Print "Text of interest:"
    'Debug.Print sLeft$ + sRight$
    
    ' remove parts of any following fields from the right bit of the record,
    '   leaving only the right part of the one field
    lPtr = LocalMarcRecord.Rat(sLeft$, vbLf)
    If lPtr = 0 Then
        lPtr = LocalMarcRecord.Rat(sLeft$, vbCr)
    End If
    If lPtr > 0 Then ' it better be!
        sLeft$ = Mid(sLeft$, lPtr + 1)
    End If
    ' remove parts of any preceding fields from the left bit of the record, leaving
    '   only the left part of the one field
    lPtr = InStr(sRight$, vbCr)
    If lPtr = 0 Then
        lPtr = LocalMarcRecord.Rat(sRight$, vbLf)
    End If
    If lPtr > 0 Then ' it better be!
        sRight$ = Mid(sRight$, 1, lPtr - 1)
    End If
        
    ' and here's the whole field
    sField$ = Trim(sLeft$ + sRight$)
    
    ' if now we don't have anything, then we're in serious trouble
    If Len(sField$) = 0 Then

        Exit Function ' with default return value of zero
    End If
    ' isolate the field's tag, and make sure that it's all numeric
    sTagToFind$ = Mid(sField$, 1, 3)
    If InStr("0123456789", Mid(sTagToFind$, 1, 1)) = 0 Or InStr("0123456789", Mid(sTagToFind$, 2, 1)) = 0 Or InStr("0123456789", Mid(sTagToFind$, 3, 1)) = 0 Then

        Exit Function ' with default return value of zero
    End If
    ' we only move 010 and higher
    If sTagToFind$ < "010" Then
        If Not bSearch Or (bSearch And sTagToFind$ <> "001") Then

            Exit Function
        End If
    End If
    
    ' does the field exist at all?
    LocalMarcRecord.FldMoveTop
    If Not LocalMarcRecord.FldFindFirst(sTagToFind$) Then

        Exit Function ' with default return value of zero
    End If
    
    ' if there is only one occurrence of the field, then
    '    that one occurrence *must* be the one we want
    If Not LocalMarcRecord.FldFindNext(sTagToFind$) Then
        ' back up to the field we found just above
        LocalMarcRecord.FldFindFirst sTagToFind$
        FindFieldCurrentlyPointedTo = LocalMarcRecord.FldPointer

        Exit Function
    End If
    
    ' OK, so there is more than one field with this tag; we'll have
    '   to do this the hard way and hope for the best
    
    ' the RTF version uses character 135 for the delimiter; translating that
    '   back to the 'real' delimiter means that we won't have to do the
    '   translation in the other direction for each field in the record
    sField$ = LocalMarcRecord.ReplaceCharacters(sField$, Chr(135), LocalMarcRecord.MarcDelimiter)

    LocalMarcRecord.FldMoveTop
    Do While LocalMarcRecord.FldFindNext(sTagToFind$)
        sLeft$ = LocalMarcRecord.FldTag + ":" + LocalMarcRecord.FldInd + ": " + LocalMarcRecord.AddSpacesAroundDelimiters(LocalMarcRecord.FldText)
        ' replace all of the 'special' characters with question marks
        For lPtr = Len(sLeft$) To 1 Step -1
            Select Case Asc(Mid(sLeft$, lPtr, 1))
                Case Is > 191 ' begins 1110 or 1100: first character in multi-byte sequence
                    sLeft$ = LocalMarcRecord.SafeStuff(sLeft$, lPtr, 1, "?")
                Case Is > 127 ' second or third character in multi-byte sequence
                    sLeft$ = LocalMarcRecord.SafeStuff(sLeft$, lPtr, 1, "")
            End Select
        Next ' lptr

        If sField$ = sLeft$ Then
            FindFieldCurrentlyPointedTo = LocalMarcRecord.FldPointer
            Exit Function
        End If
    Loop
    
    ' if we fall through to here, we were not able to find the field either way;
    ' 20100402: changed by David Bucknum from zero to -1:
    '   so we'll return with the default return value of -1

End Function

Public Function RomanizationAssistanceConvertWholeRecord(ByVal sRecordType$, ByVal iScript%, ByRef LocalMarcRecordObjectAlreadyLoadedWithRecord As Utf8MarcRecordClass, ByRef LocalMarcCharacterObject As Utf8CharClass) As Integer

    Dim sField$, sTag$, sTagToFind$, sIndicators$, s880Indicators$, sNative6$, s8806$, sLeftEnd$, sRecord$
    Dim sSelText$, sLeft$, sRight$, sRightAfterSelection$, sWholeField$, sWord$, sNewField$, sOldField$
    Dim sFieldRemainderRight$, sFieldRemainderLeft$, s6$, sOriginalField$, sSfd$, s066$
    Dim sTagToCopy$, sIndicatorsToCopy$, sFieldToCopy$, sNewFields$, sOldFields$
    Dim sSubfieldsExcludedUniversally$, sSubfieldsExcludedByTag$, sSubfield6Code$
    Dim sRLM$, sLRE$, sPDF$
    
    Dim iRc%, iRc2%, iRepeat%, iNext6%, iRomanizationStyle%, iDirection%
    
    Dim lPtr As Long, lSelLength As Long, lSelStart As Long, lStart As Long
    Dim lFldPointer As Long, lEnd As Long
        
    Dim bFound As Boolean, bSkipTagTest As Boolean
    Dim bCreateEmptyFields As Boolean, bCreateEmpty880s As Boolean
    Dim bLcPattern As Boolean
    
    Const sLineEnd = "\par"
    Const iLineEndLen = 5
            

    If gblaRomanizationTable(iScript%).DoNotUse880Field Then

        RomanizationAssistanceConvertWholeRecord = ROMANIZATIONRESULT_880NotAllowed%
        Exit Function
    End If
    
    If LocalMarcRecordObjectAlreadyLoadedWithRecord.FldFindFirst("880") Then

        RomanizationAssistanceConvertWholeRecord = ROMANIZATIONRESULT_880AlreadyPresent%
        Exit Function
    End If
    
    ' if the record contains *any* vernacular, then we assume that we're going
    '   from vernacular to roman; otherwise, we assume that we're going from
    '   roman to vernacular
    ' we need to know the direction before we meet up the first field during
    '   translation, so we know which set of tags to apply
    With LocalMarcRecordObjectAlreadyLoadedWithRecord
        iDirection% = ROMANIZATIONDIRECTION_Roman2Vernacular%
        .FldMoveTop
        Do While .FldMoveNext
            '20101213: Bucknum changed to "V2RFieldsIncluded" check to fix R2V/V2R logic below
            'If .FldTag > "009" Then
            If InStr(gblaRomanizationTable(iScript%).V2RFieldsIncluded, .FldTag) > 0 Then
                Do
                    'Debug.Print "Evaluating " + .FldTag + ":" + .SfdCode + ":" + .SfdText
                    If gblaRomanizationTable(iScript%).V2RCreateEmptyFields = True And _
                        .Utf8TextContainsOnlyMarc8Characters(.SfdText) = False Then
                        iDirection% = ROMANIZATIONDIRECTION_Vernacular2Roman%
                        GoTo RomanAssist_HaveDirection
                    ElseIf EvaluateFirstCharacter(.SfdText, iScript%, LocalMarcCharacterObject) = ROMANIZATIONDIRECTION_Vernacular2Roman% Then
                        iDirection% = ROMANIZATIONDIRECTION_Vernacular2Roman%
                        GoTo RomanAssist_HaveDirection
                    End If
                    If Not .SfdMoveNext Then
                        Exit Do
                    End If
                Loop
            End If
        Loop
RomanAssist_HaveDirection:
    End With


    ' 20070227: if we're going from romanized to vernacular, then
    '   figure out if we're going to try to do the work, or just
    '   create dummy fields for the operator to complete
    If iDirection% = ROMANIZATIONDIRECTION_Roman2Vernacular% Then
        If gblaRomanizationTable(iScript%).R2VCreateEmpty880s Then
            bCreateEmpty880s = True
            ' 20070425: pick up a script code if it's been defined--we'll include this
            '   in $6 of "empty" 880 fields, and also in 066
            ' 20070830: LC addition: if there is no such code, pick up
            '   a transmogrification of the langauge code instead; area reorganized
            sSubfield6Code$ = gblaRomanizationTable(iScript%).R2VSubfield6Code
            If LenB(sSubfield6Code$) = 0 Then
                sSubfield6Code$ = Language2ScriptCode(LocalMarcRecordObjectAlreadyLoadedWithRecord.Get008Value(35, 3))
            End If
            If LenB(sSubfield6Code$) > 0 Then
                s066$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "c" + sSubfield6Code$
                If sSubfield6Code$ = CHARACTERSET_CODES_FOR_880_HebrewAsG0$ Or _
                   sSubfield6Code$ = CHARACTERSET_CODES_FOR_880_BasicArabicAsG0$ Then
                    ' add R2L orientation code
                    sSubfield6Code$ = sSubfield6Code$ & "/r"
                End If
                ' add "/" prefix
                sSubfield6Code$ = "/" + sSubfield6Code$
            End If
        End If
        ' 20070710: set a variable for the MarcRightToLeftMarker
        '   LC wants a RTL marker before and after each delimiter,
        '   EXCEPT immediately following the $6 code itself
        If gblaRomanizationTable(iScript%).R2VIncludeFormattingCharactersLcPattern Or _
           InStr(sSubfield6Code$, "/r") > 0 Then
            ' set IncludeFormattingCharactersLcPattern = True to insert UFCs
            ' 20070830: Bucknum code forces value of this here; but we think
            '   this should come from the configuration file
            ' instead, we're going to set directly what DB was using this
            '   as a proxy for
            'gblaRomanizationTable(iScript%).R2VIncludeFormattingCharactersLcPattern = True
            bLcPattern = True
            With LocalMarcRecordObjectAlreadyLoadedWithRecord
                sRLM$ = .MarcRightToLeftMarker
                sLRE$ = .MarcLeftToRightEmbedding
                sPDF$ = .MarcPopDirectionalFormatting
            End With
        Else
            ' set IncludeFormattingCharactersLcPattern = False to not insert UFCs
            ' 20070830: Bucknum code forces value of this here; but we think
            '   this should come from the configuration file
            ' instead, we're going to leave sRLM at its ground state of null,
            '   which seems to be the point of all of this, anyway
            'gblaRomanizationTable(iScript%).R2VIncludeFormattingCharactersLcPattern = False
            bLcPattern = False
        End If
    Else
        If gblaRomanizationTable(iScript%).V2RCreateEmptyFields = True Then
            bCreateEmptyFields = True
        End If
    End If
    
    ' go through the record one field at a time
    ' if the field contains vernacular data, copy the field to 880 and create the
    '   parallel normal field with romanized vernacular data
    ' if the field contains no vernacular data, copy the field to 880, converting
    '   romanized text to vernacular as you go
    LocalMarcRecordObjectAlreadyLoadedWithRecord.FldMoveTop
    Do While LocalMarcRecordObjectAlreadyLoadedWithRecord.FldMoveNext
        DoEvents
        If Not LocalMarcRecordObjectAlreadyLoadedWithRecord.FldDeleted Then

            If iDirection% = ROMANIZATIONDIRECTION_Vernacular2Roman Then
                If InStr(gblaRomanizationTable(iScript%).V2RFieldsIncluded, LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag) = 0 Then
                    'Debug.Print LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag + " field excluded V2$"

                    GoTo RomanAssist_WholeRecordNextField
                End If
                sSubfieldsExcludedUniversally$ = gblaRomanizationTable(iScript%).V2RSubfieldsAlwaysExcluded
                sSubfieldsExcludedByTag$ = gblaRomanizationTable(iScript%).V2ROtherSubfieldsExcludedByTag
            Else
                If InStr(gblaRomanizationTable(iScript%).R2VFieldsIncluded, LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag) = 0 Then

                    GoTo RomanAssist_WholeRecordNextField
                End If
                sSubfieldsExcludedUniversally$ = gblaRomanizationTable(iScript%).R2VSubfieldsAlwaysExcluded
                sSubfieldsExcludedByTag$ = gblaRomanizationTable(iScript%).R2VOtherSubfieldsExcludedByTag
            End If
            sTag$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag
            sNewField$ = ""
            sOldField$ = ""
            LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdMoveFirst
            Do
                ' 20070710: add RLMs before and after the delimiter/subfield codes,
                '   as appropriate, but *only* if the Right2LeftMark variable is set
                ' 20070713: add a LeftToRightEmbedding character (LRE) only
                '   before the 880 $6 260-xx $c [dates] - a PDF is added below
                ' 20121121: added 264 (RDA) to logic
                If bLcPattern Then
                    sNewField$ = sNewField$ + sRLM$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdCode + sRLM$
                    If sTag$ Like "26[04]" And LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdCode = "c" Then
                        sNewField$ = sNewField$ + sLRE$
                    End If
                Else
                    sNewField$ = sNewField$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdCode
                End If
                sOldField$ = sOldField$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdCode + LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText
                If bCreateEmpty880s Or bCreateEmptyFields Then
' added 20070308 by David Bucknum
#If True Then
                    ' replacement proposed by Bucknum
                    ' include this subfield, but change it to a plus sign
                    '   if the 260 $c contains an ending period, add it for PDF processing
                    ' 20121121: added 264 (RDA) to logic
                    If sTag$ Like "26[04]" And LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdCode = "c" And Right(LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText, 1) = "." Then
                        sNewField$ = sNewField$ + "+."
                    Else
                        sNewField$ = sNewField$ + "+"
                    End If
#Else
                    ' include this subfield without attampting to change it
                    sNewField$ = sNewField$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText
#End If
                ElseIf InStr(sSubfieldsExcludedUniversally$, LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdCode) > 0 Then
                    ' include this subfield attempting to change it
                    sNewField$ = sNewField$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText
                ElseIf InStr(sSubfieldsExcludedByTag$, LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag + "/" + LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdCode) > 0 Then
                    ' include this subfield without attampting to change it
                    sNewField$ = sNewField$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText
                Else ' we attempt to change this subfield

                    Select Case iDirection% ' EvaluateFirstCharacter(LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText, iScript%, LocalMarcCharacterObject)
                        Case ROMANIZATIONDIRECTION_Vernacular2Roman%, ROMANIZATIONDIRECTION_Roman2Vernacular%
                            If LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdCode = "a" Then
                                sSfd$ = ReRomanizeText(sRecordType$, sTag$, LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText, iScript%, LocalMarcRecordObjectAlreadyLoadedWithRecord, LocalMarcCharacterObject, iDirection%)
                                'Debug.Print "Subfield changed: >" + sSfd$ + "<"
                                If sSfd$ <> LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText Then
                                    sNewField$ = sNewField$ + ReRomanizeText(sRecordType$, sTag$, LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText, iScript%, LocalMarcRecordObjectAlreadyLoadedWithRecord, LocalMarcCharacterObject, iDirection%, LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdCode)
                                Else
                                    sNewField$ = sNewField$ + ReRomanizeText(sRecordType$, sTag$, LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText, iScript%, LocalMarcRecordObjectAlreadyLoadedWithRecord, LocalMarcCharacterObject, iDirection%, LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdCode)
                                End If
                            Else
                                 sNewField$ = sNewField$ + ReRomanizeText(sRecordType$, sTag$, LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText, iScript%, LocalMarcRecordObjectAlreadyLoadedWithRecord, LocalMarcCharacterObject, iDirection%, LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdCode)
                            End If
                        Case Else
                            sNewField$ = sNewField$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdText
                    End Select
                End If
                ' 20070713: add a POPDirectionalFormatting character (PDF) only
                '   at the end of the 880 $6 260-xx $c [dates] - an LRE is added above
                ' 20121121: added 264 (RDA) to logic
                If bLcPattern Then
                    If sTag$ Like "26[04]" And LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdCode = "c" Then
                        ' if the subfield ends with a period, place the period after the PDF
                        If Right(sNewField$, 1) = "." Then
                            sNewField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.SafeStuff(sNewField$, InStrRev(sNewField$, "."), 1, sPDF$ + ".")
                        Else
                            sNewField$ = sNewField$ + sPDF$
                        End If
                    End If
                End If
                If Not LocalMarcRecordObjectAlreadyLoadedWithRecord.SfdMoveNext Then
                    Exit Do
                End If
            Loop


            sIndicators$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.FldInd
            ' change 880 $6 6xx-xx 2nd indicator to "4" (source not specified)
            If sTag$ >= 600 And sTag$ <= 651 Then
                s880Indicators$ = Mid$(sIndicators$, 1, 1) & "4"
            Else
                s880Indicators$ = sIndicators$
            End If
            
            If bCreateEmpty880s Then
                ' we're only creating an "empty" 880 field
                iNext6% = iNext6% + 1
                If Len(sNewFields$) > 0 Then
                    sNewFields$ = sNewFields$ + vbLf
                    sOldFields$ = sOldFields$ + vbLf
                End If
                ' 20070425 script code added if available (only available if roman-to-vernacular)
#If True Then
                ' changed 20070308 by David Bucknum
                ' use this line if you want a truly empty 880 field *OR* fields with "+" as subfield text
                If bLcPattern Then
                    sNewFields$ = sNewFields$ + "880" + s880Indicators$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6" + LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag + "-" + Right("00" + Trim(str(iNext6%)), 2) + sSubfield6Code$ + sRLM$ + sNewField$
                Else
                    sNewFields$ = sNewFields$ + "880" + s880Indicators$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6" + LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag + "-" + Right("00" + Trim(str(iNext6%)), 2) + sSubfield6Code$ + sNewField$
                End If
#Else
                ' use this line if you want the 880 field to start out with text as given in the original field
                If bLcPattern Then
                    sNewFields$ = sNewFields$ + "880" + s880Indicators$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6" + LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag + "-" + Right("00" + Trim(str(iNext6%)), 2) + sSubfield6Code$ + sRLM$ + sOldField$
                Else
                    sNewFields$ = sNewFields$ + "880" + s880Indicators$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6" + LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag + "-" + Right("00" + Trim(str(iNext6%)), 2) + sSubfield6Code$ + sOldField$
                End If
#End If
                sOldFields$ = sOldFields$ + Trim(str(LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer)) + vbTab + LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6" + "880-" + Right("00" + Trim(str(iNext6%)), 2) + sOldField$
            ElseIf bCreateEmptyFields Then
                ' we're only creating an "empty" romanized field
                iNext6% = iNext6% + 1
                If Len(sNewFields$) > 0 Then
                    sNewFields$ = sNewFields$ + vbLf
                    sOldFields$ = sOldFields$ + vbLf
                End If
#If True Then
                ' changed 20090524 by David Bucknum
                ' use this line if you want a truly empty romanized field *OR* fields with "+" as subfield text
                sNewFields$ = sNewFields$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag + sIndicators$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6880-" + Right("00" + Trim(str(iNext6%)), 2) + sNewField$
#Else
                ' use this line if you want the 880 field to start out with text as given in the original field
                sNewFields$ = sNewFields$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag + sIndicators$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6880-" + Right("00" + Trim(str(iNext6%)), 2) + sOldField$
#End If
                sOldFields$ = sOldFields$ + Trim(str(LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer)) + vbTab + s880Indicators$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6" + LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag + "-" + Right("00" + Trim(str(iNext6%)), 2) + sOldField$
            Else
                If sNewField$ <> sOldField$ Then ' we changed *something*!
                    iNext6% = iNext6% + 1
                    If Len(sNewFields$) > 0 Then
                        sNewFields$ = sNewFields$ + vbLf
                        sOldFields$ = sOldFields$ + vbLf
                    End If
                    If iDirection% = ROMANIZATIONDIRECTION_Vernacular2Roman% Then
                        sOldFields$ = sOldFields$ + Trim(str(LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer)) + vbTab + s880Indicators$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6" + LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag + "-" + Right("00" + Trim(str(iNext6%)), 2) + sOldField$
                        sNewFields$ = sNewFields$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag + sIndicators$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6880-" + Right("00" + Trim(str(iNext6%)), 2) + sNewField$
                    Else
                        sNewFields$ = sNewFields$ + "880" + s880Indicators$ + LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6" + LocalMarcRecordObjectAlreadyLoadedWithRecord.FldTag + "-" + Right("00" + Trim(str(iNext6%)), 2) + sNewField$
                        sOldFields$ = sOldFields$ + Trim(str(LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer)) + vbTab + LocalMarcRecordObjectAlreadyLoadedWithRecord.MarcDelimiter + "6" + "880-" + Right("00" + Trim(str(iNext6%)), 2) + sOldField$
                    End If
                End If
            End If
        End If
RomanAssist_WholeRecordNextField:
    Loop
    Do While Len(sOldFields$) > 0
        DoEvents
        GetNextPiece sOldFields$, sField$, vbLf
        If iDirection% = ROMANIZATIONDIRECTION_Vernacular2Roman% Then
            GetNextPiece sField$, sTag$, vbTab
            LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer = Val(sTag$)
            LocalMarcRecordObjectAlreadyLoadedWithRecord.FldDelete
            LocalMarcRecordObjectAlreadyLoadedWithRecord.FldAdd "880", Mid(sField$, 1, 2), Mid(sField$, 3)
        Else
            GetNextPiece sField$, sTag$, vbTab
            LocalMarcRecordObjectAlreadyLoadedWithRecord.FldPointer = Val(sTag$)
            ' 20100809 Bucknum added: remove temporary VowelMarker character before export
            If LenB(gblaRomanizationTable(iScript%).R2VVowelMarker) > 0 Then
                sField$ = LocalMarcRecordObjectAlreadyLoadedWithRecord.ReplaceCharacters(sField$, gblaRomanizationTable(iScript%).R2VVowelMarker)
            End If
            LocalMarcRecordObjectAlreadyLoadedWithRecord.FldText = sField$
        End If
    Loop
    Do While Len(sNewFields$) > 0
        GetNextPiece sNewFields$, sField$, vbLf
        If iDirection% = ROMANIZATIONDIRECTION_Vernacular2Roman% Then
            LocalMarcRecordObjectAlreadyLoadedWithRecord.FldAdd Mid(sField$, 1, 3), Mid(sField$, 4, 2), LocalMarcRecordObjectAlreadyLoadedWithRecord.UCaseFirstWord(Mid(sField$, 6))
        Else
            LocalMarcRecordObjectAlreadyLoadedWithRecord.FldAdd Mid(sField$, 1, 3), Mid(sField$, 4, 2), Mid(sField$, 6)
        End If
    Loop
    
    ' 20070425 build an 066 if the script identification code is available
    '   only possible if building empty 880s and if roman-to-vernacular
    If bCreateEmpty880s And LenB(s066$) > 0 Then
        If Not LocalMarcRecordObjectAlreadyLoadedWithRecord.FldFindFirst("066") Then
            LocalMarcRecordObjectAlreadyLoadedWithRecord.FldAdd "066", "  ", s066$
        End If
    End If
        
    
End Function

Public Sub ReRomanizeAdjustNonfilingIndicators(iScript%, ByVal sNonfilingTagString$, ByVal lPointerToOriginalField As Long, ByVal lPointerToNewField As Long, ByRef LocalMarcRecord As Utf8MarcRecordClass, ByRef LocalCharacterObject As Utf8CharClass)

    Dim iNonfiling%, iNonfilingIndicator%, iRc%, iLen%
    
    Dim sOriginal$
    
    

    With LocalMarcRecord

        .FldPointer = lPointerToOriginalField

        If .SfdFindFirst("a") Then
            If .FldTag = "880" Then
                If .SfdFindFirst("6") Then
                    iRc% = InStr(sNonfilingTagString$, Mid(.SfdText, 1, 3))
                End If
                .SfdFindFirst "a"
            Else
                iRc% = InStr(sNonfilingTagString$, .FldTag)
            End If

            If iRc% > 0 Then
                iNonfiling% = Val(Mid(sNonfilingTagString$, iRc% + 4, 1))

                If iNonfiling% > 0 Then
                    ' we're going to ignore nonfiling indicator values of 1,
                    '   because they almost certainly refer to an error (such as
                    '   skipping an opening quotation mark)
                    iNonfilingIndicator% = Val(Mid(.FldInd, iNonfiling%, 1))

                    If iNonfilingIndicator% > 0 Then
                        sOriginal$ = .SafeMid(.SfdText, 1, iNonfilingIndicator%)

                        .FldPointer = lPointerToNewField

                        If .SfdFindFirst("a") Then
                            If Mid(.SfdText, 1, Len(sOriginal$)) <> sOriginal$ Then
                                ' the beginning of subfield $a in the modified field is
                                '   not same as the beginning of subfield $a in the original
                                '   field: therefore, the current operation changed the value
                                '   of subfield $a, and we need to address the problem of the
                                '   initial articla
                                ' at this point we have to know whether the conversion was
                                '   vernacular-to-script or script-to-vernacular
                                If .FldTag = "880" Then
                                    ' the tag of the new field is 880; therefore, the conversion
                                    '   was from romanized-to-vernacular; sOriginal$ contains the
                                    '   romanized form of the critical text
                                    sOriginal$ = ReRomanizeText("B", "500", sOriginal$, iScript%, LocalMarcRecord, LocalCharacterObject, ROMANIZATIONDIRECTION_Roman2Vernacular%)
                                Else
                                    ' the tag of the new field is NOT 880; therefore, the conversion
                                    '   was from vernacular-to-romanized; sOriginal$ contains the
                                    '   romanized form of the critical text
                                    sOriginal$ = ReRomanizeText("B", "500", sOriginal$, iScript%, LocalMarcRecord, LocalCharacterObject, ROMANIZATIONDIRECTION_Vernacular2Roman%)
                                End If

                                If Mid(.SfdText, 1, Len(sOriginal$)) = sOriginal$ Then
                                    iLen% = .SafeLen(sOriginal$)
                                    If iLen% < 9 Then
                                        'Debug.Print ">" + .FldInd + "< " + str(iNonfiling%) + " " + str(iLen%)
                                        .FldInd = .SafeStuff(.FldInd, iNonfiling%, 1, Trim(str(iLen%)))
                                        'Debug.Print "After change: >" + .FldInd + "<"
                                    End If
                                End If
                            End If
                        End If
                    End If
                End If
            End If
        End If
    End With
    
End Sub

Public Function Language2ScriptCode(ByVal sLanguageCode$) As String

    Select Case sLanguageCode$
'        Case ""
'            Language2ScriptCode = CHARACTERSET_CODES_FOR_880_BasicAsG0$
        Case "heb", "yid"
            Language2ScriptCode = CHARACTERSET_CODES_FOR_880_HebrewAsG0$
        Case "bel", "mac", "rus", "scc", "ukr"
            Language2ScriptCode = CHARACTERSET_CODES_FOR_880_BasicCyrillicAsG0$
        Case "ara", "per", "urd"
            Language2ScriptCode = CHARACTERSET_CODES_FOR_880_BasicArabicAsG0$
        Case "gre"
            Language2ScriptCode = CHARACTERSET_CODES_FOR_880_GreekAsG0$
        Case "chi", "jap", "kor"
            Language2ScriptCode = CHARACTERSET_CODES_FOR_880_CJKAsG0$
' don't know which, if any, languages belong here by default:
'        Case ""
'            Language2ScriptCode = CHARACTERSET_CODES_FOR_880_ExtendedCyrillicAsG1$
'        Case ""
'            Language2ScriptCode = CHARACTERSET_CODES_FOR_880_ExtendedArabicAsG1$
'        Case ""
'            Language2ScriptCode = CHARACTERSET_CODES_FOR_880_ExtendedLatinAsG1$
        Case Else
            Language2ScriptCode = ""
    End Select

End Function

Public Function ReSequencePairedFields(ByRef LocalMarcRecordObjectAlreadyLoadedWithRecord As Utf8MarcRecordClass)

    Dim iCtr%
    Dim lPtr&
    Dim sSfdText$
    Dim bMatchFound As Boolean
    
    gbliReSequenceTableLast% = 0

    With LocalMarcRecordObjectAlreadyLoadedWithRecord
        ' loop through record to find non-880s with subfield $6
        .FldMoveTop
        Do While .FldMoveNext
            ' create array of non-880 fields with subfield $6
            ' with new consecutive sequence numbers
            If .FldTag <> "880" Then
                If .SfdFindFirst("6") = True Then
                    If Mid$(.SfdText, 5, 2) <> "00" Then
                        gbliReSequenceTableLast% = gbliReSequenceTableLast% + 1
                        ReDim Preserve gblaReSequenceTable(gbliReSequenceTableLast%)
                        gblaReSequenceTable(gbliReSequenceTableLast%).Tag = .FldTag
                        gblaReSequenceTable(gbliReSequenceTableLast%).Field = .FldText
                        gblaReSequenceTable(gbliReSequenceTableLast%).Sequence = gbliReSequenceTableLast%
                    ' "00" (non-paired) should not appear in a non-880 subfield $6
                    ' but we'll not delete it for now
'                   Else: .SfdDelete
                    End If
                End If
            End If
        Loop

        ' cannot resequence, if no non-880 subfield $6s are found
        If gbliReSequenceTableLast% = 0 Then Exit Function
        
        ' loop through the record again to match 880s with non-880s
        .FldMoveTop
        Do While .FldMoveNext
            ' add paired and non-paired 880s to the array
            If .FldTag = "880" Then
                If .SfdFindFirst("6") = True Then
                    ' make sure 880 $6 6xx-xx 2nd indicators are set to "4" (source not specified)
                    If Mid$(.SfdText, 1, 3) >= 600 And Mid$(.SfdText, 1, 3) <= 651 Then
                        .FldInd2 = "4"
                    End If
                    If Mid$(.SfdText, 5, 2) <> "00" Then
                        bMatchFound = False
                        For iCtr% = 1 To gbliReSequenceTableLast%
                            ' first make sure the 880 sequence number is zero
                            If gblaReSequenceTable(iCtr%).Sequence880 = 0 Then
                                ' if there is a match, pair the sequence numbers
                                ' add the link tag and field text for comparison later
                                If Mid$(.SfdText, 1, 3) = gblaReSequenceTable(iCtr%).Tag Then
                                    gblaReSequenceTable(iCtr%).LinkTag = gblaReSequenceTable(iCtr%).Tag
                                    gblaReSequenceTable(iCtr%).Field880 = .FldText
                                    gblaReSequenceTable(iCtr%).Sequence880 = gblaReSequenceTable(iCtr%).Sequence
                                    bMatchFound = True
                                    Exit For
                                End If
                            End If
                        Next ' iCtr%
                    End If
                    ' add non-paired 880s to the array with a "00" sequence number
                    If bMatchFound = False Or Mid$(.SfdText, 5, 2) = "00" Then
                        gbliReSequenceTableLast% = gbliReSequenceTableLast% + 1
                        ReDim Preserve gblaReSequenceTable(gbliReSequenceTableLast%)
                        gblaReSequenceTable(gbliReSequenceTableLast%).Tag = .FldTag
                        gblaReSequenceTable(gbliReSequenceTableLast%).Field = .FldText
                        gblaReSequenceTable(gbliReSequenceTableLast%).Sequence = 0
                        gblaReSequenceTable(gbliReSequenceTableLast%).Sequence880 = 0
                    End If
                End If
            End If
        Loop
        
        ' loop through record again to resequence the paired fields
        .FldMoveTop
        Do While .FldMoveNext
            ' get field pointer
            lPtr& = .FldPointer
            If Val(.FldTag) > 99 Then
                If .SfdFindFirst("6") = True Then
                    ' loop through the field/sequence array
                    For iCtr% = 1 To gbliReSequenceTableLast%
                        ' 20080826: compare the tags and field data, if matched,
                        '  adjust the sequence numbers in the field, and
                        '  delete the field data to prevent a rematch
                        ' non-880s
                        If .FldTag = gblaReSequenceTable(iCtr%).Tag And _
                           .FldText = gblaReSequenceTable(iCtr%).Field Then
                            .SfdText = .SafeStuff(.SfdText, 5, 2, Right("00" & CStr(gblaReSequenceTable(iCtr%).Sequence), 2))
                            ' change field text to avoid re-matching an "empty" field (i.e. with "+" subfields)
                            gblaReSequenceTable(iCtr%).Field = ""
                            Exit For
                        ' 880s
                        ElseIf Mid$(.SfdText, 1, 3) = gblaReSequenceTable(iCtr%).LinkTag And _
                           .FldText = gblaReSequenceTable(iCtr%).Field880 Then
                            .SfdText = .SafeStuff(.SfdText, 5, 2, Right("00" & CStr(gblaReSequenceTable(iCtr%).Sequence880), 2))
                            ' change field text to avoid re-matching an "empty" 880 (i.e. with "+" subfields)
                            gblaReSequenceTable(iCtr%).Field880 = ""
                            Exit For
                        End If
                    Next ' iCtr%
                End If
            End If
            ' reset field pointer
            .FldPointer = lPtr&
        Loop
        
    End With
    
    ' clear the array from memory
    Erase gblaReSequenceTable

End Function

Public Function AddCharSetCodes2Utf8Record(ByRef LocalMarcRecordObjectAlreadyLoadedWithRecord As Utf8MarcRecordClass, ByVal iScript%)

    Dim iPtr%, iCtr%, iNonfiling%, iIndicator%
    Dim bChanged As Boolean, bError As Boolean
    Dim sTag$, sIndicators$, sField$, sNonfiling$, sChar$
    Dim sCharacterSetsPresent$, s066$, sSfd6$, sPiece$
    Dim bLcPattern As Boolean
    
    If gblaRomanizationTable(iScript%).R2VIncludeFormattingCharactersLcPattern Then bLcPattern = True
    
    With LocalMarcRecordObjectAlreadyLoadedWithRecord

        .FldMoveTop
        Do While .FldMoveNext
            iPtr% = .FldPointer
            ' remove any existing 066 fields, but *not* in records with "empty" 880s
            If .FldTag = "066" And gblaRomanizationTable(iScript%).R2VCreateEmpty880s = False Then .FldDelete
            ' get the $6, including script codes, using a fake Utf82Marc translation
            If .FldTag = "880" Then
                .FldLoadInfo sTag$, sIndicators$, sField$
                .TranslateUtf82MarcOneField sCharacterSetsPresent$, sTag$, sField$, bChanged, bError
                If bChanged Then
                    If .SfdFindFirst("6") = True And _
                       .ExtractSubfield(sField$, "6", sSfd6$) > 0 Then
                        ' 20070710: add RLM to the end of subfield $6 in "empty" fields for R2L scripts
                        If bLcPattern Or InStr(sSfd6$, "/r") > 0 Then
                            sSfd6$ = sSfd6$ & .MarcRightToLeftMarker
                        End If
                        .SfdChange "6", sSfd6$
                    End If
                End If
                ' 20070710: check for and add the RLMs in the 880 fields for
                ' the R2L scripts, if they have not been inserted elsewhere
                If bLcPattern Or InStr(sSfd6$, "/r") > 0 Then
                    .FldText = .TranslateMarc2Utf8OneFieldLcPattern("880", .FldText)
                    ' remove any multiple UFCs from the field
                    .FldText = .RemoveRepeatedCharacters(.FldText, .MarcRightToLeftMarker)
                    .FldText = .RemoveRepeatedCharacters(.FldText, .MarcLeftToRightEmbedding)
                    .FldText = .RemoveRepeatedCharacters(.FldText, .MarcPopDirectionalFormatting)
                End If
            End If
            .FldPointer = iPtr%
        Loop

        ' convert the string of codes representing character sets present in the record into
        '   an 066 field, and add it to or change it in the record, but *not* in records with "empty" 880s
        ' remove multiple spaces from the string
        sCharacterSetsPresent$ = .RemoveRepeatedCharacters(Trim(sCharacterSetsPresent$), " ")
        s066$ = .TranslateUtf82MarcCharacterSetString(sCharacterSetsPresent$, .MarcDelimiter + "c")
        If Len(s066$) > 0 Then
            If Not .FldFindFirst("066") Or gblaRomanizationTable(iScript%).R2VCreateEmpty880s = False Then
                .FldAddGeneric "066", "  ", s066$, 3
            ElseIf .FldText <> s066$ Then
                .FldChange "066", "  ", s066$
            End If
        End If
        
    End With
    
End Function

Public Function RomanizeConvertDecimalChars(ByVal sIn$, ByRef LocalMarcRecordObject As Utf8MarcRecordClass, ByRef LocalCharacterObject As Utf8CharClass) As String

    ' convert "&#\d{4,5}" numeric character references to the equivalent, leaving other stuff as you find it
    Dim lPtr As Long
    
    Dim sLeader$, sOriginal$, sHexChar$
    Dim iDigits%
    
    Dim bShow As Boolean
       
    'If InStr(sIn$, "&#") > 0 Then
    '    bShow = True
    '    sOriginal$ = sIn$
    'End If
    
    sLeader$ = "&#"
    
    Do
        lPtr = InStr(sIn$, sLeader$)
        Do While lPtr > 0
            ' allow conversion of up to 5-digit character references
            iDigits% = Len(CStr(Val(Mid$(sIn$, lPtr + 2, 5))))
            sHexChar$ = Hex$(Mid$(sIn$, lPtr + 2, iDigits%))
            LocalCharacterObject.UcsHex = Right$(String$(4 - Len(sHexChar$), "0") & sHexChar$, 4)
            sIn$ = LocalMarcRecordObject.SafeStuff(sIn$, lPtr, iDigits% + 2, LocalCharacterObject.Utf8Char)
            lPtr = InStr(sIn$, sLeader$)
        Loop
        Select Case sLeader$
            Case "&#"
                ' scossu: added a third backslash because 2 backslashes mess up syntax coloring in Vim.
                sLeader$ = "\\\"
            ' scossu: added a third backslash because 2 backslashes mess up syntax coloring in Vim.
            Case "\\\"
                Exit Do
        End Select
    Loop
    
    RomanizeConvertDecimalChars = sIn$
    
End Function

Public Function FindScriptByKeyPress(ByRef c As Control, ByRef KeyAscii As Integer)
    
    Dim cb As Long
    Dim FindString As String
   
    If KeyAscii < 32 Or KeyAscii > 127 Then Exit Function
   
    If c.SelLength = 0 Then
        FindString = c.Text & Chr$(KeyAscii)
    Else
        FindString = Left$(c.Text, c.SelStart) & Chr$(KeyAscii)
    End If
   
    cb = SendMessage(c.hWnd, CB_FINDSTRING, -1, ByVal FindString)
   
    If cb <> CB_ERR Then
        c.ListIndex = cb
        c.SelStart = Len(FindString)
        c.SelLength = Len(c.Text) - c.SelStart
    End If
    
    KeyAscii = 0
    
End Function

Public Function IsFontInstalled(FontName As String) As Boolean

    ' Returns true in function name
    ' if parameter font name exists
    
    Dim oFont As New StdFont
    
On Error Resume Next
    
    IsFontInstalled = False
    
    If LenB(FontName) > 0 Then
        With oFont
            .Name = FontName
            If StrComp(FontName, .Name, vbTextCompare) = 0 Then IsFontInstalled = True
        End With
    End If

    Set oFont = Nothing
    
End Function

Public Function CreateRomanizationScriptList(ByRef sConfigurationFilePath$, ByRef sScripts2Load As String)

    Dim sMasterFile$, sFile$
    Dim sScripts2LoadList$()
    Dim iCtr%, iPtr%
    Dim bLoadAllScripts As Boolean

    sMasterFile$ = sConfigurationFilePath$ + "RomanizationMaster.cfg"

    If sScripts2Load$ = vbNullString Then
        bLoadAllScripts = True
    Else
        sScripts2LoadList$() = Split(sScripts2Load$)
    End If
    
    gbliRomanizationScriptLast% = 0
    gbliRomanizationTablesBytes# = 0

    Do
        iCtr% = gbliRomanizationScriptLast% + 1
        sFile$ = ReadIniFileOrNothing(sMasterFile$, "Files", Trim(str(iCtr%)), 250)
        
        If LenB(sFile$) = 0 Then Exit Do
        
        gbliRomanizationScriptLast% = gbliRomanizationScriptLast% + 1
        ReDim Preserve gblaRomanizationScript(gbliRomanizationScriptLast%)
        
        If InStr(sFile$, "\") = 0 Then
            If LenB(Dir$(sConfigurationFilePath$ + sFile$)) Then
                gblaRomanizationScript(gbliRomanizationScriptLast%).Name = ReadIniFileOrNothing(sConfigurationFilePath$ + sFile$, "General", "Name", 100)
                gblaRomanizationScript(gbliRomanizationScriptLast%).FileSize = FileLen(sConfigurationFilePath$ + sFile$)
            End If
        Else
            If LenB(Dir$(sFile$)) Then
                gblaRomanizationScript(gbliRomanizationScriptLast%).Name = ReadIniFileOrNothing(sFile$, "General", "Name", 100)
                gblaRomanizationScript(gbliRomanizationScriptLast%).FileSize = FileLen(sFile$)
            End If
        End If
        If bLoadAllScripts Then
            gblaRomanizationScript(gbliRomanizationScriptLast%).LoadScript = True
            gbliRomanizationTablesBytes# = gbliRomanizationTablesBytes# + gblaRomanizationScript(gbliRomanizationScriptLast%).FileSize
        Else
            gblaRomanizationScript(gbliRomanizationScriptLast%).LoadScript = False
            For iPtr% = 0 To UBound(sScripts2LoadList$)
                If CInt(sScripts2LoadList$(iPtr%)) = gbliRomanizationScriptLast% Then
                    gblaRomanizationScript(gbliRomanizationScriptLast%).LoadScript = True
                    gbliRomanizationTablesBytes# = gbliRomanizationTablesBytes# + gblaRomanizationScript(gbliRomanizationScriptLast%).FileSize
                End If
            Next ' iPtr%
        End If
    Loop
    
End Function

Public Sub LoadRomanizationTablesProgress(l As Long, ProgressBarCtrl As Control)

    If ProgressBarCtrl.Value < (ProgressBarCtrl.Max - l) Then
        ProgressBarCtrl.Value = ProgressBarCtrl.Value + l
    End If
        
End Sub

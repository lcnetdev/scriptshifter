# Romanization service implementation notes

## `.cfg` files

The `.cfg` format seems to follow a INI-like syntax that is ad-hoc-parsed by
the Transliterator.

Unicode points are expressed as `U+????` rather than `\x????` of the standard
INI syntax.

So far only top-level section names have been encountered.

Key-value pairs may express either a transliteration operation, e.g.

```
U+182CU+1820=qU+0307a
```

Or a passthrough (verbatim copy) operation, such as

```
At head of title=At head of title
```

Or a configuration directive, e.g.

```
SubfieldsAlwaysExcluded=uvxy0123456789
```

This last option may appear in any section, the first two only in the
transliteration sections.

It is unclear how configuration directives can be distinguished from
transliteration rules, except by naming all the possible verbatim copy options.
A more readable and efficent format would have discrete subsections for
configuration and transliteration—if necessary, with configuration and mapping
subsections inside S2R and R2S sections.

Q: Is it possible to copy non-mapped characters verbatim in script to Roman?
That would remove the need to explicitly add English phrases to the S2R section
such as `publisher not identified=publisher not identified`.

Q: Shall spaces around the `=` sign be ignored?

A (RB): Very likely yes, spaces are represented in the legacy files by
underscores.

Q: What are the `_` at the end of some mappings, e.g. `U+4E00=yi_` for Chinese?
Are they supposed to add a space where the underscore appears?

A (RB): Yes.

## `ReRomanizeRecord.bas`

Much of the code deals with MARC records. No need to concern about that since
the new Transliterator is meant to convert text strings to text strings.

Q: Is it possible (and desirable) to determine the S2R/R2S direction from user
prompt rather than guessing it from the text as the legacy software seems to
be doing?

A (RB): Yes.

Q: The software seems to take multi-line directives in the configuration into
account. Is it possible to avoid these for simplicity, or is there a need to
express some mapping in multiple lines?

A (RB): Long lines may be needed. (SC) This would be moot in YAML that supports
multi-line strings via folding.

Detailed breakdown of individual functions follows.


### Functions

#### `ReRomanizeText`

- Determine direction (input param): R2S or S2R
- Determine personal name handling
- Whether to uppercase first word


#### `LoadOneRomanizationTable`

Load cfg file (line by line, we can do the whole thing) and parse table
metadata.

Skip lines starting with `#` (comments).

Lines starting with `[` are section defiinitions. The supported sections are
`General`, `ScriptToRoman`, and `RomanToScript`.

##### `General` Section

Potentially relevant variables:

- Name
- NoRomanization
- AllowCaseVariation
- ApostropheCharacters
- AllowCaseVariation
- ApostropheCharacters
- BySyllables
- Truncation

Likely irrelevant:

- FontName
- DoNotUse880Field
- AllowDefineButton (what is this? Just UI related?)

##### `RomanToScript` section

If there is no `=` sign, it is assumed to be a multi-line directive, and the
next line should be loaded and merged with the previous content.

Otherwise, a keyword indicating a configuration directive is looked up.

Currently supported, and potentially relevant, keywords are:

- FieldsIncluded
- IncludeFormattingCharactersLcPattern
- OtherSubfieldsExcludedByTag
- VowelMarker

Likely irrelevant keywords: 

- CreateEmpty880s
- Subfield6Code
- SubfieldsAlwaysExcluded

If no keyword is detected, proceed to transliteration.


##### `ScriptToRoman` section

The logic is the same as the `RomanToscript` section, but the configuration
keywords are different.

Currently supported, potentially relevant:

 - UppercaseFirstCharacterInSubfield [TODO verify]
 - PersonalNameHandling

 Likely irrelevant (MARC-related):

 - CreateEmptyFields
 - FieldsIncluded
 - SubfieldsAlwaysExcluded
 - OtherSubfieldsExcludedByTag

There is some code (deactivated) to dump the whole table.


#### `RomanizeConvertText`

This gets called at several points by `ReRomanizeText`.

It accepts `in`, supposedly the input text, a UTF8MarcRecordClass (probably the
transliteration table) and a UTF8CharClass (?).

It replaces `"_"` with `" "` within the transliteration table (so values with
`_` are adding spaces to the translitrated text.

It loops through the text and detects the following leaders: 

There is a `LocalMarcRecordObject.SafeStuff()` function that seems critical but
I can't seem to find a definition for it.

There is a select switch within a loop whose function is not entirely clear. Is
it to advance through sections of the text by MARC record internal markers?

```
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
```


#### `LoadRomanizationTables`

This function seems to load all the tables by calling
`LoadOneRomanizationTable` over a list of files.


#### `ReRomanizeTextDetails`

This is the logic of the romanization process by character or syllable.

- Proceed by syllable or by character based on config (note: currently there
    doesn't seem to be any cfg file containing the `BySyllables` option)
- Decide to allow case variation based on config
- Proceed scanning the text and looping; look for MARC delimiters
  - Define initial only, terminal only, medial only characters
  - Decide whether to translate R2V or V2R


#### `EvaluateFirstCharacter`

This determines if the translation is R2S or S2R. Does this work reliably and
independently of any external directive? Could there be some strings in foreign
scripts that start with Latin characters (e.g. numbers or Western terms), and
lead to unexpected results?

A (RB): Some non-Latin scripts may start with Latin characters. (SC) Let's use
an explicit direction option from the user. The logic would be too complicated
and flimsy.

(Also the translation is supposedly purpose-driven, as the user should have a
specific direction in mind and wouldn't want the software to decide for them.)


#### `ReRomanizeTextDetailsReplaceApostrophes`

Replace apostrophe characters with glyphs supported by foeign script?

Coment (RB): More clarity is needed around Latin and non-Latin punctuation to
be used. (SC): TODO More to be discussed via conf call.


#### Field- and UI-related functions

- `RomanizationAssistance`
- `FindFieldCurrentlyPointedTo`
- `RomanizationAssistanceConvertWholeRecord`
- `ReRomanizeAdjustNonfilingIndicators`
- `AddCharSetCodes2Utf8Record`
- `FindScriptByKeyPress`
- `IsFontInstalled`

These functions seem to deal with interface interaction, field/text selection,
and RTF clenaup. Probably very little to nothing needs to be carried over.

Question: do we need to keep any formatting of the original text? And if yes,
which formatting tags are allowed? (in an HTML UI the formatting could be in
HTML or Markdown, so this may need to be taken into account.)

Q: It seems like several characters are parsed and added to the text to denote
MARC markers. Do we need to deal with these manually as indicators related to
the script/language handled, or shall we expect any text string input in the
new Transliterator to be clean from MARC flags? 

A (RB): Most  MARC markers are obsolete; but there may be other  markers that
are not easily transliterated, e.g. BIBFRAME markers. More discussion is needed
on this point. (SC) Need feedback from KF + MM about what to expect from input
and output string in this regard.

#### `RomanizeConvertDecimalChars`

Convert escape sequences `&#\d{4,5}` to code points.

#### `CreateRomanizationScriptList`

Create list of romanization script options by reading a master file. This will
likely be replaced by a glob-like approach.


## General strategy for rewrite

### API endpoints

#### List available transliterations

##### Invocation

```
GET /tables
```

Returns all available transliterations, and which directions are available for
each.

##### Response

`200 OK`; body: K/V pairs of: script name, list of `r2s` (Roman to script),
`s2r` (Script to Roman), or both.

#### Transliterate a string

##### Invocation

```
POST /trans/<script>/<direction>
```

##### Query parameters
- `<script>`: script name as obtained by the `/tables` endpoint.
- `<direction>`: transliteration direction as  obtained by the `/tables`
endpoint.

##### POST body

- `data`: Input text (UTF-8) to transliterate.

##### Response

- `200 OK` if transliteration was successful; response body: transliterated
  string (UTF-8)
- `400 Bad Request` if a script name is not available in the requested
  direction; response body: details of failure.
- `500 Server Error` if an internal error occurred; response body: generic
  error message (no details about the error)

#### Reload the translation tables

Reload the tables if they have been modified. This is done internally at
server start. This should be auth-protected.

##### Invocation

`POST /reload_config`

##### Authentication

API token (probably just a hard-coded value in a .env file should suffice)

##### Response

- `204 No content` if the tables were reloaded successfully; no response body.
- `500 Server Error` on internal error.


### Functional approach

1. Upon server startup: load all translation table metadata. This is equivalent
   to invoking `reload_config` via REST API (see above) and is done by
   scanning a designated directory containing only the translation table,
   finding the metadata in the `General` section, disccovering the
   `ScriptToRoman` and `RomanToScript` sections, and storing these metadata in
   a variable available to all requests.

2. Upon invocation of the `trans` method: load the relevant configuration file
   (this operation will be cached in order to save expensive parsing) and apply
   the relevant `ScriptToRoman` or `RomanToScript` transliteration to the
   provided string.

3. Upon invocation of the `/reload_config` method: reload the table metadata
   as on startup; invalidate the cache for all the configurations.

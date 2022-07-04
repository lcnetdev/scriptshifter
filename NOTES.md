# Romanization service implementation notes

## `.cfg` files

The `.cfg` format seems to follow a INI-like syntax that is ad-hoc-parsed by
the Transliterator.

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
configuration and transliteration; if possible, vebatim copy should be
implicit, which would make maintenance easier.

It is unclear at the moment if spaces around the `=` sign are ignored.


## `ReRomanizeRecord.bas`

Much of the code deals with MARC records. No need to concern about that since
the new Transliterator is meant to convert text strings to text strings.

### Functions

#### ReRomanizeText

- Determine direction (input param): R2S or S2R
- Determine personal name handling
- Whether to uppercase first word


#### LoadOneRomanizationTable

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

If no keyword is detected, proceed to transliteration. [TODO transliteration
logic details still to be looked at]


##### `ScriptToRoman` section

The logic is the same as the `RomanToscript` section, but the configuration
keyword are different.

Currently supported, potentially relevant:

 - UppercaseFirstCharacterInSubfield [TODO verify]
 - PersonalNameHandling

 Likely irrelevant:

 - CreateEmptyFields
 - FieldsIncluded
 - SubfieldsAlwaysExcluded
 - OtherSubfieldsExcludedByTag

[TODO Complete other function analysis]

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

##### Authantication

API token (probably just a hard-coded value in a .env file should suffice)

##### Response

- `204 No content` if the tables were reloaded successfully; no response body.
- `500 Server Error` on internal error.


### Functional approach

1. Load all translation table metadata on server startup. This is equivalent
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

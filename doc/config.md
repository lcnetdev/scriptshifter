# ScriptShifter configuration file format

Language transliteration is made according to set of rules contained in static
files. Generally, each file represents one script and one language, but there
may be exception to this rule in cases of multiple languages sharing the same
script.

Configuration files, also called transliteration tables, are contained in the
[`/scriptshifter/tables/data`](../scriptshifter/tables/data) directory.

## Types of configuration files

The configuration file names are key to most operations in the software. They
are all-lowercase and use underscores to separate words, e.g.
`church_slavonic`. They have the `.yml` extension and are written in the
[YAML](https://yaml.org/) configuration language. Hence, a transliteration
request to the `/trans` REST API endpoint providing `church_slavonic` as the
transliteration language, uses the `church_slavonic.yml` configuration file.

Other files are present in the `data` directory that are not exposed to the end
user via Web UI or REST API. These files may be incomplete transliteration
tables that are used by other specific tables. An example is `_cyrillic.yml`,
which is used by `belarusian.yml`, `bulgarian.yml`, etc., but is not meant to
be used by itself. It is still accessible for transliteration however, for
testing purposes. See below for more details about inheritance.

###  Index file

In order for a transliteration option to appear in the Web interface menu or
in the `/languages` API endpoint, it must be added to the `index.yml` file.
This file contains summary information about the available languages.

The index file is a map of key-value pairs, where the keys are the
transliteration table key names as described previously, and the values are
key-value pairs which can have arbitrary contents. These contents are displayed
to the user in the `/languages` API endpoint.

The only mandatory key for each key-value pair is `name`, which is the
human-readable label that is displayed in the Web UI. Other keys, such as
`description`, may be used to inform the user about the scope of a particular
table.

## Inheritance

A configuration file may inherit rules from one or more other files.

Inheritance means that, for each section (`script_to_roman` and
`roman_to_script`) in the parent table, the child table uses all the rules
found in that section, and may add to or replace them.  This is used for
Cyrillic languages for example, which share a broad base of common characters,
but each language has its own variations on certain characters, or adds
characters that are not present in other languages.

This has the obvious advantage of avoiding repetition and copying entire tables
for just slight variations of each language.
 
 The `parent` key indicates a list of tables that the current table inherits
 from.  Inheritance is recursive, i.e. if table A inherits from B and B from C,
 table A presents the combined results of the three tables. If multiple parents
 are specified, the ones listed later override the earlier ones. The child
 values override all the parents'.

Overriding of transliteration rules is applied on the left-hand side of
the mapping. I.e., if a parent table has the following rules: 

```
  "A": "B"
  "X": "Y"
```

(which means: for each `A` in the source text, write out a `B` and for each `X`
a `Y`), and another table inherits from the above and adds: 

```
  "A": "C"
  "Z": "Y"
```

The first rule in the parent gets replaced, and the second one in the child
gets added, so that the resulting rule set becomes:

```
  "A": "C"
  "X": "Y"
  "Z": "Y"
```

Therefore, it is not critical to write exclusively rules in a parent table for
characters that are in ALL the implemented languages. Some rules may be common
to most languages, and the few exceptions can be overridden in the relevant
specific tables. It is up to the language table maintainer to decide how to
organize these rules.

Elements that are inherited in a configuration are:

- Transliteration maps (both S2R and R2S)
- Ignore lists
- Hooks [TODO]


## Configuration file structure

The following deals with understanding and authoring configuration files in
detail. The index file is treated separately in another chapter.

Each configuration file has a predefined set of sections, and each section may
have one or more subsections. All of these are optional, unless otherwise
indicated.

### `general`

Type: dictionary

Mandatory: yes

This section may include a number of descriptive metadata for the
table, including:

#### `general.name`

Type: string

Human-readable name of the table. Note that this is only for informational
purposes, and no part of the application uses this field; all human-readable
labels in the application are taken from the index file.

#### `general.notes`

Type: string

Informational field containing notes, mostly aimed at maintainers. The
application doesn't use this field. For information meant for the end  user,
use the `description` field in the index file.

#### `general.parents`

Type: list

A list of parents that the configuration inherits from. See "Inheritance"
above.

### `options`

A list of additional options that may be passed in a request. This is
useful when developing custom hooks. Any values are ignored by the core
transliteration process.

Each list member is an object is expected to contain the following keys that
are used in the built-in API:

- `id`: the option ID used as a HTML tag ID and as a variable name.
- `label`: human-readable label usable in a UI.
- `description`: description usable in a UI. Optional.
- `type`: at the moment, if this is set to `list`, a select widget shall be
  generated in the UI. An additional `options` key (see below) with the
  individual options will be required. Any other value generates a single-line
  text field.
- `options`: list of maps, each representing a selectable option in the drop-
  down menu when the type is `list`. Each list item has an `id` and a `label`
  key, used respectively as the input value and human-readable label.
- `default`: The default value that should be set for the option in a UI. Note
  that this does not set a default value in an API call [TODO].

### `roman_to_script`

Roman-to-script transliteration section. If absent, the application will raise
an error if a R2S transliteration is attempted on this language.

#### `roman_to_script.ignore`

Type: list

Ignore rules. If present, the source text will be searched for all the items
in this section before looking up a matching transliteration rule. If a match
is found, the matching part of the text is copied to the output verbatim.

Each item in the list can be a plain string or a key-value pair. If it's a plain
string, the string is compared with the source text by the number of its
characters. The comparison is case-insensitive. If it's a key value pair it can
take several forms:

- `cs: "Ignore this"`: the comparison is case-sensitive.
- `re: "Ignore th[iu]s"`: the comparison is done on a case-sensitive regular
  expression. [TODO implement]

The order in which these rules are listed is only partly relevant. The rules
will be reordered by the application when the configuration file is read, so
that:

- regular expressions are sorted before plain strings, in the order they are
  written;
- longer strings are sorted (and thus are compared) before shorter strings that
  are entirely contained in the beginning of the former (so that "BAD" comes
  before "BA" but after "AD");
- strings beginning with different characters are sorted alphabetically.


#### `roman_to_script.map`

Type: key-value pairs

Transliteration rules. Each rule takes the following form:

```
  "<source>": "<destination>"
```

Unicode code points on either side can be written using the YAML notation
(`\u????`) or the literal Unicode characters.

These rules can be written in any order, however writing longer
strings such as full names before individual phonemes and characters makes the
file more readable. The strings are sorted by the application using the same
rules dscribed above for the ignore list.

To create specific rules for initial, final, and standalone tokens, the `%`
character is used to mark the word boundary. Hence:

```
  "%token": "transliteration of token at beginning of word"
  "token%": "transliteration of token at end of word"
  "%token%": "transliteration of standalone token"
  "token": "transliteration of token anywhere else not specified"
```

The order of priority is: standalone, initial, final, and medial. As for the
other tokens, these can be in any order in the configuration and will be
reordered when the table is loaded.


#### `roman_to_script.hooks`

Type: key-value pairs

Life cycle hooks. See [hook documentation](./hooks.md) for general concepts.

Each key in this section is one of the predefined hook names and is paired with
a list of functions that shall be run when the life cycle point designated for
the hook is reached. Each function definition is a list of one or two elements.
The first is the function path including the path, relative to the
`scriptshifter.hooks` package. The second, optional element, is a map of
key-value pairs provding additional keyword arguments for the function. These
arguments are fixed for all the calls to this function made by this hook.

Thus, the following section (note the indentation):

```yaml
script_to_roman:
   # […]
   hooks:
     pre_tx_token:
       -
         - my_module.myfn
         - x: 32
           y: "hello"
```

runs the function `myfn(ctx, x=32, y="hello")` in
`scriptshifter.hooks.my_module` (`ctx` is always provided by the application)
for the `pre_tx_token` hook.

### `script_to_roman`

Script-to-Roman transliteration section. If absent, the application will raise
an error if a S2R transliteration is attempted on this language.

This section may have the `hooks` and `map` sections, that behave exactly as
described for `roman_to_script`. The `ignore` section is… ignored.

#### `script_to_roman.double_cap`

Type: list

This is only a valid subsection of S2R. It is inherited from a parent and adds
items to it.

Each item in the list indicates a group of letters that, when encountered at
the beginning of a word and slated for capitalization, are capitalized
together, rather than only the first letter. This is the case in several
ligated letter groups.

Each rule must indicate the letters together as a group, romanized, and all
lowercase. E.g. to capitalize "z︠h︡", that string must be entered verbatim. In
that case, it is capitalized as "Z︠H︡", otherwise as "Z︠h︡".

#### `script_to_roman.no_double_cap`

Type: list

This is only a valid subsection of S2R. It removes double capitalization rules
from the inherited list.

#### `script_to_roman.normalize`

Type: key-value pairs; value is a list of strings.

Normalization rules. Each key is paired with one or more tokens that are
replaced with the key before the transliteration. E.g. if we have (from the
classical Greek config):

```
normalize:
"\u03B1":  # α 	Greek Small Letter Alpha
  - "\u1F00"  # ἀ 	Greek Small Letter Alpha With Psili
  - "\u1F80"  # ᾀ 	Greek Small Letter Alpha With Psili And Ypogegrammeni
  - "\u1FB0"  # ᾰ 	Greek Small Letter Alpha With Vrachy
  - "\u1FB1"  # ᾱ 	Greek Small Letter Alpha With Macron
  - "\u1FB3"  # ᾳ 	Greek Small Letter Alpha With Ypogegrammeni
```

then all ἀ, ᾀ, ᾰ, etc. are normalized to α; only this last token needs to be
mapped for transliteration.

This section is only available for S2R at the moment. It is inherited by
child configurations.

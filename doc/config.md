# Transliterator configuration file format

Language transliteration is made according to set of rules contained in static
files. Generally, each file represents one script and one language, but there
may be exception to this rule in cases of multiple languages sharing the same
script.

Configuration files, also called transliteration tables, are contained in the
[`/transliterator/tables/data`](../transliterator/tables/data) directory.

## Types of configuration files

The configuration file names are key to most operations in the software. They
are all-lowercase and use underscores to separate words, e.g.
`church_slavonic`. They have the `.yml` extension and are written in the
[YAML](https://yaml.org/) configuration language. Hence, a transliteration
request to the REST API endpoint `/trans/church_slavonic` uses the
`church_slavonic.yml` configuration file.

In order for a transliteration option to appear in the Web interface menu or
in the `/languages` API endpoint, it must be added to the `index.yml` file.
This file contains summary information about the available languages.

Other files are present in the `data` directory that are not exposed to the end
user via Web UI or REST API. These files may be incomplete transliteration
tables that are used by other specific tables. An example is `_cyrillic.yml`,
which is used by `belarusian.yml`, `bulgarian.yml`, etc., but is not meant to
be used by itself. It is still accessible for transliteration however, for
testing purposes. See below for more details about inhritance.

## Inheritance

A configuration file may inherit rules from another file. Currently, only one
level of inheritance is allowed (i.e. a table can only inherit from another
table, and no further lookup is done if the other table inherits from yet
another one).

Inheritance means that, for each section (`script_to_roman` and
`roman_to_script`) in the parent table, the child table uses all the rule
found in that section, and may add to or replace them.  This is used for
Cyrillic languages for example, which share a broad base of common characters,
but each language has its own variations on certain characters, or adds
characters that are not present in other languages.

This has the obvious advantage of avoiding repetition and copying entire tables
for just slight variations of each language.

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

Thus, it is not critical to write exclusively rules in a parent table for
characters that are in ALL the implemented languages. Some rules may be common
to most languages, and the few exceptions can be overridden in the relevant
specific tables. It is up to the language table maintainer to decide how to
organize these rules.


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
- `re: "Ignore th[iu]s": the comparison is done on a case-sensitive regular
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

Unicode code points on either side are written using the YAML notation:
`\u????`

These rules can be written in any order, however writing longer
strings such as full names before individual phonemes and characters makes the
file more readable. The strings are sorted by the application using the same
rules dscribed above for the ignore list.


#### `roman_to_script.hooks`

Type: key-value pairs

Life cycle hooks. See [`hooks.md`](./hooks.md) for general concepts.

Each key in this section is one of the predefined hook names and is paired with
a list of functions that shall be run when the life cycle point designated for
the hook is reached. Each function definition is a list of one or two elements.
The first is the function path including the path, relative to the
`transliterator.hooks` package. The second, optional element, is a map of
key-value pairs provding additional keyword arguments for the function. These
arguments are fixed for all the calls to this function within this hook.

Thus, the following section:

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
`transliterator.hooks.my_module` (`ctx` is always provided by the application)
for the `pre_tx_token` hook.

### `script_to_roman`

Script-to-Roman transliteration section. If absent, the application will raise
an error if a S2R transliteration is attempted on this language.

This section may have the `hooks` and `map` sections, that behave exactly as
described for `roman_to_script`. The `ignore` section is… ignored.


##  Index file

The index file is a map of key-vlue pairs, where the keys are the
transliteration table key names as described previously, and the values are
key-value pairs which can have arbitrary contents. These contents are displayed
to the user in the `/languages` API endpoint.

The only mandatory key for each key-value pair is `name`, which is the
human-readable label that is displayed in the Web UI. Other keys, such as
`description`, may be used to inform the user about the scope of a particular
table.

# Transliterator life cycle hooks

This is a guide for language specialists with some Python development skills,
or who can partner with Python developers to create new, complex
transliteration features.

This software strives to become a universal transliteration tool; however, the
challenge of such goal is that some scripts have very complex, specific
rules that, if implemented in a generic tool, would quickly make its code
unmanageable.

The solution we propose in this tool is to keep its core functionality simple,
yet versatile enough to work with the vast majority of scripts; and to enable
script- or language-specific extensions that can be managd by subject matter
experts so that it's easy to isolate those specific features.

This is implemented life cycle hooks, which are "ports" where additional logic
can be executed to change the outcome of a transliteration at certain stages
of the process.


## Overview of the transliteration process

In order to understand how hooks work, it is necessary to understand the logic
underpinning the transliteration process.

When a transliteration request is sent to the application, the following
happens:

1. A configuration is read and parsed for the script/language specified. This
   is actually only done once, the first time that that language is used since
   the application was (re)started. If a configuration is changed, the
   application must be restarted in order for it to parse the updated rules.
   See [`config.md`](./config.md) for a complete guide on the configuration
   structure.
   a. If the table is designated as inheriting another table (e.g. `russian`
      inheriting the `_cyrillic_base` table), the parent's tokens in the `map`
      sections under `roman_to_script` and/or `script_to_roman` are first read
      and then te present table's tokens are merged onto them. If a key is
      present in both tables, the "child" table token overrides the parent. The
      same thing happens with the "ignore" list in the `roman_to_script`
      section.
   b. Each of the tokens are rearranged so that longer tokens are
      sorted before shorter ones that are completely contained in the beginning
      part of the former. E.g. a list of tokens such as `['A', 'B', 'AB',
      'BCD', 'ABCD', 'BCDE', 'BEFGH']` (showing only keys here) becomes
      `['ABCD', 'AB', 'A', 'BCDE', 'BCD', 'BEFGH', 'B']`. This is critical to
      ensure that specific word definitions are parsed in their entirety before
      they are transliterated. Hence, the Hanzi sequence "北京" is correctly
      interpreted as "Beijing" instead of "bei jing".
2. Once the transliteration rules are loaded, the application proceeds to
   scanning the input text. The application initializes an empty list, which
   shall contain the parsed tokens, and starts a loop that advances a cursor,
   which represents the reading position starting at 0 (the beginning of the
   text).
3. For Roman-to-script transliteration, tokens in the `ignore` list are first
   compared against the text at the cursor position. The amount of
   characters compared is equal to the length of each token in the ignore list.
   a. If there is a match, the matching token is added to the output list and
      the cursor advanced by the number of characters in the token.
   b. If all ignore tokens are scanned and there is no match, the application
      proceeds with the next step at the same cursor position.
4. Tokens in the relevant `map` of the transliteration table are compared, one
   by one in the order established in 1.b, with the string at the cursor
   position. The amount of characters compared is equal to the length of the
   token.
   a. If there is a match, the transliteration indicated in the token is added
      to the output list, and the cursor advanced by the number of characters
      in the token.
   b. If there is no match, the next token is tried. If all the tokens have
      been tried and still no match results, the single character at the
      current position is added verbatim to the output list, and the cursor
      advances by one position.
5. When the end of the input text is reached, if the configuration indicates
   that capitalization is required (this is true by default), te first element
   of the output list is capitalized.
6. The output list is joined into one string.
7. The string is compacted by removing excessive whitespace: Two or more
   contiguous spaces are collapsed into one, and whitespace is stripped off
   both ends of the text.
8. The output string is returned.


## Hooks

Hooks are entry points for arbitrary code that may be added to change the
transliteration behavior at specific point of the process described above.
Each of the hooks may indicate the name of a function and optional, additional
paramters.

Hook functions may be defined for each language/script in the corresponding
configuration file. See [`config.md`](./config.md) for details.

The function name takes the form of `<module name>/<function name>` and must
correspond to an existing module and function under the `transliterator.hooks`
package.

Each hook requires input parameters that are specific to its context, and are
passed to the corresponding hook function(s) by the internal process. They must
be defined in each function associated with the hook. Hooks may also accept
optional keyword-only arguments, as described below, whose values can be
defined in the configuration.

Each function must also return an output that the process is able to handle as
expected. These are also defined below.

**[TODO]** These hooks are being implemented in a vacuum, without much of a
real-world use case. Modifications to these capabilities may change as actual
challenges arise.

### `post_config`

This hook is run after the whole configuration is parsed and possibly merged
with a parent configuration.

This hook is run once with the configuration parsing.

#### Input parameters

- `config` (dict): The parsed configuration data structure.
- `**kwargs`: Additional arguments that may be defined in the configuration.

#### Output

(dict) Configuration data structure.

### `begin_input_token`

This hook is run at the beginning of each iteration of the input parsing loop.

#### Input parameters

- `input` (str): the whole input text.
- `cursor` (int): cursor position.
- `ouptut` (list): Output list in its current state.
- `**kwargs`: Additional arguments that may be defined in the configuration.

#### Output

(int) Cursor position.

### `pre_ignore_token`

Run before each ignore token is compared with the input.

#### Input parameters

- `input` (str): the whole input text.
- `cursor` (int): cursor position.
- `token` (str): Current ignore token.
- `**kwargs`: Additional arguments that may be defined in the configuration.

#### Output

(int) Cursor position.

### `on_ignore_match`

Run when an ignore token matches.

TODO

### `pre_tx_token`

Run before comparing each transliteration token with the current text.

TODO

### `on_tx_token_match`

Run when a transliteration token matches the input.

TODO

### `on_no_tx_token_match`

Run after all tokens for the current position have been tried and no match has
been found. If defined, this **replaces** the default behavior of copying the
character to the output.

TODO

### `pre_assembly`

Run after the whole text has been scanned, before the output list is
capitalized and assembled into a string.

TODO

### `post_assembly`

Run after the output has been assembled into a string, before whitespace is
stripped off.

TODO

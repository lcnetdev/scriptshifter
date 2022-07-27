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

Each hook requires some arguments to be defined in each function associated
with it: `ctx`, an instance of `transliterator.trans.Context` which carries
information about the current scanner status and can be manipulated by the hook
function; and `**kw`, optional keyword-only arguments, whose values can be
defined in the configuration.

Each function must also return an output that the process is able to handle as
expected. the output may instruct the application to make a specific decision
after the hook function is executed. Possible return values are defined below
for each hook.

**[TODO]** These hooks are being implemented in a vacuum, without much of a
real-world use case. Modifications to these capabilities may change as actual
challenges arise.

### `post_config`

This hook is run after the whole configuration is parsed and possibly merged
with a parent configuration.

#### Return

`None`.

### `begin_input_token`

This hook is run at the beginning of each iteration of the input parsing loop.

#### Return

(str | None) Possible values are `"cont"`, `"break"`, or `None`. If `None` is
returned, the parsing proceeds as normal. `"cont"` causes the application to
skip the parsing of the current token. `"break"` interrupts the text scanning
and proceeds directly to handling the result list for output. **CAUTION**: when
returning "cont", it is the responsibility of the function to advance `ctx.cur`
so that the loop doesn't become an infinite one. 

### `pre_ignore_token`

Run before each ignore token is compared with the input.

#### Output

(str | None) `"cont"`, `"break"`, or `None`. `"cont"` skips the checks on the
current ignore token. `"break"` stops looking up ignore tokens for the current
position. This function can return `"cont"` without advancing the cursor and
without causing an infinite loop.

### `on_ignore_match`

Run when an ignore token matches.

#### Output

(str | None) `"cont"`, `"break"`, or `None`. `"cont"` voids the match and keeps
on looking up the ignore list. `"break"` stops looking up ignore tokens for the
current position. See cautionary note on `begin_input_token`.

### `pre_tx_token`

Run before comparing each transliteration token with the current text.

#### Output

(str | None) `"cont"`, `"break"`, or `None`. `"cont"` skips the checks on the
current token. `"break"` stops looking up all tokens for the current
position. See cautionary note on `begin_input_token`.

### `on_tx_token_match`

Run when a transliteration token matches the input.

#### Output

(str | None) `"cont"`, `"break"`, or `None`. `"cont"` voids the match and keeps
on looking up the token list. `"break"` stops looking up tokens for the
current position and effectively reports a non-match.

### `on_no_tx_token_match`

Run after all tokens for the current position have been tried and no match has
been found.

#### Output

(str | None) `"cont"`, `"break"`, or `None`. `"cont"` skips to the next
position in the input text. Int his case, the function **must** advance the
cursor. `"break"` stops all text parsing and proceeds to the assembly of the
output.

### `pre_assembly`

Run after the whole text has been scanned, before the output list is
capitalized and assembled into a string. This function may manipulate the token
list and/or handle the assembly itself, in which case it can return the
assembled string and bypass any further output handling.

#### Output

(str | None) If the output is a string, the transliteration function returns
this string immediately; otherwise it proceeds with standard adjustments and
assembly of the output list.

### `post_assembly`

Run after the output has been assembled into a string, before whitespace is
stripped off. This function can access and manipulate `ctx.dest` which is
the output string.

#### Output

(str | None) If the output is a string, the transliteration function returns
this string immediately; otherwise it proceeds with standard adjustments of the
output string.

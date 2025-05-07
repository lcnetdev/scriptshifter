# ScriptShifter life cycle hooks

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

This is implemented by using life cycle hooks, which are "ports" into the
transliteration workflow where additional logic can be executed to change the
outcome of a transliteration at certain stages of the process.


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
4. Tokens in the relevant `map` section of the transliteration table are
   compared, one by one in the order established in 1.b, with the string at the
   cursor position. The amount of characters compared is equal to the length of
   the token.

   a. If there is a match, the transliteration indicated in the token is added
      to the output list, and the cursor advanced by the number of characters
      in the token.

   b. If there is no match, the next token is tried. If all the tokens have
      been tried and still no match results, the single character at the
      current position is added verbatim to the output list, and the cursor
      advances by one position.
5. When the end of the input text is reached, if the configuration indicates
   that capitalization is required (this is true by default), the first element
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

The function name takes the form of `<module name>.<function name>` and must
correspond to an existing module and function under the `scriptshifter.hooks`
package. Check the [`rot3.yml`](../tests/data/rot3.yml) test
configuration and the referred functions for a working example.

Each hook requires some arguments to be defined in each function associated
with it: `ctx`, an instance of `scriptshifter.trans.Context` which carries
information about the current scanner status and can be manipulated by the hook
function; and `**kw`, optional keyword-only arguments, whose values can be
defined in the configuration.

Each function must also return an output that the process is able to handle as
expected. the output may instruct the application to make a specific decision
after the hook function is executed. Possible return values are defined below
for each hook. Some special return values, such as `BREAK` and `CONT`, are
registered as constants under `scriptshifter.exceptions`.

### Note on running multiple functions on a hook

Currently, if multiple functions are defined for a hook, they are executed
in the order specified in the configuration. There is no way to skip a function
implicitly based on the outcome of the previous one. The only state that is
passed around in this context, is the `ctx` instance of the `Transliterator`
class. This may change in the future as specific needs arise. 


### Always available context members

The following members of the context object are available in all the hooks:

- `ctx.src`: Source text. Read only.
- `ctx.general`: Configuration general options.
- `ctx.langsec`: language section (S2R or R2S) of configuration.
- `ctx.options`: language-specific options defined in configuration and set
    at the beginning of the request.
- `ctx.warnings`: list of warnings issued during the process. They will be
  output in the return value of the `transliterate()` function. Normally
  this function does not return an error if a malformed string was provided;
  rather, it may return an empty string and some warnings about the issues
  found with the input.

Other members are available in different hooks. See the individual hooks
reference below.

### `post_config`

This hook is run after the whole configuration is parsed and possibly merged
with a parent configuration.

This hook can be used to completely override the transliteration process by
devising an entirely different logic and/or calling a third party library
or REST API.

#### Available context members

- `ctx.cur`: cursor position. It should be 0 at this point.
- `ctx.dest_ls`: destination token list. It should be empty at this point.

#### Return

`None` or `BREAK`. In the former case the application proceeds to the usual
transliteration process; in the latter case, it returns the value of
`ctx.dest`, which the hook function should have set.

### `begin_input_token`

This hook is run at the beginning of each iteration of the input parsing loop.

Functions implemented here can be used to override the default behavior for
each iteration of the input text scan, e.g. when special conditions must be
applied to detect word boundaries or punctuation, or handling the interaction
of multiple symbols based on logical rules rather than a dictionary.

#### Available context members

- `ctx.cur`: cursor position.
- `ctx.cur_flags`: flags associated with the current position. They are reset
  at every character iteration. See "Cursor Flags" below.
- `ctx.dest_ls`: destination token list.

#### Return

Possible values are `CONT`, `BREAK`, or `None`. If `None` is returned,
the parsing proceeds as normal. `CONT` causes the application to skip the
parsing of the current token. `BREAK` interrupts the text scanning and
proceeds directly to handling the result list for output. **CAUTION**: when
returning CONT, it is the responsibility of the function to advance
`ctx.cur` so that the loop doesn't become an infinite one. 

### `pre_ignore_token`

Run before each ignore token is compared with the input.

Functions implementing this hook can change the behavior for detecting an
ignore term and when or when not to trigger a match.

#### Available context members

- `ctx.cur`: cursor position.
- `ctx.cur_flags`: flags associated with the current position. They are reset
  at every character iteration. See "Cursor Flags" below.
- `ctx.dest_ls`: destination token list.

#### Return

`CONT`, `BREAK`, or `None`. `CONT` skips the checks on the
current ignore token. `BREAK` stops looking up ignore tokens for the current
position. This function can return `CONT` without advancing the cursor and
without causing an infinite loop.

### `on_ignore_match`

Run when an ignore token matches.

Functions implementing this hook can change the behavior of the process after
an ignore token has matched. Actions may include skipping or redefining the
ignore step, which by default copies the matching token verbatim and keeps
scanning for more ignore tokens past the match.

#### Available context members

- `ctx.cur`: cursor position.
- `ctx.cur_flags`: flags associated with the current position. They are reset
  at every character iteration. See "Cursor Flags" below.
- `ctx.dest_ls`: destination token list.
- `ctx.tk`: matching ignore token.
- `ctx.ignoring`: whether an ignore token matched. If set to `False`, the rest
  of the workflow will assume a non-match.

#### Return

`CONT`, `BREAK`, or `None`. `CONT` voids the match and keeps
on looking up the ignore list. `BREAK` stops looking up ignore tokens for the
current position. See cautionary note on `begin_input_token`.

### `pre_tx_token`

Run before comparing each transliteration token with the current text.

Functions implementing this hook can change the behavior of how a character is
matched, e.g. by injecting additional conditions based on logical rules, which
may take a broader context into consideration. They may also take over the
substitution step for the current position, skip the scanning for an arbitrary
number of characters, and/or exit the text scanning loop altogether.

#### Available context members

- `ctx.cur`: cursor position.
- `ctx.cur_flags`: flags associated with the current position. They are reset
  at every character iteration. See "Cursor Flags" below.
- `ctx.dest_ls`: destination token list.
- `ctx.src_tk`: the input token being looked up.
- `ctx.dest_tk`: the transliterated string associated with the current token.

#### Return

`CONT`, `BREAK`, or `None`. `CONT` skips the checks on the
current token. `BREAK` stops looking up all tokens for the current
position. See cautionary note on `begin_input_token`.

### `on_tx_token_match`

Run when a transliteration token matches the input.

Functions implementing this hook can override how the transliterated
character(s) are added to the result token list once a match is found. They can
also inject additional conditions and logic for the match, and revoke the
"match" status, which would prevent the transliteration step from running.

#### Available context members

- `ctx.cur`: cursor position.
- `ctx.cur_flags`: flags associated with the current position. They are reset
  at every character iteration. See "Cursor Flags" below.
- `ctx.dest_ls`: destination token list. The matching token will be added to it
  after this hook is run.
- `ctx.src_tk`: the matching input token.
- `ctx.dest_tk`: the transliterated string to be added to the output.
- `ctx.match`: whether there was a match. If set to `False`, the rest of the
  workflow will assume a non-match.

#### Return

`CONT`, `BREAK`, or `None`. `CONT` voids the match and keeps
on looking up the token list. `BREAK` stops looking up tokens for the
current position and effectively reports a non-match.

### `on_no_tx_token_match`

Run after all tokens for the current position have been tried and no match has
been found.

Functions implementing this hook can perform additional actions after the
current position has not been matched by any of the available tokens. They can
also override the default logic which is adding the single character at the
cursor position to the destination list, verbatim.

#### Available context members

- `ctx.cur`: cursor position.
- `ctx.cur_flags`: flags associated with the current position. They are reset
  at every character iteration. See "Cursor Flags" below.
- `ctx.dest_ls`: destination token list.

#### Return

`CONT`, `BREAK`, or `None`. `CONT` skips to the next position in the input
text. Int his case, the function **must** advance the cursor. `BREAK` stops all
text parsing and proceeds to the assembly of the output.

### `pre_assembly`

Run after the whole text has been scanned, before the output list is
capitalized and assembled into a string.

Functions implementing this hook can manipulate the token list and/or handle
the assembly itself, in which case they can return the assembled string and
bypass any further output handling.

#### Available context members

- `ctx.dest_ls`: destination token list.

#### Return

`BREAK` or `None`. If `BREAK`, the content of `ctx.dest`, which should be set
by the function, is returned immediately; otherwise it proceeds with standard
adjustments and assembly of the output list.

### `post_assembly`

Run after the output has been assembled into a string, before whitespace is
stripped off.

Functions implementing this hook can manipulate and reassign the output string,
and return it before any further default processing is done.

#### Available context members

- `ctx.cur`: cursor position.
- `ctx.dest_ls`: destination token list.
- `ctx.dest`: output string.

#### Output

`BREAK` or `None`. If `BREAK`, the transliteration function returns the content
of `ctx.dest` immediately; otherwise it proceeds with standard adjustments of
the output string before returning.

## Cursor flags

At certain points of the processing, some boolean flags are associated with
the current cursor position. These flags are available under `ctx.cur_flags`.
The following flags are currently supported:

- `CUR_BOW`: Beginning of word.
- `CUR_EOW`: End of word.

The beginning and end of word flags are useful for hooks to manipulate the
transliteration where letters take different shapes based on their position
within a word. Either, both, or neither flag may be set at any position. If
both are set, the letter is standalone. If neither is set, the letter is
medial.

# ScriptShifter REST API

## `GET /health`

Useful endpoint for health checks.

### Response code

`200 OK` if the service is running.

## `GET /languages`

List all the languages supported.

### Response code

`200 OK`

### Response body

MIME type: `application/json`

Content: a JSON object of the supported language tables. Keys are the keywords
used throughout the API, e.g. for `/transliterate`. Each key is paired with an
object that contains some basic metadata about the language features. At the
moment, only the human-readable name is available.

## `GET /table/<lang>`

Dump a language table.

### URI parameters

- `<lang>`: Language code as given by the `/languages` endpoint. 

### Response code

`200 OK`

### Response body

MIME type: `application/json`

Content: language configuration as a JSON object with all the transliteration
rules as they are read by the application. If the table inherits from a parent,
the computed values from the merged tables are shown.

## `GET /options/<lang>`

Get options available for a script.

### URI parameters

- `<lang>`: Language code as given by the `/languages` endpoint. 

### Response code

`200 OK`

### Response body

MIME type: `application/json`

Content: list of options as a JSON object.

## `POST /trans`

Transliterate an input string into a given language.

### POST body

MIME type: `application/json`

Content: JSON object with the following keys:

- `lang`: Language code as given by the `/languages` endpoint.
- `text`: Input text to be transliterated.
- `capitalize`: One of `first` (capitalize the first letter of the input),
  `all` (capitalize all words separated by spaces), or null (default: apply no
  additional capitalization). All options leave any existing capitalization
  unchanged.
- `t_dir`: Direction of the transliteration or transcription: either `s2r`
  (default: script to Roman) or `r2s` (Roman to script).

### Response code

- `200 OK` on successful operation.
- `400 Bad Request` for an invalid request. The reason for the failure is
  normally printed in the response body.

### Response body

MIME Type: `application/json`

Content: JSON object containing two keys: `ouput` containing the transliterated
string; and `warnings` containing a list of warnings. Characters not found in
the mapping are copied verbatim in the transliterated string (see
"Configuration files" section for more information).

## `POST /feedback`

Send a feedback form about a transliteration result.

### POST body

MIME type: `application/json`

Content: JSON object with the following keys:

    `lang`: language of the transliteration. Mandatory.
    `src`: source text. Mandatory.
    `t_dir`: transliteration direction. If omitted, it defaults to `s2r`.
    `result`: result of the transliteration. Mandatory.
    `expected`: expected result. Mandatory.
    `options`: options passed to the request, if any.
    `notes`: optional user notes.
    `contact`: contact email for feedback. Optional.

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

## `POST /transliterate/<lang>[/r2s]`

Transliterate an input string in a given language.

### URI parameters

- `<lang>`: Language code as given by the `/languages` endpoint. 
- `r2s`: if appended to the URI, the transliteration is intended to be
  Roman-to-script, and the input string should be Latin text. If not, the
  default behavior is followed, which is interpreting the input as a script
  in the given language, and returning the Romanized text.

### POST body

- `text`: Input text to be transliterated.

### Response code

- `200 OK` on successful operation.
- `400 Bad Request` for an invalid request. The reason for the failure is
  normally printed in the response body.

### Response body

MIME Type: `text/plain`

Content: transliterated string. Characters not found in the mapping are copied
verbatim (see "Configuration files" section for more information).

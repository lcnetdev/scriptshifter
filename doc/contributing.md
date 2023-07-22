# Contributing to ScriptShifter

All contributions to ScriptShifter are done via the Git repository at
https://github.com/lcnetdev/scriptshifter.

Most scripts can be handled simply via editing script tables, which does not
require any programming skills, but requires an understanding of how the
tables are laid out.

## Contributing to the transliteration & transcription tables

For non-developers who want to improve, fix issues, or add whole new script
tables:

- You need a Github account to perform any edits to the code.
- Read the [configuration documentation](./config.md) first, which should
  provide the necessary understanding of ScriptShifter tables.
- Open a new issue by clicking the "New issue" button in
  https://github.com/lcnetdev/scriptshifter/issues. Describe clearly and
  concisely the need for the changes you want to commit. IMPORTANT: if you have
  multiple items to resolve, such as more than one major area of a script or
  multiple scripts, open one issue for each, and commit one set of changes per
  issue.
- If you are modifying an existing table, navigate on Github to the table in
  question in the [data folder](../scriptshifter/tables/data) while logged into
  Github, and click on the pencil button on the right on top of the code to
  edit the file in place.
- You can perform as many edits as you like within a branch. Just keep adding
  until you are satisfied. Just remember to keep the scope of the PR specific
  to the one issue you are resolving.
- Once you are done editing, click the green "Commit changes" button. This will
  open a form window.
- If you are changing rules in a script table, or adding a whole new table,
  please add sample strings to the test table (see detailed instructions
  below).
- Replace the generic commit message with an informative message about what you
  did. Please be concise and clear. In the "Extended description" field, enter
  `Fixes #<issue ID>`, where `<issue ID>` is the identifier of the issue you
  opened earlier (it shows in the title).
- From the radio button at the bottom, select "create a new branch" if not
  already selected. Leave the provided branch name if you can't come up with a
  better one.
- Confirm creating the branch and opening a pull request (PR), which is a
  request to merge your changes into the main branch (the one that runs on the
  live service).
- (Note: the steps up to here may be achieved by different means if you are
  familiar with code editors and Git).
- Go to your pull request in the [PR
  page](https://github.com/lcnetdev/scriptshifter/pulls) and request a review
  from at least one of `@thisismattmiller`, `@kefo`, or `@scossu`. The pull
  request will be reviewed and may be accepted, or sent back to you for edits
  (normally with clear indications of what needs to be changed).
- If you are requested edits, keep adding edits to the same PR and re-request a
  review when you think you satisfied your reviewers' comments.
- After the request is approved, you can merge it into the main branch using
  the button present in the PR page, if someone hasn't done that already.
- At this point, your job is done, but the code must still be deployed to the
  live service. Please coordinate with the repository managers (Matt or Kevin)
  if you don't see your changes reflected in Marva within a day or two.


## Adding test strings

Adding strings to the [test table](../tests/data/sample_strings.csv) is the
single most important thing to do, after your contribution, to keep
ScriptShifter free from error and well-maintained. This table is used as a
source of test strings by the automated tests that run before deploying a new
version of ScriptShifter.

If you modify in any way rules in a table (almost certainly), or even add a
whole new script table, you will want to verify that your changes work as
intended.

The test table is a CSV file, which you can download from Github and open with
a spreadsheet editor such as LibreOffice or Excel. Only the first four columns
are mandatory and used by the automated tests, the others are for annotation
purposes. Add brief and self-contained strings as the ones already present in
the table, covering a wide range of cases and in particular, complex and
ambiguous cases. Enter one line per test string, repeating the language,
script, and table key values. It is important to add the table key on column C,
because without that, tests won't run for that script.

If you edited the file with a spreadsheet editor, make sure you export the
file as CSV (and not as Excel or LibreOffice). Then, go back to the branch that
you opened your PR on, navigate to the original file, and replace the file with
your CSV.

You can (and should) perform these edit within the same PR in which you are
making changes to the same script. You can also create a new PR just to add
more test strings, which is a wonderful thing to do.

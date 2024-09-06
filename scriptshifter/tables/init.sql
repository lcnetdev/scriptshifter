/*
 * Master language table.
 *
 * Overview of languages available in Scriptshifter.
 */
CREATE TABLE tbl_language (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE,
    label TEXT,
    marc_code TEXT,
    description TEXT,
    features TINYINT DEFAULT 0
);

/*
 * Transliteration maps.
 *
 * Each row is a S2R or R2S pair associated with a language ID.
 */
CREATE TABLE tbl_trans_map (
    id INTEGER PRIMARY KEY,
    lang_id INTEGER NOT NULL,
    dir TINYINT NOT NULL DEFAULT 0,  /* 1 = S2R; 2 = R2S */
    src TEXT NOT NULL,
    dest TEXT,
    sort INT NOT NULL,  /* Smaller values have higher priority. */

    FOREIGN KEY (lang_id) REFERENCES tbl_language(id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX idx_trans_lookup ON tbl_trans_map (lang_id, dir, src);
CREATE INDEX idx_trans_map_sort ON tbl_trans_map (sort ASC);

/*
 * Processing hooks.
 *
 * Note that multiple functions may be grouped under the same hook, lang, and
 * direction. These are ordered by `sort`.
 */
CREATE TABLE tbl_hook (
    id INTEGER PRIMARY KEY,
    lang_id INTEGER NOT NULL,
    dir TINYINT NOT NULL DEFAULT 0,  /* 1 = S2R; 2 = R2S */
    name TEXT NOT NULL, /* Hook name. */
    sort INT NOT NULL,  /* Function sorting order within the hook. */
    module TEXT NOT NULL, /* Module name. */
    fn TEXT NOT NULL,   /* Function name. */
    kwargs TEXT,        /* KW arguments as JSON blob. */

    FOREIGN KEY (lang_id) REFERENCES tbl_language(id) ON DELETE CASCADE
);
CREATE INDEX idx_hook_lookup ON tbl_hook (lang_id, dir);
CREATE INDEX idx_hookname_lookup ON tbl_hook (name);
CREATE INDEX idx_hook_sort ON tbl_hook (sort ASC);

/*
 * Ignore lists for R2S.
 */
CREATE TABLE tbl_ignore (
    id INTEGER PRIMARY KEY,
    lang_id INTEGER NOT NULL,
    rule TEXT NOT NULL,
    features TINYINT,  /* 1 = case insensitive; 2 = regular expression. */

    FOREIGN KEY (lang_id) REFERENCES tbl_language(id) ON DELETE CASCADE
);

/*
 * Double capitals.
 */
CREATE TABLE tbl_double_cap (
    id INTEGER PRIMARY KEY,
    lang_id INTEGER NOT NULL,
    rule TEXT NOT NULL,

    FOREIGN KEY (lang_id) REFERENCES tbl_language(id) ON DELETE CASCADE
);

/*
 * Normalization rules.
 */
CREATE TABLE tbl_normalize (
    id INTEGER PRIMARY KEY,
    lang_id INTEGER NOT NULL,
    src TEXT NOT NULL,
    dest TEXT NOT NULL,

    FOREIGN KEY (lang_id) REFERENCES tbl_language(id) ON DELETE CASCADE
);

/*
 * Input options.
 */
CREATE TABLE tbl_option (
    id INTEGER PRIMARY KEY,
    lang_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    label TEXT NOT NULL,
    description TEXT,
    dtype TEXT,
    options TEXT,
    default_v TEXT,

    FOREIGN KEY (lang_id) REFERENCES tbl_language(id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX idx_option_lookup ON tbl_option (lang_id, name);



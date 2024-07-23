/*
 * Master language table.
 *
 * Overview of languages available in Scriptshifter.
 */
CREATE TABLE tbl_language (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE,
    label TEXT,
    marc_code TEXT NULL,
    description TEXT NULL,
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
    src TEXT NOT NULL UNIQUE,
    dest TEXT,

    FOREIGN KEY (lang_id) REFERENCES tbl_language.id ON DELETE CASCADE
);
CREATE_INDEX trans_lookup ON tbl_trans_map (lang_id, dir, src);

/*
 * Processing hooks.
 */
CREATE TABLE tbl_hook (
    id INTEGER PRIMARY KEY,
    lang_id INTEGER NOT NULL,
    dir TINYINT NOT NULL DEFAULT 0,  /* 1 = S2R; 2 = R2S */
    name TEXT NOT NULL,  /* Hook name. */
    order INT NOT NULL,  /* Function sorting order within the hook. */
    fn TEXT NOT NULL,   /* Function name. */
    signature TEXT,     /* Arguments as JSON blob. */

    FOREIGN KEY (lang_id) REFERENCES tbl_language.id ON DELETE CASCADE
);
CREATE INDEX hook_lookup ON tbl_hook (lang_id, dir);
CREATE INDEX hookname_lookup ON tbl_hook (name);
CREATE INDEX hook_order ON tbl_hook (order ASC);

/*
 * Ignore lists for R2S.
 */
CREATE TABLE tbl_ignore (
    id INTEGER PRIMARY KEY,
    lang_id INTEGER NOT NULL,
    rule TEXT NOT NULL,
    features TINYINT,  /* 1 = case insensitive; 2 = regular expression. */

    FOREIGN KEY (lang_id) REFERENCES tbl_language.id ON DELETE CASCADE
);

/*
 * Double capitals.
 */
CREATE TABLE tbl_double_cap (
    id INTEGER PRIMARY KEY,
    lang_id INTEGER NOT NULL,
    rule TEXT NOT NULL,

    FOREIGN KEY (lang_id) REFERENCES tbl_language.id ON DELETE CASCADE
);

/*
 * Normalization rules.
 */
CREATE TABLE tbl_norm (
    id INTEGER PRIMARY KEY,
    lang_id INTEGER NOT NULL,
    src TEXT NOT NULL,
    dest TEXT NOT NULL,

    FOREIGN KEY (lang_id) REFERENCES tbl_language.id ON DELETE CASCADE
);

/*
 * Input options.
 */
CREATE TABLE tbl_option (
    id INTEGER PRIMARY KEY,
    lang_id INTEGER NOT NULL,
    name TEXT UNIQUE,
    description TEXT NULL,
    type TEXT,
    default TEXT NULL,

    FOREIGN KEY (lang_id) REFERENCES tbl_language.id ON DELETE CASCADE
);



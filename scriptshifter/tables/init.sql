/*
 * Master language table.
 *
 * Overview of languages available in Scriptshifter.
 */
CREATE TABLE tbl_language (
    id INTEGER PRIMARY KEY,
    name VARCHAR UNIQUE,
    label VARCHAR,
    description VARCHAR NULL,
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

/*
 * Processing hooks.
 */
CREATE TABLE tbl_hook (
    id INTEGER PRIMARY KEY,
    lang_id INTEGER NOT NULL,
    dir TINYINT NOT NULL DEFAULT 0,  /* 1 = S2R; 2 = R2S */
    hook TEXT NOT NULL,  /* Hook name. */
    order INT NOT NULL,  /* Function sorting order within the hook. */
    fn TEXT NOT NULL,   /* Function name. */
    signature TEXT,     /* Arguments as JSON blob. */

    FOREIGN KEY (lang_id) REFERENCES tbl_language.id ON DELETE CASCADE
);

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
 * Normalization rules.
 */
CREATE TABLE tbl_norm (
    id INTEGER PRIMARY KEY,
    lang_id INTEGER NOT NULL,
    src TEXT NOT NULL,
    dest TEXT NOT NULL,

    FOREIGN KEY (lang_id) REFERENCES tbl_language.id ON DELETE CASCADE
);


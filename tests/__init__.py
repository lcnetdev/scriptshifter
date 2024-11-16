from csv import reader
from difflib import ndiff
from glob import glob
from importlib import reload
from json import loads as jloads
from logging import getLogger
from os import environ, path

from scriptshifter.trans import transliterate


TEST_DIR = path.dirname(path.realpath(__file__))
TEST_DATA_DIR = path.join(TEST_DIR, "data")

logger = getLogger(__name__)


def reload_tables():
    if "TXL_CONFIG_TABLE_DIR" in environ:
        del environ["TXL_CONFIG_TABLE_DIR"]

    # import here to set modified test config dir.
    from scriptshifter import tables

    tables.init_db()

    for fname in glob(path.join(TEST_DATA_DIR, "config", ".yml")):
        tname = path.splitext(path.basename(filename))[1]
        with tables.get_connection() as conn:
            tables.populate_table(conn, tname, {"name": fname})


    tables.list_tables.cache_clear()
    tables.get_language.cache_clear()
    tables.get_lang_map.cache_clear()

    return tables


def test_sample(dset):
    """
    Test an individual sample set and produce a human-readable report.

    Used outside of automated tests.

    @param dset (str): sample set name (without the .csv extension) found in
    the `data/script_samples` directory.
    """
    deltas = []
    dset_fpath = path.join(TEST_DATA_DIR, "script_samples", dset + ".csv")
    log_fpath = path.join(TEST_DATA_DIR, f"test_{dset}.log")

    with open(dset_fpath, newline="") as fh:
        csv = reader(fh)
        i = 1
        for row in csv:
            logger.info(f"CSV row #{i}")
            i += 1
            lang, script, rom = row[:3]
            if not lang:
                continue
            opts = jloads(row[3]) if len(row) > 3 and row[3] else {}
            trans, warnings = transliterate(
                    script, lang, t_dir="s2r",
                    capitalize=opts.get("capitalize"), options=opts)
            if (trans == rom):
                print(".", end="")
            else:
                print("F", end="")
                deltas.append((lang, script, ndiff([trans], [rom])))

    with open(log_fpath, "w") as fh:
        # If no deltas, just truncate the file.
        for lang, script, delta in deltas:
            fh.write(f"Language: {lang}\n")
            fh.write(f"Original: {script}\nDiff (result vs. expected):\n")
            for dline in delta:
                fh.write(dline.strip() + "\n")
            fh.write("\n\n")

    ct = len(deltas)
    if ct > 0:
        print(f"{ct} failed tests. See report at {log_fpath}")
    else:
        print("All tests passed.")

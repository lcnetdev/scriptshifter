from csv import reader
from difflib import ndiff
from json import loads as jloads
from logging import getLogger
from os import path

from scriptshifter.trans import transliterate
from test import TEST_DATA_DIR

logger = getLogger(__name__)


def test_sample(dset, report=True):
    """
    Test an individual sample set and produce a human-readable report.

    Used outside of automated tests.

    @param dset (str): sample set name (without the .csv extension) found in
    the `data/script_samples` directory.

    @param report (bool): if True (the default), print fail/success ticks and
    write out a report to file at the end. Otherwise, raise an exception on
    the first error encountered.
    """
    deltas = [] if report else None
    dset_fpath = path.join(TEST_DATA_DIR, "script_samples", dset + ".csv")
    log_fpath = path.join(TEST_DATA_DIR, "log", f"test_{dset}.log")

    with open(dset_fpath, newline="") as fh:
        csv = reader(fh)
        i = 1
        for row in csv:
            logger.debug(f"CSV row #{i}")
            lang, script, rom = row[:3]
            if not lang:
                continue
            t_dir = row[3] if len(row) > 3 else None
            opts = jloads(row[4]) if len(row) > 4 and row[4] else {}

            if t_dir:
                _trans(script, lang, t_dir, opts, rom, deltas)
            else:
                _trans(script, lang, "s2r", opts, rom, deltas)
                _trans(rom, lang, "r2s", opts, script, deltas)
            i += 1

    if report:
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
            print(f"\n\n{ct} failed tests. See report at {log_fpath}")
        else:
            print("All tests passed.")


def _trans(script, lang, t_dir, opts, rom, deltas):
    logger.debug(f"Transliterating {lang}: {t_dir}")
    trans, warnings = transliterate(
            script, lang, t_dir=t_dir,
            capitalize=opts.get("capitalize"), options=opts)
    try:
        assert trans == rom
    except AssertionError as e:
        if deltas is not None:
            print("F", end="")
            deltas.append((lang, script, ndiff([trans], [rom])))
        else:
            raise e
    else:
        if deltas:
            print(".", end="")

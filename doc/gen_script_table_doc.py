#!/usr/bin/env python

import sys
from os import path
from yaml import load
try:
    from yaml import CLoader as Loader
except ImportError:
    from yaml import Loader


DOCROOT = path.dirname(__file__)

sys.path.append(path.dirname(DOCROOT))
from scriptshifter.tables import TABLE_DIR, list_tables

REL_TABLE_DIR = "../scriptshifter/tables/data"


with open(path.join(DOCROOT, "supported_scripts_template.md"), "r") as fh:
    tpl_data = fh.read()

with open(path.join(DOCROOT, "supported_scripts.md"), "w") as fh:
    fh.write(tpl_data)

    for name, data in list_tables().items():
        if "alias_of" in data:
            fh.write(
                f"| `{name}` | {data['label']} | "
                f"[`{data['alias_of']}`]({REL_TABLE_DIR}/{data['alias_of']}.yml)"
                f" | - | - | - | -\n"
            )
        else:
            fname = path.join(TABLE_DIR, name + ".yml")
            with open(fname, "r") as md_fh:
                md = load(md_fh, Loader=Loader)

            fh.write(
                f"| [`{name}`]({REL_TABLE_DIR}/{name}.yml) | "
                f"{data['label']} | - | "
                f"{'Y' if data.get('has_r2s', False) else 'N'} | "
                f"{'Y' if data.get('has_s2r', False) else 'N'} | "
                f"{md['general'].get('version', '-')} | "
                f"{md['general'].get('date', '-')} \n"
            )

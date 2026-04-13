#!/usr/bin/env python

import sys
from os import path

DOCROOT = path.dirname(__file__)

sys.path.append(path.dirname(DOCROOT))
from scriptshifter.tables import list_tables

with open(path.join(DOCROOT, "supported_scripts_template.md"), "r") as fh:
    tpl_data = fh.read()

with open(path.join(DOCROOT, "supported_scripts.md"), "w") as fh:
    fh.write(tpl_data)

    for name, data in list_tables().items():
        if "alias_of" in data:
            fh.write(
                f"| `{name}` | {data['label']} | "
                f"- | - | [`{data['alias_of']}`]"
                f"(../scriptshifter/tables/data/{data['alias_of']}.yml) |\n"
            )
        else:
            fh.write(
                f"| [`{name}`](../scriptshifter/tables/data/{name}.yml) | "
                f"{data['label']} | "
                f"{'Y' if data.get('has_r2s', False) else 'N'} | "
                f"{'Y' if data.get('has_s2r', False) else 'N'} | - |\n"
            )

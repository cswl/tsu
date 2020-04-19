#!/usr/bin/env python3

import re

input_src = "./shell/tsu.sh"
input_usage = "./README.md"
out_file = "./tsu"


#
def extract(f, filter=None):
    code_blocks = []
    while True:
        line = f.readline()
        if not line:
            # EOF
            break

        out = re.match("[^`]*```(.*)$", line)
        if out:
            if filter and filter.strip() != out.group(1).strip():
                continue
            code_block = [f.readline()]
            while re.search("```", code_block[-1]) is None:
                code_block.append(f.readline())
            code_blocks.append("".join(code_block[:-1]))
    return code_blocks


with open(input_src) as f, open(input_usage) as u:
    cb = extract(u)
    sample1 = f.read().replace("#SHOW_USAGE_BLOCK", cb[0])

with open(out_file, "w") as o:
    o.write(sample1)

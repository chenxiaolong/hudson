#!/usr/bin/env python3

import os
import re
import sys

filename = os.path.split(sys.argv[1])[1]

# With tag
r1 = re.search(r"^cm-[0-9\.]+-([0-9]+)-[^-]+-([^-]+)-([a-zA-Z0-9]+)\.zip$", filename)
# Without tag
r2 = re.search(r"^cm-[0-9\.]+-([0-9]+)-[^-]+-([a-zA-Z0-9]+)\.zip$", filename)

date = ""
tag = "UNNAMED"
device = ""

if r1:
  date   = r1.groups()[0]
  tag    = r1.groups()[1]
  device = r1.groups()[2]

elif r2:
  date   = r2.groups()[0]
  device = r2.groups()[1]

print("%s:%s:%s" % (date, tag, device))

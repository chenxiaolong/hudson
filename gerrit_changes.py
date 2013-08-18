#!/usr/bin/env python3

# Based on CyanogenMod's repopick.py from https://github.com/CyanogenMod/hudson

import json
import os
import re
import subprocess
import sys
import urllib.request

if not "GERRIT_URL" in os.environ:
  print("GERRIT_URL not specified!")
  sys.exit(1)

gerrit_url = os.environ['GERRIT_URL']

if gerrit_url[-1] == '/':
  gerrit_url = gerrit_url[:-1]

repo = ""

# Look for repo tool
for path in os.environ["PATH"].split(os.pathsep):
  temp = os.path.join(path, "repo")
  if os.path.isfile(temp) and os.access(temp, os.X_OK):
    repo = temp
    break

if not repo:
  print("repo not found!")
  sys.exit(1)

process = subprocess.Popen(
  [ repo, 'list' ],
  stdout = subprocess.PIPE,
  universal_newlines = True
)

temp = process.communicate()[0].split('\n')
repos = []
for line in temp:
  if not line:
    continue

  split = re.split('\s*:\s*', line)

  repos.append(split)

for change in sys.argv[1:]:
  if not change:
    continue

  if '://' in change:
    match = re.search(r'#/c/([0-9]+)/?', change)
    if not match:
      print("Invalid URL: %s" % change)
      sys.exit(1)
    change = match.group(1)

  print("Cherrypicking %s ..." % change)

  f = urllib.request.urlopen("%s/query?q=change:%s" % (gerrit_url, change))
  d = f.read().decode()

  print("Received from gerrit:")
  print("---")
  print(d)
  print("---")

  d = d.split('\n')[0]
  data = json.loads(d)
  project = data['project']
  projectpath = ""
  number = data['number']

  print("URL: %s/#/c/%s/ ..." % (gerrit_url, number))

  for i in repos:
    if project == i[1]:
      projectpath = i[0]
      break

  if not projectpath:
    print("Project %s not found!" % project)
    sys.exit(1)

  if not os.path.isdir(projectpath):
    print("%s is not a directory!" % projectpath)
    sys.exit(1)

  f = urllib.request.urlopen("%s/changes/%s/revisions/current/review" % \
                             (gerrit_url, number))
  d = f.read().decode()
  d = '\n'.join(d.split('\n')[1:])
  data = json.loads(d)

  current_revision = data['current_revision']
  patchset = 0
  ref = ""

  for i in data['revisions']:
    if i == current_revision:
      ref = data['revisions'][i]['fetch']['http']['ref']
      patchset = data['revisions'][i]['_number']
      break

  print("Patch set: %i" % patchset)
  print("Ref: %s" % ref)

  os.system('cd %s ; git fetch %s/%s %s' % \
            (projectpath, gerrit_url, project, ref))

  os.system('cd %s ; git merge --no-edit FETCH_HEAD' % projectpath)

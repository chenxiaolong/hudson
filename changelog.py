#!/usr/bin/python3

# Generate changelogs and create HTML output

import os
import subprocess
import sys
from email.utils import formatdate

if len(sys.argv) < 4:
  print("Usage: changelog.py [device] [rom] [branch]")
  exit(1)

html_path = os.environ["WORKSPACE"] + "/archive/changelog.html"

html_file = open(html_path, 'w')

def write_html(string):
  html_file.write(string + '\n')

current_time = formatdate()
device = sys.argv[1]
rom = sys.argv[2]
branch = sys.argv[3]
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

# Read previous build time
previous_time = ""
changes = os.environ["WORKSPACE"] + "/changes_%s_%s_%s" % (rom, branch, device)
if not os.path.exists(changes):
  fd = open(changes + '.new', 'w')
  fd.write(current_time)
  fd.close()

  write_html("Initial build; no changelog")
  html_file.close()
  sys.exit(0);

fd = open(changes, 'r')
contents = fd.readlines()
if len(contents) >= 1:
  previous_time = contents[0].strip('\n')
fd.close()

# Get list of repos
process = subprocess.Popen(
  [ repo, 'forall', '-c', 'echo ${REPO_PATH}' ],
  stdout = subprocess.PIPE,
  universal_newlines = True
)

all_repos = process.communicate()[0].split('\n')

html_header = """
<html>
  <head>
    <title>Changelog for %s</title>
  </head>
  <body>
    <h1>Changelog for %s</h1>
    <table>
      <tr>
        <td>From:</td>
        <td>%s</td>
      </tr>
      <tr>
        <td>to:</td>
        <td>%s</td>
      </tr>
    </table>
""" % (device, device, previous_time, current_time)

html_footer = """
  </body>
</html>
"""

write_html(html_header)

counter = 0

for current_repo in all_repos:
  if not current_repo: continue

  # Get repo URL
  process = subprocess.Popen(
    [ 'git', 'remote' ],
    stdout = subprocess.PIPE,
    cwd = current_repo,
    universal_newlines = True
  )

  remote = process.communicate()[0].split('\n')[0]

  # Get project path
  process = subprocess.Popen(
    [ 'git', 'config',
      '--get', 'remote.' + remote + '.projectname' ],
    stdout = subprocess.PIPE,
    cwd = current_repo,
    universal_newlines = True
  )

  project_name = process.communicate()[0].split('\n')[0]

  # Get commit log
  process = subprocess.Popen(
    [ 'git', 'log',
      '--pretty=format:%H\n%s',
      '--since', previous_time,
      '--until', current_time, ],
    stdout = subprocess.PIPE,
    cwd = current_repo,
    universal_newlines = True
  )

  log = process.communicate()[0].split('\n')
  if len(log) > 1:
    write_html("<h2><a href=%s/%s>%s</a></h2>" %
               ("https://github.com", project_name, current_repo))

    write_html("<table>")
    for i in range(0, len(log) - 1, 2):
      commit = log[i]
      subject = log[i + 1]

      write_html("<tr>")
      write_html("<td><a href=%s/%s/commit/%s>%s</a></td>" %
                 ("https://github.com", project_name, commit, commit[0:7]))
      write_html("<td><a href=%s/%s/commit/%s>%s</a></td>" %
                 ("https://github.com", project_name, commit, subject))
      write_html("</tr>")
    write_html("</table>")

    counter = counter + 1

write_html(html_footer)
html_file.close()

#if counter == 0:
#  print("NO CHANGES SINCE LAST BUILD!!!")
#  sys.exit(1)

fd = open(changes + '.new', 'w')
fd.write(current_time)
fd.close()

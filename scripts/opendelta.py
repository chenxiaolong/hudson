#!/usr/bin/env python3

import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile

template = """
{
  "version": 1,
  "in": {
      "name"              : "%s",
      "size_store"        : %i,
      "size_store_signed" : %i,
      "size_official"     : %i,
      "md5_store"         : "%s",
      "md5_store_signed"  : "%s",
      "md5_official"      : "%s"
  },
  "update": {
      "name"              : "%s.update",
      "size"              : %i,
      "size_applied"      : %i,
      "md5"               : "%s",
      "md5_applied"       : "%s"
  },
  "signature": {
      "name"              : "%s.sign",
      "size"              : %i,
      "size_applied"      : %i,
      "md5"               : "%s",
      "md5_applied"       : "%s"
  },
  "out": {
      "name"              : "%s",
      "size_store"        : %i,
      "size_store_signed" : %i,
      "size_official"     : %i,
      "md5_store"         : "%s",
      "md5_store_signed"  : "%s",
      "md5_official"      : "%s"
  }
}
"""

if len(sys.argv) != 6:
  print("Usage: %s [device] [old build path] [new build path] [binaries path] [output path]" % sys.argv[0])
  sys.exit(1)

device = sys.argv[1]
path_last = sys.argv[2]
path_current = sys.argv[3]
binariesdir = sys.argv[4]
outputdir = sys.argv[5]

java = 'java'
xdelta3 = 'xdelta3'
zipadjust = os.path.join(binariesdir, 'zipadjust')

file_re = r"cm-.*noobdev.*\.zip"

remove_dirs = []

def clean_up_and_exit(exit_status):
  for d in remove_dirs:
    shutil.rmtree(d)

  sys.exit(exit_status)

def run_command(command,
                stdin_data = None,
                cwd = None,
                universal_newlines = True):
  try:
    process = subprocess.Popen(
      command,
      stdin = subprocess.PIPE,
      stdout = subprocess.PIPE,
      stderr = subprocess.PIPE,
      cwd = cwd,
      universal_newlines = universal_newlines
    )
    output, error = process.communicate(input = stdin_data)

    exit_status = process.returncode
    return (exit_status, output, error)
  except:
    print("Failed to run command: \"%s\"" % ' '.join(command))
    return (None, None, None)

# Read's everything into memory, but that's fine
def get_file_md5(path):
  f = open(path, 'rb')
  md5 = hashlib.md5(f.read()).hexdigest()
  f.close()
  return md5

def get_file_size(path):
  f = open(path, 'rb')
  f.seek(0, os.SEEK_END)
  size = f.tell()
  f.close()
  return size

def get_latest_file(path):
  files = []
  latest = ""

  for f in os.listdir(path):
    if re.search(file_re, f):
      files.append(f)

  files.sort()

  if files:
    latest = os.path.split(files[-1])[1]

  return latest

# --- BEGIN ---

print("Device:\t\t" + device)

file_current = get_latest_file(path_current)
file_last = get_latest_file(path_last)
file_last_base = os.path.splitext(file_last)[0]

print("Last build:\t" + file_last)
print("Current build:\t" + file_current)

if file_current == "":
  print("Current zip not found")
  clean_up_and_exit(1)

if file_last == "":
  print("Last zip not found")
  print("Copying current zip to last zip ...")
  shutil.copyfile(
    os.path.join(path_current, file_current),
    os.path.join(path_last, file_current)
  )
  clean_up_and_exit(0)

if file_last == file_current:
  print("Current and last zip have the same name")
  clean_up_and_exit(1)

print('-' * 80)
# --- GENERATE DELTA ---

tempdir = tempfile.mkdtemp()
remove_dirs.append(tempdir)

print("Decompressing %s ..." % file_current)
exit_status, output, error = run_command(
  [ zipadjust, '--decompress',
    os.path.join(path_current, file_current),
    os.path.join(tempdir, 'current.zip') ]
)

if exit_status is None or exit_status != 0:
  print("Failed to decompress current zip")
  clean_up_and_exit(1)

print("Decompressing %s ..." % file_last)
exit_status, output, error = run_command(
  [ zipadjust, '--decompress',
    os.path.join(path_last, file_last),
    os.path.join(tempdir, 'last.zip') ]
)

if exit_status is None or exit_status != 0:
  print("Failed to decompress last zip")
  clean_up_and_exit(1)

print("Generating delta %s ..." % (file_last_base + '.update'))
exit_status, output, error = run_command(
  [ xdelta3, '-9evfS', 'none', '-s',
    os.path.join(tempdir, 'last.zip'),
    os.path.join(tempdir, 'current.zip'),
    os.path.join(outputdir, file_last_base + '.update') ]
)

if exit_status is None or exit_status != 0:
  print("Failed create delta file")
  clean_up_and_exit(1)

md5_current       = get_file_md5(os.path.join(path_current, file_current))
md5_current_store = get_file_md5(os.path.join(tempdir, 'current.zip'))
md5_last          = get_file_md5(os.path.join(path_last, file_last))
md5_last_store    = get_file_md5(os.path.join(tempdir, 'last.zip'))
md5_update        = get_file_md5(os.path.join(outputdir, file_last_base + '.update'))

size_current       = get_file_size(os.path.join(path_current, file_current))
size_current_store = get_file_size(os.path.join(tempdir, 'current.zip'))
size_last          = get_file_size(os.path.join(path_last, file_last))
size_last_store    = get_file_size(os.path.join(tempdir, 'last.zip'))
size_update        = get_file_size(os.path.join(outputdir, file_last_base + '.update'))

print('-' * 80)
print("Last build:")
print("  MD5:\t\t\t"           + md5_last)
print("  Decompressed MD5:\t"  + md5_last_store)
print("  Size:\t\t\t"          + str(size_last))
print("  Decompressed size:\t" + str(size_last_store))
print()
print("Current build:")
print("  MD5:\t\t\t"           + md5_current)
print("  Decompressed MD5:\t"  + md5_current_store)
print("  Size:\t\t\t"          + str(size_current))
print("  Decompressed size:\t" + str(size_current_store))
print()
print("Delta:")
print("  MD5:\t\t\t"           + md5_update)
print("  Size:\t\t\t"          + str(size_update))


f = open(os.path.join(outputdir, file_last_base + '.delta'), 'wb')

f.write((template % (
  # in
  file_last,
  size_last_store,
  0,       # size_last_store_signed
  size_last,
  md5_last_store,
  'dummy', # md5_last_store_signed
  md5_last,

  # update
  file_last_base,
  size_update,
  size_current_store,
  md5_update,
  md5_current_store,

  # signature
  'dummy', # file_last_base
  0,       # size_sign
  0,       # size_current_store_signed
  'dummy', # md5_sign
  'dummy', # md5_current_store_signed

  # out
  file_current,
  size_current_store,
  0,       # size_current_store_signed
  size_current,
  md5_current_store,
  'dummy', # md5_current_store_signed
  md5_current
)).encode("UTF-8"))

f.close()

clean_up_and_exit(0)

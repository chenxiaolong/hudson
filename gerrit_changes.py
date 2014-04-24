#!/usr/bin/env python3

import argparse
import json
import os
import re
import subprocess
import sys

if sys.hexversion < 0x03000000:
    from urllib2 import urlopen
    from urllib2 import URLError
else:
    from urllib.request import urlopen
    from urllib.error import URLError


# Get default URL (used if only the change IDs are provided as parameters)
if 'GERRIT_URL' in os.environ:
    default_host = os.environ['GERRIT_URL']
    if default_host[-1] == '/':
        default_host = default_host[:-1]
else:
    default_host = None


class Commit:
    def __init__(self):
        self.host = default_host
        self.url = ""
        self.changeid = ""
        self.project = ""
        self.projectpath = ""
        self.patchset = 0
        self.ref = ""

    def cherrypick(self):
        exit_status, output, error = run_command(
            ['git', 'fetch', self.host + '/' + self.project, self.ref],
            cwd=self.projectpath
        )
        if exit_status != 0:
            raise Exception(
                'Failed to run command (exit status %i):\n' % exit_status +
                '--- stdout ---\n' + output +
                '--- stderr ---\n' + error +
                '--- end ---'
            )

        exit_status, output, error = run_command(
            ['git', 'merge', '--no-edit', 'FETCH_HEAD'],
            cwd=self.projectpath
        )
        if exit_status != 0:
            run_command(
                ['git', 'reset', '--hard', 'HEAD'],
                cwd=self.projectpath
            )
            raise Exception(
                'Failed to run command (exit status: %i):\n' % exit_status +
                '--- stdout ---\n' + output +
                '--- stderr ---\n' + error +
                '--- end ---'
            )

    def parse(self, arg):
        if '://' in arg:
            self.parse_url(arg)
        elif arg[0] == 'I':
            self.parse_commit_id(arg)
        elif re.search(r'^[0-9]+$', arg):
            self.parse_change_id(arg)
        else:
            raise Exception('Could not parse argument: ' + arg)

        self.projectpath = self.get_project_path()
        self.fetch_latest_revision()

    def parse_url(self, url):
        match = re.search(r'(?:/#/c)?/([0-9]+)/?', arg)
        if not match:
            raise Exception('Invalid URL: %s' % arg)

        host = re.search(r'^(.+://.+?)/', arg)
        if not host:
            raise Exception('Invalid URL: %s' % arg)

        self.host = host.group(1)
        self.url = arg
        self.changeid = match.group(1)
        data = self.query_gerrit(self.changeid)
        self.project = data['project']

    def parse_commit_id(self, commit_id):
        data = self.query_gerrit(commit_id)
        self.changeid = data['number']
        self.project = data['project']
        self.url = '%s/#/c/%s/' % (self.host, self.changeid)

    def parse_change_id(self, change_id):
        self.changeid = change_id
        data = self.query_gerrit(change_id)
        self.project = data['project']
        self.url = '%s/#/c/%s/' % (self.host, self.changeid)

    def query_gerrit(self, query):
        if not self.host:
            raise Exception('GERRIT_URL environment variable is not set')

        query_url = "%s/query?q=change:%s" % (self.host, query)

        # Sometimes 504's a bit
        counter = 0
        while counter < 5:
            try:
                f = urlopen(query_url)
                d = f.read().decode()
                d = d.split('\n')[0]
                data = json.loads(d)
                return data
            except URLError as e:
                if int(e.code / 100) != 5:
                    raise Exception('Failed to query gerrit: ' + str(e))
                else:
                    print('Failed to query gerrit, trying again ...')
                    counter += 1

        raise Exception('Failed to query gerrit after 5 tries')

    def get_project_path(self):
        path = None

        for i in repos:
            if self.project == i[1]:
                path = i[0]
                break

        if not path:
            for i in repos:
                if re.sub('CyanogenMod/android', 'chenxiaolong/CM',
                          self.project) == i[1]:
                    path = i[0]
                    break

        if not path:
            raise Exception('The path for project %s was not found' %
                            self.project)

        if not os.path.isdir(path):
            raise Exception('The path %s is not a directory' % path)

        return path

    def fetch_latest_revision(self):
        f = urlopen("%s/changes/%s/revisions/current/review" %
                    (self.host, self.changeid))
        d = f.read().decode()
        d = '\n'.join(d.split('\n')[1:])
        data = json.loads(d)

        current_revision = data['current_revision']
        patchset = 0
        ref = ""

        for i in data['revisions']:
            if i == current_revision:
                fetch = data['revisions'][i]['fetch']
                if 'http' in fetch:
                    ref = fetch['http']['ref']
                else:
                    ref = fetch['anonymous http']['ref']
                patchset = data['revisions'][i]['_number']
                break

        self.patchset = patchset
        self.ref = ref


def run_command(command,
                stdin_data=None,
                cwd=None,
                universal_newlines=True):
    try:
        process = subprocess.Popen(
            command,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=cwd,
            universal_newlines=universal_newlines
        )
        output, error = process.communicate(input=stdin_data)

        exit_status = process.returncode
        return (exit_status, output, error)
    except:
        raise Exception("Failed to run command: \"%s\"" % ' '.join(command))


def find_repo():
    for path in os.environ['PATH'].split(os.pathsep):
        f = os.path.join(path, 'repo')
        if os.path.isfile(f) and os.access(f, os.X_OK):
            return f
    return None


def get_repo_list():
    exit_status, output, error = run_command(
        [repo, 'list']
    )
    lines = output.split('\n')

    repos = []
    for line in lines:
        if not line:
            continue

        repos.append(re.split(r'\s*:\s*', line))

    return repos


# Look for repo tool
repo = find_repo()
if not repo:
    print("repo not found!")
    sys.exit(1)

repos = get_repo_list()

parser = argparse.ArgumentParser()
parser.add_argument('-f', '--file',
                    dest='filepath',
                    help='Load commit list from a file',
                    action='store')
parser.add_argument('-u', '--url',
                    dest='urlpath',
                    help='Load commit list from a URL',
                    action='store')
parser.add_argument('commit',
                    help='List of commits',
                    nargs='*')
args = parser.parse_args()

commits = []
for i in args.commit:
    commits.append(i)

if args.filepath:
    with open(args.filepath, 'r') as f:
        lines = f.readlines()
        for line in lines:
            commits.append(line.strip('\n').strip('\r'))

if args.urlpath:
    u = urlopen(args.urlpath)
    lines = u.readlines()
    for line in lines:
        temp = line.decode('UTF-8')
        commits.append(temp.strip('\n').strip('\r'))
    u.close()

if not commits:
    print('No commits were specified')
    sys.exit(1)


for arg in commits:
    if not arg:
        continue

    print('=' * 80)

    commit = Commit()

    try:
        commit.parse(arg)

        print('Cherrypicking %s ...' % commit.changeid)
        print('URL:       %s' % commit.url)
        print('Project:   %s' % commit.project)
        print('Path:      %s' % commit.projectpath)
        print("Patch set: %i" % commit.patchset)
        print("Ref:       %s" % commit.ref)

        commit.cherrypick()
    except Exception as e:
        print(str(e))
        sys.exit(1)

print("=" * 80)

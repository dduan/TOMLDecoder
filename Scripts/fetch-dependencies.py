#!/usr/bin/env python2

import json
import subprocess
import os

pins = json.loads(open('Package.resolved').read())
for pin in pins["object"]["pins"]:
    path = 'Dependencies/' + pin['package']
    subprocess.call(['rm', '-rf', path])
    subprocess.call(['git', 'clone', pin['repositoryURL'] + '.git', path])
    cwd = os.getcwd()
    os.chdir(path)
    subprocess.call(['git', 'checkout', pin['state']['revision']])
    subprocess.call(['rm', '-rf', pin['package'] + '.xcodeproj/xcshareddata/xcschemes'])
    os.chdir(cwd)


#!/usr/bin/env python

# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
# This file was autogenerated by the transformation.py script
#

import sys, getopt
import urllib2
from urlparse import urlparse,ParseResult
import re
import logging
import yaml
import os
import subprocess

# Defining defaults

# By default, we implements the required source yaml section. This can be update by a flag --source (NOT YET IMPLEMENTED)
SOURCES="sources"
#########################

def help():
  print 'bp --start <url|bp-name> [--debug] [-v]'

def load_bp(bp_element):
  "load_bp function read from a file or from an url, the blueprint yaml document. It returns the blueprint data in dict object."
  dUrl=urlparse(bp_element)
  
  re_filename=re.compile('^[a-zA-Z0-9]*$')
  if dUrl.scheme == '' and re_filename.match(bp_element): # Need to build the url with forj-oss link by default.
     dUrl=ParseResult('http','catalog.forj.io','/master/'+bp_element+'-master.yaml','','','')
     bp_element=dUrl.geturl()
     logging.debug('Use default internet FORJ catalog: ' + bp_element)
  
  if dUrl.scheme == '' :
     try:
       fYaml_hdl = open(dUrl.path)
     except IOError, e:
       logging.error('Unable to open %s: %s',dUrl.path,e.msg)
  else:   
     fYaml_req = urllib2.Request(bp_element)
     try:
       fYaml_hdl = urllib2.urlopen(fYaml_req)
     except URLError, e:
       logging.error('Unable to contact the url "'+bp_element+'" : '+e.reason)
       sys.exit(1)
     except URLError, e:
       logging.error('Unable to retrieve the blueprint from the url "'+bp_element+'" : '+e.code)
       sys.exit(1)
  
  fYaml = yaml.load(fYaml_hdl)
  logging.debug(fYaml)
  return fYaml

def git_clone(url, to = "/opt/config/production/git"):

  """git_clone(url,to): Execute a git clone of an url."""

  GIT='/usr/bin/git'
  
  logging.info("GIT: Cloning '%s' to '%s'",url,to)
  if not os.path.isdir(to) or not os.access(to, os.W_OK):
     logging.error("'%s' doesn't exist or is not writable. Please check. git clone aborted.",to)
     return
  os.chdir(to)
  if not os.access(GIT,os.X_OK):
     logging.error("'%s' is not executable. Is git installed???",GIT)
     return
  GIT_CMD=[GIT,'clone',url]
  try:
    iGitCode=subprocess.call(GIT_CMD)
  except OSError,e:
    logging.error('git_clone: "%s" fails with return code: %d (%s)',' '.join(GIT_CMD),iGitCode,e.message) 

def install_bp(bp_element):
  "install_bp(bp_element) Loading the blueprint file and install the required element to make it work on Maestro."
  fYaml=load_bp(bp_element)
  
  if not fYaml.has_key('blueprint'):
     logging.error('"%s" do not define required "blueprint/" yaml section.',bp_element)
     sys.exit(2)

  BP_DESC="Undefined blueprint"
  BP_yaml=fYaml['blueprint']
  if BP_yaml.has_key('description'):
     BP_DESC=BP_yaml['description']
  else:
     logging.warning('"%s" do not define "blueprint/description" data.',bp_element)
  
  logging.info('Blueprint downloaded: '+BP_DESC)
  if not BP_yaml.has_key('requires') :
    logging.error('"%s" do not define required "blueprint/requires" yaml section.',bp_element)
    sys.exit(2)

  if BP_yaml['requires'].has_key(SOURCES):
     dSource=BP_yaml['requires'][SOURCES]
     for v in dSource:
         if v.has_key('git'):
            git_clone(v['git'])
         else:
            logging.warning("Protocol '%s' not yet implemented.",k)
  

def main(argv):
  """Main function"""
  
  logging.basicConfig(format='%(asctime)s: %(message)s', datefmt='%m/%d/%Y %I:%M:%S %p')
  oLogging=logging.getLogger()
  try:
     opts,args = getopt.getopt(argv,"hI:v",["help","install=","debug","verbose"])
  except getopt.GetoptError, e:
     print 'Error: '+e.msg
     help()
     sys.exit(2)
  
  action=0
  for opt, arg in opts:
     if opt in ('-h', '--help'):
        help()
        sys.exit()
     elif opt in ('-v'):
        if oLogging.level >20:
           oLogging.setLevel(oLogging.level-10)
     elif opt in ('--debug'):
        print "Setting debug mode"
        oLogging.setLevel(logging.DEBUG)
     elif opt in ('-I', '--install'):
        ACTION="install_bp"
        BP=arg
        action=1
  if action == 0:
    print 'Error: At least --start is required.'
    help()
  else:
    if ACTION == 'install_bp':
       install_bp(BP)
  sys.exit()

if __name__ == "__main__":
   main(sys.argv[1:])
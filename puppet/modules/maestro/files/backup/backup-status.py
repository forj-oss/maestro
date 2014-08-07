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

# This script is designed to build the maestro backup status file (backup-status.yaml)
# It reads his information from what has been pushed to /mnt/backups (or --bck-path)
# It consider the following path:
# On each nodes : PATH is {root_backup}/{Services}/BUP DATA&LOGS 
# On Maestro, PATH is {root_backup}/{Server}/{Services}/{Weekstring}/BUP DATA&LOGS
# Nodes rsync BUP DATA&LOGS to the appropriate Maestro backup path. ({root_backup}/{Server}/{Services}/{Weekstring})
# 
# BUP DATA&LOGS contains
# - bup_repo - This directory content is managed by bup (GIT repo structure). Each bup run will have:
#   - List of path
#   - Additional files or path (mysql files for example)
#   - info.yaml - File which inform about how a bup run was executed.
# - logs
#   - info_{YYYY-MM-DD}_{HH-MM-SS}_{PID}.yaml
#   - bup_{YYYY-MM-DD}_{HH-MM-SS}_{PID}.log


import sys
import getopt
#import urllib2
#from urlparse import urlparse,ParseResult
import re
import logging
import logging.handlers
import yaml
import os
#import subprocess
#import distutils.spawn
#import string 
from datetime import date,datetime
#import time
#import tempfile

# Defining defaults

# 

##############################
def help():
   print 'backup-status.py [--bck-path MaestroBackupPath] [-d|--debug] [-v|--verbose] [--output|-o <file|\'-\'>]'

##############################
def find_mount_point(path):
    """Determine what is the filesystem root mount point"""
    path = os.path.abspath(path)
    while not os.path.ismount(path):
        path = os.path.dirname(path)
    return path

##############################
def check_FS_stats(path, yyaml):
  """Function to check and load FS statistics if new"""

  oLogging=logging.getLogger('backup-status')

  mount_point=find_mount_point(path)

  if yyaml.has_key('status') and yyaml['status'].has_key('filesystems'):
     if not yyaml['status']['filesystems'].has_key(mount_point):
        mpstat=os.statvfs(mount_point)
        free_avail_percent=round(100.0*mpstat.f_bfree/mpstat.f_blocks, 2)
        free_avail=round(0.0+mpstat.f_bavail*mpstat.f_frsize/1024/1024/1024, 2)
        total_fs=round(0.0+mpstat.f_blocks*mpstat.f_frsize/1024/1024/1024, 2)
        
        yyaml['status']['filesystems'][mount_point]={
                                       'free-GB'     : free_avail,
                                       'free-percent': free_avail_percent,
                                       'total-fs'    : total_fs
                                       }
        oLogging.debug('The mount point "%s" has been evaluated and added in status/filesystems', mount_point)
  return mount_point

##############################
def get_backupfile_status(yService, info_file, root, Week):
  """Find and load the backup status files and report it."""

  oLogging=logging.getLogger('backup-status')

  reObj=re.compile('^info_(\d\d\d\d-\d\d-\d\d_\d\d-\d\d-\d\d_\d*)\.yaml')
  oResult=reObj.search(info_file)
  oLogging.debug('Checking "%s"', os.path.join(root, info_file))
  if oResult == None:
     return

  oLogging.debug('Opening "%s" to read the backup run status.', info_file)
  aMsg = []
  errors = 0
  warnings = 0
  log_file = os.path.join(root,"bup_" + oResult.group(1) + '.log')
  if not os.path.exists(log_file) or os.path.isdir(log_file):
     warnings+=1
     aMsg.append('Warning! Unable to find the log file ' + log_file)
  try:
    fBckStatus=open(os.path.join(root, info_file))
  except IOError as e:
    oLogging.error("I/O error({0}): {1}".format(e.errno, e.strerror))
    status=2
    aMsg.append("I/O error({0}): {1}".format(e.errno, e.strerror))
    oLogging.error(aMsg[-1])
  else:
    try:
       back_status=yaml.load(fBckStatus)
    except yaml.YAMLError, exc:
       status=2
       aMsg.append('Errors found while reading "{0}" as yaml document: {1}'.format(info_file, exc))
       oLogging.error(aMsg[-1])
    else:
       fBckStatus.close()
       if type(back_status) is not dict:
          status=2
          aMsg.append('{0} is not a valid yaml file.'.format(info_file))
          errors+=1
       else:
          if type(back_status) is dict and back_status.has_key('errors'):
            errors+=back_status['errors']

          if type(back_status) is dict and back_status.has_key('warnings'):
            warnings+=back_status['warnings']

          status=0
          if warnings > 0:
            status=1
            aMsg.append('{1} warning(s) has been detected in {0}. Please review.'.format(log_file, warnings))
          elif errors > 0:
            if status == 1:
               aMsg.append('{0} error(s) and {1} warning(s) has been detected in {2}. Please review.'.format(errors, warnings, log_file))
            else:
               aMsg.append('{0} Errors has been detected in {1}. Please review.'.format(errors, log_file))
            status=2
          else:
               aMsg.append('No error/warning reported')
          oLogging.debug("Found %s errors and %s warnings from log file '%s'.", errors, warnings, log_file)

  # Storing info_file status in backup/{server}/{service}/history.
  yHistory=yService['history']
  yHistory[oResult.group(1)]={'log_file': log_file,
                             'errors': errors,
                             'warnings': warnings,
                             'message': '\n'.join(aMsg)
                            }

  # report last backup executed on the service.
  reWeek=re.compile('^(.*)_.*_.*')
  oWeek=reWeek.search(oResult.group(1))
  if oWeek.group(1) == None:
     yService['last'] = oWeek.group(1)
  elif yService['last'] < oWeek.group(1):
     yService['last'] = oWeek.group(1)

  yService['status'] = status
  yService['message'] = yHistory[oResult.group(1)]['message']


##############################
def path_size(start_path):
    """Calculate directory tree size"""

    total_size = 0
    for dirpath, dirnames, filenames in os.walk(start_path):
        for f in filenames:
            fp = os.path.join(dirpath, f)
            total_size += os.path.getsize(fp)
    return total_size


##############################
def build_backup_status(bck_path, bck_file):
  """ This is the main function of this script. Build the backup status and save it to the status yaml file.
  
  function build_backup_status(bck_path, bck_file)
  :param bck_path: The Maestro backup PATH, where backups are stored.
  :param bck_file: Yaml file which will store backup status information.
  :returns: Nothing
  :raises: Nothing
  """

  oLogging=logging.getLogger('backup-status')
  oLoggingOut=logging.getLogger('backup-status-output')

  run_datetime = date.today()
  run_date = date.isoformat(run_datetime)
  run_year,run_week,_ = date.isocalendar(run_datetime)

  bck_path=os.path.normpath(bck_path)

  
  ybck_status={'status': {
                          'week'       : '{0}-{1}'.format(run_year, run_week),
                          'date'       : run_date,
                          'filesystems': {},
                          'status'     : 0
                         },
               'backup': {},
               'services': {}}

  
  check_FS_stats(bck_path, ybck_status)

  if not os.path.isdir(bck_path):
     oLogging.error('"%s" was not a valid directory. aborted.', bck_path)
     sys.exit(2)

  oLogging.info('Using "%s" as {root_backup}', bck_path)

  reIgnored=re.compile('ignored', re.I)
  reSupportedName=re.compile('^\w+\.[\w.]+$', re.I)

  # Loop in subdirectories to build services backup status
  for root,dirnames,files in os.walk(bck_path):
     oLogging.debug("Walking in '%s'", root)
     rel_path=re.sub(bck_path+'/*','', root).split('/')
     bIgnored=False
     if rel_path[0] <> "" and reIgnored.search(rel_path[0]) <> None:
        # Ignore the root path, if 'ignored' is found in the root dir name.
        bIgnored=True
        oLogging.debug("'%s' contains 'ignored'. Ignored from analyze.", rel_path[0])
        for i in sorted(dirnames):
           dirnames.remove(i)

     elif rel_path[0] <> "" and reSupportedName.search(rel_path[0]) == None:
        # Ignore the root path, if the server part name does not contain at least 1 '.'
        # The server name (root dir of the path) should be built at least with *.*, like '<ServerName>.<Domain>'
        bIgnored=True
        oLogging.debug("'%s' is not like '<ServerName>.<Domain>'. Ignored from analyze.", rel_path[0])
        for i in sorted(dirnames):
           dirnames.remove(i)

     if not bIgnored and len(rel_path) == 3: # server/service/week level
        if 'bup_repo' not in dirnames or 'logs' not in dirnames:
           oLogging.warning('%s is not a valid backup directory. Ignored.', root)
           bIgnored=True

        # Cleaning all additional subdirectories to stop the walk recursive task.
        for i in sorted(dirnames):
           if bIgnored or i <> 'logs': # keep logs in walk process to build week history. (Next elif case)
              dirnames.remove(i)

        # Adding data
        Server=rel_path[0]
        Service=rel_path[1]
        Week=rel_path[2]
        if not bIgnored:

           # Check if the mount point is different, to rebuild FS statistics.
           mount_point=check_FS_stats(root, ybck_status)

           if not ybck_status['backup'].has_key(Server):
              ybck_status['backup'][Server]={}
           if not ybck_status['backup'][Server].has_key(Service):
              ybck_status['backup'][Server]={Service:{
                                                      'status': 0,
                                                      'message': 'No error/warning reported.',
                                                      'last': None,
                                                      'history': {}
                                                     }
                                            }
           ybck_status['backup'][Server][Service]['used']=path_size(root)
           ybck_status['backup'][Server][Service]['mount-point']=mount_point
           ybck_status['backup'][Server][Service]['path']=os.path.join(bck_path, Server, Service)

           if not ybck_status['services'].has_key(Service):
             ybck_status['services'][Service]=[Server]
           else:
             if Server not in ybck_status['services'][Service]:
                ybck_status['services'][Service].append(Server)
     elif not bIgnored and len(rel_path) == 4: # server/service/week/logs level - Build history and provide last status.
        Server=rel_path[0]
        Service=rel_path[1]
        Week=rel_path[2]
        
        yService=ybck_status['backup'][Server][Service]
        oLogging.debug('Week: %s - Looping on logs:', Week)
        for log_file in sorted(files):
            get_backupfile_status(yService, log_file, root, Week)

        if not yService.has_key('last') or yService['last'] == None:
           yService['status']=2
           yService['message']='"{0}/*" week(s) has no valid log to verify.'.format(os.path.join(bck_path, Server, Service))
        else:
           # Check status from latest backup date, compare to now.
           # If missing last backup = Warning
           # If missing 2 or more last backup = error
           # Possible fixes:
           # - Restore backup function - Fix backup run error.
           # - Move old service backup to /mnt/backup/disabled.

           # Get number of days of missing backup
           iDaysOld=(run_datetime-datetime.strptime(yService['last'],'%Y-%m-%d').date()).days
           if iDaysOld == 1:
              UpdateStatus(ybck_status['status'], 1,
                           "Warning! {0}: Missing previous day backup. Please review service status.".format(Service))
           elif iDaysOld >1:
              UpdateStatus(ybck_status['status'], 2,
                           "Error! {0}: Several backup days missing. Please review service status. If this service is obsolete, move '{0}' to '{1}'".format(Service, os.path.join(bck_path,'ignored')))

           # Report to the top status if errors/warnings are found in a service backup.
           if yService['status'] == 1: 
              UpdateStatus(ybck_status['status'], 1,("Warning! {0}: "+yService['message']).format(Service))
           if yService['status'] > 1: 
              UpdateStatus(ybck_status['status'], 2,("Error! {0}: "+yService['message']).format(Service))

  if not ybck_status['status'].has_key('message'):
     ybck_status['status']['message']='No error/warning reported.'

  if bck_file == '-':
     print yaml.dump(ybck_status)
  else:
     try:
        stream=open(os.path.join(bck_path, bck_file),'w')
     except IOError as oErr:
        oLogging.error('Unable to write in \'%s\'.%s. Fix and retry.', oErr.strerror, os.path.join(bck_path, bck_file))
     else:
        yaml.dump(ybck_status, stream)
        stream.close()
        oLogging.info('\'%s\' written.', os.path.join(bck_path, bck_file))


 # print '{0}'.format(ybck_status)

##############################
def UpdateStatus(yStatus, iStatus, sMsg):
   """Update master backup status information"""

   if yStatus['status'] < iStatus:
      yStatus['status']=iStatus
   if yStatus.has_key('message'):
      sPrevMsg=yStatus['message']
   else:
      sPrevMsg=""

   if sPrevMsg == "":
      yStatus['message']=sMsg
   else:
      yStatus['message']=sPrevMsg+'\n'+sMsg

##############################
def main(argv):
  """Main function"""

  oLogging=logging.getLogger('backup-status')
  oLogging.setLevel(20)

  try:
     opts,args = getopt.getopt(argv,"hp:vdo:", ["help","bck-path=" ,"debug" ,"verbose" ,'output-file='])
  except getopt.GetoptError, e:
     print 'Error: '+e.msg
     help()
     sys.exit(2)

  action=1
  BCK_PATH = '/mnt/backups'
  BCK_STATUS_FILE = 'backup-status.yaml'
  ACTION="run"
  for opt, arg in opts:
     if opt in ('-h', '--help'):
        help()
        sys.exit()
     elif opt in ('-v','--verbose'):
        if oLogging.level >20:
           oLogging.setLevel(oLogging.level-10)
     elif opt in ('--debug','-d'):
        logging.getLogger().setLevel(logging.DEBUG)
        logging.debug("Setting debug mode")
        oLogging.setLevel(logging.DEBUG)
     elif opt in ('-p', '--bck-path'):
        BCK_PATH=arg
        action=1
     elif opt in ('-o', '--output-file'):
        BCK_STATUS_FILE=arg
        action=1

  if action == 0:
    logging.critical('Error: check options required.')
    help()
  else:
    LOG_FILE=os.path.join(BCK_PATH,'backup-status.log')
    if not os.path.isdir(BCK_PATH):
       logging.error("Unable write log file %s. Aborted.", LOG_FILE)
       sys.exit(1)
    handler=logging.FileHandler(LOG_FILE, mode='w')
    handler.setFormatter(logging.Formatter('%(asctime)s: %(levelname)s - %(message)s', '%m/%d/%Y %I:%M:%S %p'))
    oLogging.addHandler(handler)

    if BCK_STATUS_FILE == '-':
       # Permit to show info/Warning/errors/critical on err while status is printed out to standard output.
       logging.getLogger().setLevel(20)

    if ACTION == 'run':
       build_backup_status(BCK_PATH, BCK_STATUS_FILE)
  sys.exit()



#########################

# Define global oLogging object. 
#logging.basicConfig(format='%(asctime)s: %(levelname)s - %(message)s', datefmt='%m/%d/%Y %I:%M:%S %p')

if __name__ == "__main__":
   main(sys.argv[1:])


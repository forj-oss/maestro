#!/usr/bin/python

# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

import os.path
import subprocess
import sys
import logging
import Colorer

logger = ''


def setup_logging(logfile, loglevel):
    global logger
    if not logger:
        logger = logging.getLogger('createservercert')
    doFileLogging = True
    logint = getattr(logging, loglevel.upper())
    # file handler
    logfile_dir = os.path.basename(os.path.abspath(logfile))
    if not os.path.exists(logfile_dir):
        doFileLogging = False
    if doFileLogging:
        fch = logging.FileHandler(logfile)
        fch.setLevel(logint)
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        fch.setFormatter(formatter)
        logger.addHandler(fch)

    # console handler
    ch = logging.StreamHandler()
    ch.setLevel(logging.DEBUG)
    formatter = logging.Formatter('[%(name)s] %(message)s')
    ch.setFormatter(formatter)
    logger.addHandler(ch)
    if doFileLogging:
        logger.info("writing logfile to : " + logfile)


def openssl_cmd(action, site_name, cacerts_dir, options):
    try:
        global logger
        logger.debug("calling openssl_cmd action " + action)
        openssl_exe = "openssl"
        if action == "test":
            args = options
        elif action == "genrsa":
            inout_options = "-out " + site_name + ".key "
            args = action + " " + inout_options + " " + options
        elif action == "req":
            inout_options = "-key " + site_name + ".key -out " + site_name + ".csr"
            args = action + " " + inout_options + " " + options
        elif action == "ca":
            inout_options = "-out " + site_name + ".crt -infiles " + site_name + ".csr"
            args = action + " " + options + " " + inout_options
        elif action == "rsa":
            args = action + " " + options
        else:
            args = action

        logger.debug("calling sub on : " + openssl_exe + " " + args)
        logger.debug("calling it from folder: " + cacerts_dir)
        print openssl_exe + " " + args
        print "cwd = " + cacerts_dir
        print "command : " + openssl_exe + " " + args
        retcode = subprocess.call(openssl_exe + " " + args, shell=True, cwd=cacerts_dir)
        if not retcode == 0:
            logger.error("Command " + action + " failed!! " + str(retcode))
            sys.exit(1)
        else:
            logger.info("Command " + action + " completed successfully " + str(retcode))
    except OSError as e:
        logger.error("Execution failed: " + e)


def banner_start():
    global logger
    logger.info("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
    logger.info("  create_servercert -  generating a server certificate ....   ")
    logger.info("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")


def validate_directory(dir):
    if not os.path.exists(dir):
        logger.error("missing dir: " + dir)
        sys.exit(1)


def validate_file(file):
    if not os.path.isfile(file):
        logger.error("missing file: " + file)
        sys.exit(1)
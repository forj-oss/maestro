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
# -*- coding: utf-8 -*-
'''
 Module to provide MySQL compatibility to salt.

 :depends:   - MySQLdb Python module

'''
import traceback
from subprocess import check_call


HAS_MYSQLDB = False

try:
    import MySQLdb
    HAS_MYSQLDB = True
except ImportError:
    check_call(['sudo', 'apt-get', 'install', 'build-essential', 'python-dev', 'libmysqlclient-dev', '-y'])
    check_call(['sudo', 'apt-get', 'install', 'python-pip', '-y'])
    check_call(['sudo', 'pip', 'install', 'MySQL-python'])
    import MySQLdb
    HAS_MYSQLDB = True


def __virtual__():
    if HAS_MYSQLDB:
        return 'change_mysql_password'
    return False


def change_mysql_password(host_param, user_param, db_param, passwd_param, new_passwd_param):
    try:
        # hostname = socket.gethostbyname(socket.gethostname())
        connection = MySQLdb.connect(host=host_param, user=user_param, passwd=passwd_param, db=db_param)
    except:
        trace = traceback.format_exc()
        return trace
    else:
        query = u"SET PASSWORD FOR '%s'@'%s' = PASSWORD('%s')" % \
                (user_param, host_param, new_passwd_param)
        try:
            cursor = connection.cursor()
            cursor.execute(query)
        except:
            trace = traceback.format_exc()
            return trace
        else:
            cursor.close()
            connection.close()
            return "Password changed successfully"
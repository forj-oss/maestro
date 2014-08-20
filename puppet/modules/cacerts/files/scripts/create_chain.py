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
#
# Requires the following directory structure
# your_cacerts_dir/openssl.cnf
# your_cacerts_dir/serial
# your_cacerts_dir/private
# your_cacerts_dir/ca2013/private
# your_cacerts_dir/ca2013/certs
# your_cacerts_dir/ca2013/crl
# your_cacerts_dir/ca2013/newcerts
# your_cacerts_dir/ca2013/serial
#
# You can create them with the following shell commands:
# mkdir /tmp/cacerts
# cd /tmp/cacerts
# cp /usr/lib/ssl/openssl.cnf .
# sed -i 's/.\/demoCA/./g' openssl.cnf
# echo "01" > serial
# mkdir private ca2013
# cd ca2013
# mkdir certs crl newcerts private
# echo "01" > serial

#
# Run with this command: python /tmp/create_chain.py --loglevel debug --subject /C=US/ST=California/L=Roseville/O=HP/OU=PDE --domain forj.io --site review.hs --cacerts_dir /tmp/cacerts
# Good reading https://jamielinux.com/articles/2013/08/create-an-intermediate-certificate-authority/

import os.path
import argparse
import util
from shutil import copyfile
from pwd import getpwnam


def main():
    # http://docs.python.org/2/library/argparse.html
    global logger
    parser = argparse.ArgumentParser(description='Create a server certificate using the cacerts db.')
    parser.add_argument('--loglevel', help='Specify the default logging level (optional).', choices=['debug', 'info', 'warning', 'error', 'DEBUG', 'INFO', 'WARNING', 'ERROR'], default='info')
    parser.add_argument('--logfile', help='Specify logfile name.', default='/tmp/create_servercert.log')
    parser.add_argument('--cacerts_dir', help='alternate cacerts config dir.', default='../cacerts')
    parser.add_argument('--domain', help='The domain name.', default='forj.io')
    parser.add_argument('--site', help='The name of the site.', default='')
    parser.add_argument('--password', help='Specify a password (optional).', default='changeme')
    parser.add_argument('--subject', help='Specify the certificate subject info.', default='/C=US/ST=California/L=Roseville/O=HP/OU=PDE')
    parser.add_argument('--altnames', help='Specify alternative names like "/CN=server1/CN=server2"', default='')
    args = parser.parse_args()

    util.setup_logging(args.logfile, args.loglevel)
    cacerts_dir = os.path.abspath(args.cacerts_dir)
    ca2013_dir = os.path.abspath(os.path.join(cacerts_dir, "ca2013"))
    site_name = args.site + "." + args.domain
    subject = args.subject + "/CN=" + site_name

    util.validate_directory(cacerts_dir)
    util.validate_directory(ca2013_dir)
    util.validate_directory(ca2013_dir + "/private")
    util.validate_directory(ca2013_dir + "/certs")
    util.validate_directory(ca2013_dir + "/crl")
    util.validate_directory(ca2013_dir + "/newcerts")

    util.validate_file(cacerts_dir + "/openssl.cnf")
    util.validate_file(cacerts_dir + "/serial")
    util.validate_file(ca2013_dir + "/serial")

    # Creating root cert
    # Running at cacerts_dir
    copyfile("/dev/null", cacerts_dir + "/index.txt")
    print "(1)"
    util.openssl_cmd("genrsa -passout pass:" + args.password + " -des3 -out private/cakey.key 4096", "", cacerts_dir, "")
    copyfile(cacerts_dir + "/private/cakey.key", cacerts_dir + "/private/cakey.pem")
    print "(2)"
    util.openssl_cmd("req -passin pass:" + args.password + " -subj " + subject + " -new -x509 -nodes -sha1 -days 1825 -key private/cakey.key -out cacert.pem -config ./openssl.cnf", "", cacerts_dir, "")

    # Creating intermediate cert
    # Running at cacerts_dir/ca2013
    copyfile("/dev/null", ca2013_dir + "/index.txt")
    copyfile(cacerts_dir + "/openssl.cnf", ca2013_dir + "/openssl.cnf")
    print "(3)"
    util.openssl_cmd("genrsa -passout pass:" + args.password + " -des3 -out private/cakey.pem 4096", "", ca2013_dir, "")
    print "(4)"
    util.openssl_cmd("req -passin pass:" + args.password + " -subj " + subject + " -new -sha1 -key private/cakey.pem -out ca2013.csr -config ./openssl.cnf", "", ca2013_dir, "")
    print "(5)"
    util.openssl_cmd("ca -batch -extensions v3_ca -days 365 -out cacert.pem -in ca2013.csr -config openssl.cnf -key " + args.password + " -keyfile ../private/cakey.key -cert ../cacert.pem", "", ca2013_dir, "")
    copyfile(ca2013_dir + "/cacert.pem", ca2013_dir + "/chain.crt")
    file2 = open(cacerts_dir + "/cacert.pem", "rb")
    with open(ca2013_dir + "/chain.crt", "a") as myfile:
        myfile.write(file2.read())

    # Root and Intermediate certificates
    copyfile(cacerts_dir + "/cacert.pem", cacerts_dir + "/root.cer")
    copyfile(ca2013_dir + "/cacert.pem", cacerts_dir + "/intermediate.cer")

    # Permissions
    os.chmod(cacerts_dir + "/cacert.pem", 0755)
    os.chmod(cacerts_dir + "/intermediate.cer", 0755)
    os.chmod(cacerts_dir + "/root.cer", 0755)
    os.chmod(cacerts_dir + "/private/cakey.pem", 0400)
    os.chmod(cacerts_dir + "/ca2013/private/cakey.pem", 0755)
    os.chmod(cacerts_dir + "/private/cakey.key", 0755)
    os.chmod(cacerts_dir + "/ca2013/ca2013.csr", 0755)
    os.chmod(cacerts_dir + "/ca2013/cacert.pem", 0755)
    os.chmod(cacerts_dir + "/ca2013/chain.crt", 0755)
    os.chmod(cacerts_dir + "/index.txt", 0765)
    os.chmod(cacerts_dir + "/ca2013/index.txt", 0765)

    # TODO: create a recursive chown def
    uid = getpwnam('puppet').pw_uid
    gid = getpwnam('puppet').pw_gid
    os.chown(cacerts_dir + "/cacert.pem", uid, gid)
    os.chown(cacerts_dir + "/intermediate.cer", uid, gid)
    os.chown(cacerts_dir + "/root.cer", uid, gid)
    os.chown(cacerts_dir + "/private/cakey.pem", uid, gid)
    os.chown(cacerts_dir + "/ca2013/private/cakey.pem", uid, gid)
    os.chown(cacerts_dir + "/private/cakey.key", uid, gid)
    os.chown(cacerts_dir + "/ca2013/ca2013.csr", uid, gid)
    os.chown(cacerts_dir + "/ca2013/cacert.pem", uid, gid)
    os.chown(cacerts_dir + "/ca2013/chain.crt", uid, gid)
    os.chown(cacerts_dir + "/index.txt", uid, gid)
    os.chown(cacerts_dir + "/ca2013/index.txt", uid, gid)


if __name__ == '__main__':
    main()

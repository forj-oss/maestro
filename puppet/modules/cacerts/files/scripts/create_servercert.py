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
# Requires that create_chain.py runs first
# which creates root and intermediate certificates

# Run with this command: python /tmp/create_servercert.py --loglevel debug --subject /C=US/ST=California/L=Roseville/O=HP/OU=PDE --domain forj.io --site review.i5 --cacerts_dir /tmp/cacerts

import os.path
import argparse
import util
import sys


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
    util.banner_start()
    util.logger.debug("parsed arguments")
    util.logger.info("got folder " + args.cacerts_dir)
    cacerts_dir = os.path.abspath(args.cacerts_dir)

    util.validate_directory(cacerts_dir)
    cainter_dir = os.path.abspath(os.path.join(cacerts_dir, "ca2013"))
    util.validate_directory(cainter_dir)
    cakey_pem = os.path.abspath(os.path.join(cacerts_dir, "private/cakey.pem"))
    util.validate_file(cakey_pem)

    if not args.site:
        util.logger.error("found cakey_pem")
        sys.exit(1)

    source_dir = cainter_dir
    destin_dir = os.path.join(cainter_dir, 'certs')

    # http://docs.python.org/2/library/subprocess.html#replacing-older-functions-with-the-subprocess-module
    util.openssl_cmd("test", args.site, cainter_dir, 'version')

    # pushd /cacerts/ca2013
    #
    # [ -f ~/.rnd ] && sudo rm -f ~/.rnd
    # openssl genrsa -passout pass:xxxxxxxx -des3 -out $_SITE.key 2048 -config ./openssl.cnf
    # openssl req -passin pass:xxxxxxxx -new -key $_SITE.key -out $_SITE.csr -subj "/C=US/ST=California/L=Roseville/O=HP/OU=PDE/CN=$_SITE.forj.io" -config ./openssl.cnf
    # openssl ca -passin pass:xxxxxxxx -batch -config openssl.cnf -policy policy_anything -out $_SITE.crt -infiles $_SITE.csr
    subject = args.subject + "/CN=" + args.site + "." + args.domain + args.altnames
    util.openssl_cmd("genrsa", args.site + '.' + args.domain, cainter_dir, "-passout pass:" + args.password + " -des3 2048 -config ./openssl.cnf")
    util.openssl_cmd("req", args.site + '.' + args.domain, cainter_dir, "-passin pass:" + args.password + " -new -subj " + subject + " -config ./openssl.cnf")
    # -keyfile and -cert makes the linkage to intermediate certificate
    util.openssl_cmd("ca", args.site + '.' + args.domain, cainter_dir, "-passin pass:" + args.password + " -batch -config ./openssl.cnf -policy policy_anything -keyfile ./private/cakey.pem -cert ./cacert.pem")

    # cd cainter_dir
    # mv $_SITE.key $_SITE.csr $_SITE.crt certs
    extensions = ['.key', '.csr', '.crt']

    for ext in extensions:
        util.logger.debug("relocating " + args.site + ext)
        os.rename(os.path.join(source_dir, args.site + '.' + args.domain + ext),
                  os.path.join(destin_dir, args.site + '.' + args.domain + ext))

    # this is an ssl cert, remove the ssl password on the key....
    #  openssl rsa -passin pass:xxxxxxxx -in $_SITE.key -out $_FQDN.key
    key_in = os.path.join(destin_dir, args.site + '.' + args.domain + '.key')
    key_out = os.path.join(destin_dir, args.site + '.' + args.domain + '.key2')
    util.openssl_cmd("rsa", args.site, cainter_dir, "-passin pass:" + args.password + " -in " + key_in + " -out " + key_out)
    util.logger.debug("unlink : " + key_in)
    os.unlink(key_in)
    util.logger.debug("rename : " + key_out + " -> " + key_in)
    os.rename(key_out, key_in)

    # SSLCertificateFile /var/ca/ca2008/certs/{server_name}.crt
    # SSLCertificateKeyFile /var/ca/ca2008/certs/{server_name}.key
    # SSLCertificateChainFile /var/ca/ca2008/chain.crt


if __name__ == '__main__':
    main()

#!/bin/sh

# -----------------------------------------------------------------------------
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org>
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Compile nginx from source.
#
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# -----------------------------------------------------------------------------

# Include user configurable configuration.
. ./config.sh

# Download and extract given compressed tar archive.
#
# ARGS:
#   $1 - The URL path to the file on the remote server.
#   $2 - The name of the file.
#   $3 - The version string.
download_and_extract()
{
  # Use existing source files if version matches.
  if [ -d ${2}-${3} ]
  then
    return
  fi

  # We don't know which version these files have, delete and retrieve again.
  if [ -d ${2} ]
  then
    rm -rf ${2}
  fi

  # Build archive name.
  local ARCHIVE_NAME="${2}-${3}.tar.gz"

  # Delete possibly left over archive.
  if [ -f ${ARCHIVE_NAME} ]
  then
    rm -f ${ARCHIVE_NAME}
  fi

  # Download, extract, delete archive, simplify directory name by creating
  # a symbolic link and make sure files belong to root user.
  wget ${1}${ARCHIVE_NAME}
  tar fvxz ${ARCHIVE_NAME}
  rm -f ${ARCHIVE_NAME}
  ln -s ${2}-${3} ${2}
  chown root:root ${SOURCE_DIRECTORY}/${2}
  chown -R root:root ${SOURCE_DIRECTORY}/${2}
}

# Create directory and set nginx owner.
#
# ARGS:
#   $1 - Absolute path to the directory.
create_directory()
{
  if [ ! -d ${1} ]
  then
    mkdir -p ${1}
    chmod 0770 ${1}
    chown ${USER}:${GROUP} ${1}
  fi
}

# Check return status of every command.
set -e

echo "Installing nginx ${NGINX_VERSION} ..."

# Make sure we operate from the correct directory.
cd ${SOURCE_DIRECTORY}

# Download necessary sources.
download_and_extract 'http://nginx.org/download/' 'nginx' ${NGINX_VERSION}
download_and_extract 'ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/' 'pcre' ${PCRE_VERSION}

if [ ${TLS_LIBRARY_NAME} = 'openssl' ]
then
  download_and_extract 'http://www.openssl.org/source/' 'openssl' ${TLS_LIBRARY_VERSION}
elif [ ${TLS_LIBRARY_NAME} = 'boringssl' ]
then
  if [ -d 'boringssl' ]
  then
    cd boringssl
    git pull
    cd ..
  else
    git clone https://boringssl.googlesource.com/boringssl
  fi
elif [ ${TLS_LIBRARY_NAME} = 'libressl' ]
then
  echo 'TODO: libressl'
  exit 1
else
  echo "[$(tput bold; tput setaf 1)fail$(tput sgr0)] Unsupported TLS library '${TLS_LIBRARY_NAME}' specified, check your configuration."
  exit 1
fi

# Ensure zlib is up to date.
if [ -d "zlib" ]
then
  cd zlib
  git pull
  cd ..
else
  git clone "https://github.com/madler/zlib.git"
fi

# Configure, compile, and install nginx.
cd ${SOURCE_DIRECTORY}/nginx
CFLAGS='-O3 -m64 -march=native -ffunction-sections -fdata-sections -D FD_SETSIZE=131072' \
CXXFLAGS=${CFLAGS} \
CPPFLAGS=${CFLAGS} \
LDFLAGS='-Wl,--gc-sections' \
./configure \
  --user=${USER} \
  --group=${GROUP} \
  --prefix='/usr/local' \
  --sbin-path='/usr/local/sbin' \
  --conf-path='/etc/nginx/nginx.conf' \
  --pid-path='/run/nginx.pid' \
  --lock-path='/var/lock/nginx.lock' \
  --error-log-path='/var/log/nginx/error.log' \
  --http-client-body-temp-path='/var/nginx/uploads' \
  --http-fastcgi-temp-path='/var/nginx/fastcgi' \
  --http-log-path='/var/log/nginx/access.log' \
  --with-cc-opt=${CFLAGS} \
  --with-ld-opt=${LDFLAGS} \
  --with-ipv6 \
  --with-http_gzip_static_module \
  --with-http_ssl_module \
  --with-http_spdy_module \
  --with-openssl-opt='-DOPENSSL_NO_HEARTBEATS enable-ec_nistp_64_gcc_128 no-rc2 no-rc4 no-rc5 no-md2 no-md4 no-ssl2 no-ssl3 no-krb5 no-hw no-engines' \
  --with-openssl="${SOURCE_DIRECTORY}/${TLS_LIBRARY_NAME}" \
  --with-md5="${SOURCE_DIRECTORY}/${TLS_LIBRARY_NAME}" \
  --with-md5-asm \
  --with-sha1="${SOURCE_DIRECTORY}/${TLS_LIBRARY_NAME}" \
  --with-sha1-asm \
  --with-pcre="${SOURCE_DIRECTORY}/pcre" \
  --with-pcre-jit \
  --with-zlib="${SOURCE_DIRECTORY}/zlib" \
  --without-http_access_module \
  --without-http_auth_basic_module \
  --without-http_autoindex_module \
  --without-http_empty_gif_module \
  --without-http_geo_module \
  --without-http_memcached_module \
  --without-http_proxy_module \
  --without-http_referer_module \
  --without-http_scgi_module \
  --without-http_split_clients_module \
  --without-http_ssi_module \
  --without-http_upstream_ip_hash_module \
  --without-http_userid_module \
  --without-http_uwsgi_module
make
make install
make clean

# Create the directories for temporary data.
create_directory /var/nginx/uploads
create_directory /var/nginx/fastcgi

if [ ! -f /etc/init.d/nginx ]
then
  # Download SysVinit compliant script and ensure correct permissions and owner.
  wget -O /etc/init.d/nginx https://raw.githubusercontent.com/Fleshgrinder/nginx-sysvinit-script/master/nginx
  chmod 0775 /etc/init.d/nginx
  chown root:root /etc/init.d/nginx

  # Ensure nginx is started upon system startup.
  update-rc.d nginx defaults 2>&-
fi

# Stop any running nginx process.
set -e
service nginx stop 2>&-
set +e
service nginx start

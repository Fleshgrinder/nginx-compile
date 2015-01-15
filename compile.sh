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

# Print usage text.
#
# RETURN:
#  0 - Printing successful.
#  1 - Printing failed.
usage()
{
  cat << EOT
Usage: ${0##*/} [OPTION]... [TLS_LIBRARY_NAME]
Compile and install nginx from source.

  -h  Display this help and exit.

Report bugs to richard@fussenegger.info
GitHub repository: https://github.com/Fleshgrinder/nginx-compile
For complete documentation, see: README.md
EOT
}

# Check for possibly passed options.
while getopts 'h' OPT
do
  case "${OPT}" in
    h|[?]) usage && exit 0 ;;
  esac

  # We have to remove found options from the input for later evaluations of
  # passed arguments in subscripts that are not interested in these options.
  shift $(( $OPTIND - 1 ))
done

# Remove possibly passed end of options marker.
if [ "${1}" = "--" ]
then
  shift $(( $OPTIND - 1 ))
fi

# For more information on shell colors and other text formatting see:
# http://stackoverflow.com/a/4332530/1251219
readonly RED=$(tput bold; tput setaf 1)
readonly GREEN=$(tput bold; tput setaf 2)
readonly YELLOW=$(tput bold; tput setaf 3)
readonly NORMAL=$(tput sgr0)

# Include user configurable configuration.
. "$(cd -- "$(dirname -- "${0}")"; pwd)"/config.sh

# Install dependencies.
apt-get --yes -- install build-essential git

# Used to collect additional modules that should be added to nginx.
ADD_MODULES=''

# Add additional module to nginx.
#
# ARGS:
#   $1 - The name of the directory within the source directory.
add_module()
{
  ADD_MODULES="${ADD_MODULES}--add-module=${SOURCE_DIRECTORY}/${1} "
}

# Create directory and set nginx owner.
#
# ARGS:
#   $1 - Absolute path to the directory.
create_directory()
{
  mkdir --parents -- "${1}"
  chmod -- 0755 "${1}"
  chown -- "${USER}":"${GROUP}" "${1}"
}

# Clone git repository (or pull changes if it already exists).
#
# ARGS:
#   $1 - User name
#   $2 - Repository name
git_clone()
{
  if [ -d "${SOURCE_DIRECTORY}/${2}/.git" ]
  then
    cd -- "${SOURCE_DIRECTORY}/${2}"
    git pull
    cd -- "${SOURCE_DIRECTORY}"
  else
    rm --recursive --force -- "${SOURCE_DIRECTORY}/${1}"
    git clone "https://github.com/${1}/${2}.git"
  fi
}

# Download and extract given compressed tar archive.
#
# ARGS:
#   $1 - The URL path to the file on the remote server.
#   $2 - The name of the file.
#   $3 - The version string.
download_and_extract()
{
  # Use existing source files if version matches.
  if [ -d "${2}-${3}" ]
  then
    return 0
  fi

  # We don't know which version these files have, delete and retrieve again.
  rm --force --recursive -- "${2}"

  # Build archive name.
  local ARCHIVE_NAME="${2}-${3}.tar.gz"

  # Delete possibly left over archive.
  rm --force -- "${ARCHIVE_NAME}"

  # Download, extract, delete archive, simplify directory name by creating
  # a symbolic link and make sure files belong to root user.
  wget -- "${1}${ARCHIVE_NAME}"
  tar --extract --file="${ARCHIVE_NAME}"
  rm --force -- "${ARCHIVE_NAME}"
  ln --symbolic -- "${2}-${3}" "${2}"
  chown -- root:root "${SOURCE_DIRECTORY}/${2}"
  chown --recursive -- root:root "${SOURCE_DIRECTORY}/${2}"
}

# Check return status of every command.
set -e

printf -- 'Installing nginx %s ...\n' "${YELLOW}${NGINX_VERSION}${NORMAL}"

# Make sure we operate from the correct directory.
cd -- "${SOURCE_DIRECTORY}"

if [ $NGINX_VERSION = false ]
then
  git_clone Fleshgrinder nginx
else
  download_and_extract 'http://nginx.org/download/' 'nginx' "${NGINX_VERSION}"
fi

download_and_extract 'ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/' 'pcre' "${PCRE_VERSION}"

case "${TLS_LIBRARY_NAME}" in
  openssl)
    download_and_extract 'http://www.openssl.org/source/' 'openssl' "${TLS_LIBRARY_VERSION}"
  ;;

  boringssl)
#     if [ -d 'boringssl' ]
#     then
#      cd -- boringssl
#      git pull
#      cd -- ..
#    else
#      git clone 'https://boringssl.googlesource.com/boringssl'
#    fi
    printf '%sTODO:%s boringssl' "${YELLOW}" "${NORMAL}" >&2
    exit 1
  ;;

  libressl)
    printf '%sTODO:%s libressl' "${YELLOW}" "${NORMAL}" >&2
    exit 1
  ;;

  *)
    printf '[%sfail%s] Unsupported TLS library `%s` specified, check your configuration.\n' \
      "${RED}" "${NORMAL}" "${TLS_LIBRARY_NAME}" >&2
    exit 1
  ;;
esac

# Ensure zlib is up to date.
if [ -d zlib ]
then
  cd -- "${SOURCE_DIRECTORY}/zlib"
  git pull
  cd -- "${SOURCE_DIRECTORY}"
else
  git clone 'https://github.com/madler/zlib.git'
fi

if [ ${ACCEPT_LANGUAGE} = true ]
then
  git_clone Fleshgrinder nginx_accept_language_module
fi

if [ ${GOOGLE_PAGESPEED} = true ]
then
  git_clone pagespeed ngx_pagespeed
  if [ !-d "${SOURCE_DIRECTORY}/ngx_pagespeed/psol" ]
  then
    cd -- "${SOURCE_DIRECTORY}/ngx_pagespeed"
    wget -- "https://dl.google.com/dl/page-speed/psol/${GOOGLE_PAGESPEED_VERSION}.tar.gz"
    tar --extract --file="${SOURCE_DIRECTORY}/ngx_pagespeed/${GOOGLE_PAGESPEED_VERSION}.tar.gz"
    rm --force -- "${SOURCE_DIRECTORY}/ngx_pagespeed/${GOOGLE_PAGESPEED_VERSION}.tar.gz"
    cd -- "${SOURCE_DIRECTORY}"
    chown --recursive -- root:root "${SOURCE_DIRECTORY}/ngx_pagespeed/psol"
    chmod --recursive -- 0755 "${SOURCE_DIRECTORY}/ngx_pagespeed/psol"
    find "${SOURCE_DIRECTORY}/ngx_pagespeed/psol" -type f -exec chmod 644 {} \;
  fi
fi

# Configure, compile, and install nginx.
cd -- "${SOURCE_DIRECTORY}/nginx"
CFLAGS='-O3 -pipe -m64 -march=native -mtune=native -fdata-sections -ffunction-sections -fexceptions -fstack-protector --param=ssp-buffer-size=4 -Wp,-D_FORTIFY_SOURCE=2 -DFD_SETSIZE=131072' \
CXXFLAGS="${CFLAGS}" \
CPPFLAGS="${CFLAGS}" \
LDFLAGS='-Wl,--gc-sections' \
./configure \
  --user="${USER}" \
  --group="${GROUP}" \
  --prefix='/usr/local' \
  --sbin-path='/usr/local/sbin' \
  --conf-path='/etc/nginx/nginx.conf' \
  --pid-path='/run/nginx.pid' \
  --lock-path='/var/lock/nginx.lock' \
  --error-log-path='/var/log/nginx/error.log' \
  --http-client-body-temp-path='/var/nginx/uploads' \
  --http-fastcgi-temp-path='/var/nginx/fastcgi' \
  --http-log-path='/var/log/nginx/access.log' \
  --with-cc-opt="${CFLAGS}" \
  --with-ld-opt="${LDFLAGS}" \
  --with-debug \
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
  ${ADD_MODULES} \
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

# Create the directories for temporary data.
create_directory /var/nginx/uploads
create_directory /var/nginx/fastcgi

if [ ! -f /etc/init.d/nginx ]
then
  # Download SysVinit compliant script and ensure correct permissions and owner.
  wget --output-document=/etc/init.d/nginx 'https://raw.githubusercontent.com/Fleshgrinder/nginx-sysvinit-script/master/nginx'
  chmod -- 0775 /etc/init.d/nginx
  chown -- root:root /etc/init.d/nginx

  # Ensure nginx is started upon system startup.
  update-rc.d nginx defaults
fi

set -e
service nginx stop 2>/dev/null
set +e

make install
service nginx start
make clean

printf '[%sok%s] Installation finished.\n' "${GREEN}" "${NORMAL}"
exit 0

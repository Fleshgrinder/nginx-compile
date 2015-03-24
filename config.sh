#!/bin/sh

# ------------------------------------------------------------------------------
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or # distribute
# this software, either in source code form or as a compiled binary, for any
# purpose, commercial or non-commercial, and by any means.
#
# In jurisdictions that recognize copyright laws, the author or authors of this
# software dedicate any and all copyright interest in the software to the public
# domain. We make this dedication for the benefit of the public at large and to
# the detriment of our heirs and successors. We intend this dedication to be an
# overt act of relinquishment in perpetuity of all present and future rights to
# this software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org>
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Configuration file for nginx-compile scripts.
#
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013-15 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
#                                                           COMMON CONFIGURATION
# ------------------------------------------------------------------------------


# The version string of the nginx release that should be installed.
# Defaults to `false` and the code is cloned from my personal repository.
readonly NGINX_VERSION=false

# Whether to perform an on-the-fly upgrade or not.
readonly NGINX_ONTHEFLY_UPGRADE=true

# The version string of the PCRE release that should be installed.
readonly PCRE_VERSION='8.36'

# The name of the SSL/TLS library nginx should be compiled against.
#
# Possible values: 'openssl' (default), 'boringssl', and 'libressl'
#
# IMPORTANT! Right now only 'openssl' is supported, so do not touch.
readonly TLS_LIBRARY_NAME="${1:-openssl}"

# The version string of the SSL/TLS library release that should be installed.
readonly TLS_LIBRARY_VERSION='1.0.2a'

# Determines if the Accept-Language module should be compiled or not.
readonly ACCEPT_LANGUAGE=true

# Determines if the Google PageSpeed module should be compiled or not.
readonly GOOGLE_PAGESPEED=true

# The version string of the Google PageSpeed library.
readonly GOOGLE_PAGESPEED_VERSION='1.9.32.3'

# The name of the user nginx should use.
readonly USER='www-data'

# The name of the group nginx should use.
readonly GROUP="${USER}"


# ------------------------------------------------------------------------------
#                                                           CUSTOM CONFIGURATION
# ------------------------------------------------------------------------------


# Whether to install the SysVinit script or not.
readonly NGINX_INITD=true

# Please see official nginx documentation for all of the following or check out
# the configure call at the bottom of this script.
readonly NGINX_PREFIX='/usr/local'
readonly NGINX_SBIN_PATH="${NGINX_PREFIX}/sbin"
readonly NGINX_CONF_PATH='/etc/nginx'
readonly NGINX_PID_PATH='/run/nginx.pid'
readonly NGINX_LOCK_PATH='/run/nginx.lock'
readonly NGINX_LOG_PATH='/var/log/nginx'
readonly NGINX_TMP_PATH='/tmp'

# Additional flags that should be passed to the C compiler.
NGINX_CLFAGS="-O2 -march=native -pipe -DFD_SETSIZE=131072"

# Add 64bit option to C compiler flags if applicable.
[ $(uname -m) = 'x86_x64' ] && CFLAGS="${CFLAGS} -m64"

# Additional flags that should be passed to the linker.
NGINX_LDFLAGS=

# Options to pass to the TLS library.
readonly TLS_LIBRARY_OPTIONS='-DOPENSSL_NO_HEARTBEATS enable-ec_nistp_64_gcc_128 no-rc2 no-rc4 no-rc5 no-md2 no-md4 no-ssl2 no-ssl3 no-krb5 no-hw no-engines'

# The absolute path to the downloaded and extracted source files.
readonly SOURCE_DIRECTORY='/usr/local/src'

# Absolute path to the nginx init.d script.
readonly INITD_PATH='/etc/init.d/nginx'


# ------------------------------------------------------------------------------
#                                              INTERNAL VARIABLES (DO NOT TOUCH)
# ------------------------------------------------------------------------------


# For more information on shell colors and other text formatting see:
# https://stackoverflow.com/a/4332530/1251219
readonly RED=$(tput bold; tput setaf 1)
readonly GREEN=$(tput bold; tput setaf 2)
readonly YELLOW=$(tput bold; tput setaf 3)
readonly BLUE=$(tput bold; tput setaf 4)
readonly NORMAL=$(tput sgr0)

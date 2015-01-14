#!/bin/sh

# ------------------------------------------------------------------------------
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
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Configuration file for nginx compile scripts.
#
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# ------------------------------------------------------------------------------

# The version string of the nginx release that should be installed.
readonly NGINX_VERSION='1.7.9'

# The version string of the PCRE release that should be installed.
readonly PCRE_VERSION='8.36'

# The name of the SSL/TLS library nginx should be compiled against.
#
# Possible values: openssl (default), boringssl. libressl
readonly TLS_LIBRARY_NAME="${1:-openssl}"

# The version string of the SSL/TLS library release that should be installed.
readonly TLS_LIBRARY_VERSION='1.0.1k'

# The version string of the Google PageSpeed library.
readonly GOOGLE_PAGESPEED_VERSION='1.9.32.3'

# The name of the user nginx should use.
readonly USER='www-data'

# The name of the group nginx should use.
readonly GROUP='www-data'

# The absolute path to the downloaded and extracted source files.
readonly SOURCE_DIRECTORY='/usr/local/src'

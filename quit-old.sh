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
# Stop old nginx instance and use the new one.
#
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013-15 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# ------------------------------------------------------------------------------

# Load the configuration.
. "$(cd -- "$(dirname -- "${0}")"; pwd)/config.sh"

# Find PIDs of old and new nginx.
readonly NGINX_OLD_PID_PATH="${NGINX_PID_PATH}.oldbin"
readonly NGINX_NEW_PID=$(cat "${NGINX_PID_PATH}")
readonly NGINX_OLD_PID=$(cat "${NGINX_OLD_PID_PATH}")

# Ask the old nginx to quit.
kill -28 "${NGINX_OLD_PID}" || exit 64

# Give it some time to shut down.
sleep 1

# Ask it to quit.
kill -3 "${NGINX_OLD_PID}" || exit 65

# Give it some time to quit.
sleep 0.1

# Remove the old binary.
rm "${NGINX_SBIN_PATH}/nginx.oldbin"

exit 0

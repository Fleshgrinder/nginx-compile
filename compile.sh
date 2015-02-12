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
# Compile nginx from source.
#
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013-15 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
#                                                                    ERROR CODES
# ------------------------------------------------------------------------------


# More or less a catch-all error code for simple commands like rm, cd, ...
readonly EC_SYSTEM_CALL_FAILED=64

readonly EC_SUPERUSER_ONLY=65
readonly EC_UNKNOWN_OPTION=66
readonly EC_DEPENDENCY_FAIL=67
readonly EC_SRCDIR_MISSING=68
readonly EC_DL_NGINX_FAIL=69
readonly EC_DL_PCRE_FAIL=70
readonly EC_DL_ZLIB_FAIL=71
readonly EC_UNSUPPORTED_TLSLIB=72
readonly EC_DL_TLSLIB_FAIL=73
readonly EC_DL_NALM_FAIL=74
readonly EC_DL_GPSNM_FAIL=75
readonly EC_DL_PSOL_FAIL=76
readonly EC_CONFIGURE_FAIL=77
readonly EC_MAKE_FAIL=78
readonly EC_MKDIR_FAIL=79
readonly EC_DL_INITD_FAIL=80


# ------------------------------------------------------------------------------
#                                              INTERNAL VARIABLES (DO NOT TOUCH)
# ------------------------------------------------------------------------------


# Name of this script.
readonly __FILENAME__="${0##*/}"

# Directory where this script resides (not necessarily the same as CWD).
readonly __DIRNAME__="$(cd -- "$(dirname -- "${0}")"; pwd)"

# Used to collect additional modules that should be added to nginx.
ADD_MODULES=''


# ------------------------------------------------------------------------------
#                                                                      FUNCTIONS
# ------------------------------------------------------------------------------


# Add additional module to nginx.
#
# ARGS:
#   $1 - The name of the directory within the source directory.
add_module()
{
    log_info "Adding nginx module ${YELLOW}${1}${NORMAL} ..."
    ADD_MODULES="${ADD_MODULES}--add-module=${SOURCE_DIRECTORY}/${1} "
}

# Create directory and set nginx owner.
#
# ARGS:
#   $1 - Absolute path to the directory.
# RETURNS:
#    0 - Success
#   64 - Failure
create_directory()
{
    log_info "Creating directory ${YELLOW}${1}${NORMAL} ..."
    mkdir --parents -- "${1}" || return 64
    chmod -- 0755 "${1}" || return 64
    chown -- "${USER}":"${GROUP}" "${1}" || return 64

    return 0
}

# Exit script with an error code.
#
# ARGS:
#   $1 - Desriptive human readable error message.
#   $2 - Exit code.
# RETURNS:
#   ALWAYS exits the script with the code provided as second argument.
die()
{
    log_failure "${1}"
    exit ${2}
}

# Download and extract given compressed, versioned tar archive.
#
# ARGS:
#   $1 - The URL to the file on the remote server.
#   $2 - The name of the file.
#   $3 - The version string.
# RETURNS:
#    0 - Downloading and extracting successfull.
#   64 - Misc operation failed.
#   65 - Downloading failed.
#   66 - Extracting failed.
download_and_extract()
{
    local SOURCE_PATH="${SOURCE_DIRECTORY}/${2}"
    local SOURCE_PATH_VERSIONED="${SOURCE_PATH}-${3}"

    # Use existing source files if version matches.
    [ -d "${SOURCE_PATH_VERSIONED}" ] && return 0

    log_info "Downloading ${YELLOW}${2} ${3}${NORMAL} ..."

    local ARCHIVE_FILENAME="${2}-${3}.tar.gz"
    local ARCHIVE_PATH="${SOURCE_DIRECTORY}/${ARCHIVE_FILENAME}"

    # Delete any left overs of old versions (note the star at the end).
    rm --force --recursive -- "${SOURCE_PATH}"* || return 64

    # Download, extract, and delete source archive.
    wget --output-document="${ARCHIVE_PATH}" -- "${1}${ARCHIVE_FILENAME}" || return 65
    tar --extract --file="${ARCHIVE_PATH}" || return 66
    rm --force -- "${ARCHIVE_PATH}" || return 64

    # Make sure files belong to root and create a symbolic link without the
    # version number for unified access to the source files.
    chown --recursive -- root:root "${SOURCE_PATH_VERSIONED}" || return 64
    ln --symbolic -- "${SOURCE_PATH_VERSIONED}" "${SOURCE_PATH}" || return 64

    return 0
}

# Clone git repository (or pull changes if it already exists).
#
# ARGS:
#   $1 - User name
#   $2 - Repository name
# RETURNS:
#    0 - Cloning or pulling succefull.
#   64 - Misc operation failed.
#   65 - Pulling failed.
#   66 - Cloning failed.
git_clone()
{
    local REPOSITORY_PATH="${SOURCE_DIRECTORY}/${2}"

    if [ -d "${REPOSITORY_PATH}/.git" ]
    then
        log_info "Updating ${YELLOW}${2}${NORMAL} via git ..."
        git -C "${REPOSITORY_PATH}" pull || return 65
    else
        log_info "Downloading ${YELLOW}${2}${NORMAL} via git ..."
        rm --recursive --force -- "${REPOSITORY_PATH}" || return 64
        git clone "https://github.com/${1}/${2}.git" "${REPOSITORY_PATH}" || return 66
    fi

    return 0
}

# Log message.
#
# ARGS:
#   $1 - Message.
log()
{
    printf -- '%s\n' "${1}"
}

# Log failure message but do not exit.
#
# ARGS:
#   $1 - Failure message.
log_failure()
{
    printf -- '[%sfail%s] %s\n' "${RED}" "${NORMAL}" "${1}" >&2
}

# Log informational message.
#
# ARGS:
#   $1 - Informational message
log_info()
{
    printf -- '[%sinfo%s] %s\n' "${YELLOW}" "${NORMAL}" "${1}"
}

# Log success message.
#
# ARGS:
#   $1 - Success message.
log_ok()
{
    printf -- '[%s ok %s] %s\n' "${GREEN}" "${NORMAL}" "${1}"
}

# Log to do message.
#
# ARGS:
#   $1 - To do message.
log_todo()
{
    printf -- '[%stodo%s] %s\n' "${BLUE}" "${NORMAL}" "${1}" >&2
}

# Print usage text.
usage()
{
    cat << EOT
Usage: ${__FILENAME__} [OPTION]... [TLS_LIBRARY_NAME]
Compile and install nginx from source.

    -h -?   Display this help and exit.

Report bugs to richard@fussenegger.info
GitHub repository: https://github.com/Fleshgrinder/nginx-compile
For complete documentation, see: README.md
EOT
}


# ------------------------------------------------------------------------------
#                                                                      BOOTSTRAP
# ------------------------------------------------------------------------------


if [ $(id -u) -ne 0 ]
    then die 'Super user only!' ${EC_SUPERUSER_ONLY}
fi

# Check for possibly passed options.
while getopts 'h' OPT
do
    case "${OPT}" in
        h|[?]) usage && exit 0 ;;
        *) usage >2 && exit ${EC_UNKNOWN_OPTION} ;;
    esac

    # We have to remove found options from the input for later evaluations of
    # passed arguments in subscripts that are not interested in these options.
    shift $(( $OPTIND - 1 ))
done

# Remove possibly passed end of options marker.
if [ "${1}" = '--' ]
    then shift $(( $OPTIND - 1 ))
fi

# Load the configuration.
. "${__DIRNAME__}/config.sh"

log 'Starting nginx compilation, this might take several minutes ...'


# ------------------------------------------------------------------------------
#                                          PREPARE DEPENDENCIES AND SOURCE FILES
# ------------------------------------------------------------------------------


log_info 'Installing dependencies ...'
apt-get --yes -- install build-essential git || die 'Installing dependencies failed.' ${EC_DEPENDENCY_FAIL}

cd -- "${SOURCE_DIRECTORY}" || die "Could not change to source directory '${SOURCE_DIRECTORY}', check configuration." ${EC_SRCDIR_MISSING}

if [ ${NGINX_VERSION} = false ]
then
    git_clone Fleshgrinder nginx || die 'Could not download nginx sources.' ${EC_DL_NGINX_FAIL}
else
    download_and_extract 'http://nginx.org/download/' 'nginx' "${NGINX_VERSION}" || die 'Could not download nginx sources.' ${EC_DL_NGINX_FAIL}
fi

download_and_extract 'ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/' 'pcre' "${PCRE_VERSION}" || die 'Could not download PCRE sources.' ${EC_DL_PCRE_FAIL}

git_clone madler zlib || die 'Could not download ZLIB sources.' ${EC_DL_ZLIB_FAIL}

case "${TLS_LIBRARY_NAME}" in
    openssl)
        download_and_extract 'http://www.openssl.org/source/' 'openssl' "${TLS_LIBRARY_VERSION}" || die 'Could not download OpenSSL sources.' ${EC_DL_TLSLIB_FAIL}
    ;;

    boringssl|libressl)
        log_todo "Implement ${TLS_LIBRARY_NAME} support, please open an issue if you are interested in this."
        exit ${EC_UNSUPPORTED_TLSLIB}
    ;;

    *)
        die "Unsupported TLS library '${RED}${TLS_LIBRARY_NAME}${NORMAL}' specified, check configuration." ${EC_UNSUPPORTED_TLSLIB}
;;
esac

if [ ${ACCEPT_LANGUAGE} = true ]
    then git_clone Fleshgrinder nginx_accept_language_module || die 'Could not download nginx-accept-language-module sources.' ${EC_DL_NALM_FAIL}
fi

if [ ${GOOGLE_PAGESPEED} = true ]
then
    readonly PSOL="${SOURCE_DIRECTORY}/ngx_pagespeed/psol"
    readonly PSOL_ARCHIVE="${SOURCE_DIRECTORY}/ngx_pagespeed/${GOOGLE_PAGESPEED_VERSION}.tar.gz"

    git_clone pagespeed ngx_pagespeed || die 'Could not download Google PageSpeed module sources.' ${EC_DL_GPSNM_FAIL}

    if [ !-d "${PSOL}" ]
    then
        log_info "Downloading Google ${BLUE}PSOL ${GOOGLE_PAGESPEED_VERSION}${NORMAL} ..."

        wget -- "https://dl.google.com/dl/page-speed/psol/${GOOGLE_PAGESPEED_VERSION}.tar.gz" || die 'Could not download PSOL sources.' ${EC_DL_PSOL_FAIL}
        tar --extract --file="${PSOL_ARCHIVE}" || exit ${EC_SYSTEM_CALL_FAILED}
        rm --force -- "${PSOL_ARCHIVE}" || exit ${EC_SYSTEM_CALL_FAILED}

        chown --recursive -- root:root "${PSOL}" || exit ${EC_SYSTEM_CALL_FAILED}
        chmod --recursive -- 0755 "${PSOL}" || exit ${EC_SYSTEM_CALL_FAILED}
        find "${PSOL}" -type f -exec chmod 644 {} \; || exit ${EC_SYSTEM_CALL_FAILED}
    fi
fi


# ------------------------------------------------------------------------------
#                                                            CONFIGURE & COMPILE
# ------------------------------------------------------------------------------


# Rescue existing nginx configuration.
[ -d /etc/nginx ] && mv /etc/nginx /etc/.nginx

# Configure nginx installation.
cd -- "${SOURCE_DIRECTORY}/nginx"
./configure \
    --user="${USER}" \
    --group="${GROUP}" \
    --prefix="${NGINX_PREFIX}" \
    --sbin-path="${NGINX_SBIN_PATH}" \
    --conf-path="${NGINX_CONF_PATH}/nginx.conf" \
    --pid-path="${NGINX_PID_PATH}" \
    --lock-path="${NGINX_LOCK_PATH}" \
    --error-log-path="${NGINX_LOG_PATH}/error.log" \
    --http-client-body-temp-path="${NGINX_HTTP_CLIENT_BODY_TEMP_PATH}" \
    --http-fastcgi-temp-path="${NGINX_HTTP_FASTCGI_TEMP_PATH}" \
    --http-log-path="${NGINX_LOG_PATH}/access.log" \
    --with-cc-opt="${NGINX_CLFAGS}" \
    --with-ld-opt="${NGINX_LDFLAGS}" \
    --with-file-aio \
    --with-ipv6 \
    --with-http_gzip_static_module \
    --with-http_ssl_module \
    --with-http_spdy_module \
    --with-openssl-opt="${TLS_LIBRARY_OPTIONS}" \
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
    --without-http_uwsgi_module \
    || die 'Could not configure nginx.' ${EC_CONFIGURE_FAIL}

# Compile configured nginx.
make || die 'Could not compile nginx.' ${EC_MAKE_FAIL}

# Restore existing nginx configuration.
[ -d /etc/nginx ] && mv /etc/nginx /etc/nginx/dist
[ -d /etc/.nginx ] && mv /etc/.nginx /etc/nginx

# Create the directories for temporary data.
create_directory "${NGINX_HTTP_CLIENT_BODY_TEMP_PATH}" || die 'Could not create HTTP client body temp path directory.' ${EC_MKDIR_FAIL}
create_directory "${NGINX_HTTP_FASTCGI_TEMP_PATH}" || die 'Could not create HTTP FastCGI temp path directory.' ${EC_MKDIR_FAIL}


# ------------------------------------------------------------------------------
#                                                                        INSTALL
# ------------------------------------------------------------------------------


# Install SysVinit script if applicable.
if [ ${NGINX_INITD} = true ] && [ ! -f "${INITD_PATH}" ]
then
    # Download SysVinit compliant script and ensure correct permissions and owner.
    wget --output-document="${INITD_PATH}" 'https://raw.githubusercontent.com/Fleshgrinder/nginx-sysvinit-script/master/nginx' \
        || die 'Could not download SysVinit script.' ${EC_DL_INITD_FAIL}
    chmod -- 0775 "${INITD_PATH}" || exit ${EC_SYSTEM_CALL_FAILED}
    chown -- root:root "${INITD_PATH}" || exit ${EC_SYSTEM_CALL_FAILED}

    # Ensure nginx is started upon system startup.
    update-rc.d nginx defaults || exit ${EC_SYSTEM_CALL_FAILED}
fi

# Check if an nginx is already installed.
OLDBIN=$(command -v nginx)
if [ $? -eq 0 ]
then
    # We'll only try an on the fly upgrade if the PID locations of the old and
    # new nginx are the same. Otherwise the SysVinit script that we provide will
    # most certainly not pick the PID file up and other edge cases may arise.
    if [ -f "${NGINX_PID_PATH}" ]
        then readonly OLDBIN_PID_PATH="${NGINX_PID_PATH}.oldbin"
    else
        # Could be it is not running right now.
        log_info 'Could not find PID file of old nginx installation.'
    fi

    if [ ${NGINX_ONTHEFLY_UPGRADE} = true ] && [ -n "${OLDBIN_PID_PATH}" ]
    then
        # Move the old executable to a new place and avoid text file busy errors.
        mv "${OLDBIN}" "${OLDBIN}.oldbin" || die 'Could not move old nginx.' ${EC_SYSTEM_CALL_FAILED}
        OLDBIN="${OLDBIN}.oldbin"

        # Now we can install the new nginx.
        make install || die 'Could not install nginx.' ${EC_MAKE_FAIL}

        # Retrieve the actual PID of the old binary.
        readonly OLDBIN_PID=$(cat "${NGINX_PID_PATH}")

        # Next we need to send the USR2 signal to the old nginx installation. For
        # more details please refer to: http://nginx.org/en/docs/control.html#upgrade
        kill -12 "${OLDBIN_PID}" || die 'Could not send USR2 signal to old nginx.' ${EC_SYSTEM_CALL_FAILED}

        cat << EOT
[${GREEN} ok ${NORMAL}] Finished on-the-fly upgrade.

You now have two nginx instances up and running serving your websites.

If you are happy with your new nginx, execute the following script:
${GREEN}${__DIRNAME__}/quit-old.sh${NORMAL}*

If you want to roll back to your old nginx, execute the following script:
${GREEN}${__DIRNAME__}/rollback.sh${NORMAL}*

For more information please refer to the official documentation:
${YELLOW}http://nginx.org/en/docs/control.html#upgrade${NORMAL}

EOT
    else
        if [ -f /etc/init.d/nginx ] && service nginx status 2>/dev/null 1>/dev/null
        then
            # Old nginx is up and running but also has an init script, we have no
            # clue where the PID file resides, let's give it a shot ...
            log_info 'Attempting to stop old nginx process and install new one ...'
            service nginx stop || die 'Could not stop old nginx.' ${EC_SYSTEM_CALL_FAILED}
            make install || die 'Could not install nginx.' ${EC_MAKE_FAIL}
        else
            # Hopefully old nginx is simply not running, in which case this will
            # work; other possibilities include PID file in non-standard directory,
            # lingering daemon, and much more ...
            log_info 'Attempting to install new nginx ...'
            make install || die 'Could not install nginx.' ${EC_MAKE_FAIL}
        fi

        if [ -f "${INITD_PATH}" ]
            then service nginx start || die 'Could not start nginx.' ${EC_MAKE_FAIL}
        fi
    fi
fi


# ------------------------------------------------------------------------------
#                                                                        SUCCESS
# ------------------------------------------------------------------------------


cat << EOT
[${GREEN} ok ${NORMAL}] Succesfully installed nginx.

CONF:  ${BLUE}/etc/nginx${NORMAL}
BIN:   ${GREEN}/usr/local/sbin/nginx${NORMAL}*
PID:   ${BLUE}/run/nginx.pid${NORMAL}

You might want to check out ${YELLOW}https://github.com/Fleshgrinder/nginx-configuration${NORMAL}.
You also might want to delete the source files in ${BLUE}${SOURCE_DIRECTORY}${NORMAL}.

EOT

exit 0

#!/bin/bash
# -*- coding: utf-8 -*-

########################################
# Please modify those parameter.
########################################
# Emacs version you want to install.
readonly EMACS_VERSION=emacs-25.3
# Path to install directory. Cygwin style path.
readonly EMACS_INSTALL_DIR=/cygdrive/c/Tools/tmp/${EMACS_VERSION}
#readonly EMACS_INSTALL_DIR=/usr/local
# Working Directory.
readonly BUILD_BASE_DIR=/tmp


########################################
# Don't modify the follows.
########################################
readonly BUILD_DIR=${BUILD_BASE_DIR}/${EMACS_VERSION}

readonly OK_PREFIX="[ \033[32mOK    \033[0m ]"
readonly ERROR_PREFIX="[ \033[31mERROR \033[0m ]"
readonly NOTICE_PREFIX="[ \033[34mNOTICE\033[0m ]"


########################################
# Functions
########################################
function usage
{
    echo -e "Usage: `basename $0` [--full|--buildonly|--install|--help] w64|cygwin
    Build and install the emacs with apply IME patch at Cygwin.

    Target:
        w64    : build the emacs without depends on the cygwin1.dll.
        cygwin : build the emacs depends on the Cygwin.

    Options:
        --full      : download emacs sources and build it.
        --buildonly : build only. this mode is default.
        --install   : install emacs.
        --help      : show this help message.
    "
}

function detect_duplication_of_mode
{
    local mode=$1
    if [[ $mode == "none" ]]; then
        return 0
    else
        return 1
    fi
}

function download_emacs_sources
{
    git clone --depth 1 -b ${EMACS_VERSION} http://git.savannah.gnu.org/git/emacs.git

    if [[ ! -d emacs ]]; then
        echo -e "${ERROR_PREFIX} Failed to download emacs sources."
        exit 1
    fi
}

function patch_to_sources
{
    base_url="https://gist.github.com/rzl24ozi"

    # emacs-25.3-w32-ime.diff
    patch_to_sources_w32_ime ${base_url}

    # emacs-25.3-disable-w32-ime.diff
    patch_to_sources_disable-w32-ime ${base_url}

    # emacs-25.3-cygwin-rsvg.diff
    patch_to_sources_cygwin_rsvg ${base_url}
}

function patch_to_sources_w32_ime
{
    local base_url=$1
    local w32_ime="8c20b904c9f5e588ba99"
    git clone ${base_url}/${w32_ime}
    patch -p0 < ${w32_ime}/emacs-25.3-w32-ime.diff
}

function patch_to_sources_disable-w32-ime
{
    local base_url=$1
    local disable_w32_ime="76aadcfc58404d9e7326"
    git clone ${base_url}/${disable_w32_ime}
    patch -p0 < ${disable_w32_ime}/emacs-25.3-disable-w32-ime.diff
}

function patch_to_sources_cygwin_rsvg
{
    local base_url=$1
    local cygwin_rsvg="b0165eaf404a0c5a47ae"
    git clone ${base_url}/${cygwin_rsvg}
    patch -p0 < ${cygwin_rsvg}/emacs-25.3-cygwin-rsvg.diff
}

# if use mingw on Cygwin, the configure script will generate file for MSYS2.
# and, src/epaths.h is need to set up the Windows-like path name.
# the build-aux/msys-to-w32 script will rewrite the path by "pwd -W" on MSYS2.
# Cygwin don't support this option. this function use cygpath and sed to rewrite the path.
function edit_msys_to_w32
{
    local target=build-aux/msys-to-w32
    sed --in-place ${target} \
        -e 's@pwd\ -W@cygpath -w `pwd` | sed -e '\''s!\\\\!/!g'\''@'
}

function setup_build_parameters
{
    local mode=$1

    if [[ $mode == "w64" ]]; then
        # Required to run of temacs.exe.
        export PATH=$PATH:/usr/x86_64-w64-mingw32/sys-root/mingw/bin
        # for GCC
        export CONFIG_CFLAGS='-O3 -march=native -static'
        # for configure script.
        export CONFIG_HOST="--host=x86_64-w64-mingw32"
        export CONFIG_PKG_CONFIG_PATH=/usr/x86_64-w64-mingw32/sys-root/mingw/lib/pkgconfig

    elif [[ $mode == "cygwin" ]]; then
        # for GCC
        export CONFIG_CFLAGS='-O3 -march=native'
        # for configure script.
        #export CONFIG_HOST=
        export CONFIG_PKG_CONFIG_PATH=/usr/lib/pkgconfig
    fi
}

function download_and_build
{
    local mode=$1

    mkdir -p ${BUILD_DIR}
    cd ${BUILD_DIR}

    download_emacs_sources
    cd emacs

    # IME patch to emacs sources.
    patch_to_sources

    if [[ $mode == "w64" ]]; then
        edit_msys_to_w32
    fi

    run_to_build

    install_emacs
}

function build_only
{
    cd ${BUILD_DIR}/emacs
    run_to_build
}

function install_emacs
{
    cd ${BUILD_DIR}/emacs
    # run to make install.
    make install
    if [[ $? -ne 0 ]]; then
        echo -e "${ERROR_PREFIX} Failed to execute make install command."
        exit 1
    fi
}

function run_to_build
{
    # run to autogen.sh script.
    ./autogen.sh

    # run to configure script.
    PKG_CONFIG_PATH=${CONFIG_PKG_CONFIG_PATH} \
    CFLAGS=${CONFIG_CFLAGS} \
    ./configure \
        ${CONFIG_HOST} \
        --prefix ${EMACS_INSTALL_DIR} \
        --with-w32 \
        --with-modules \
        --without-dbus \
        --without-compress-install

    if [[ $? -ne 0 ]]; then
        echo -e "${ERROR_PREFIX} Failed to execute configure script."
        exit 1
    fi

    # run to make.
    make -j8
    if [[ $? -ne 0 ]]; then
        echo -e "${ERROR_PREFIX} Failed to execute make command."
        exit 1
    fi

    install_emacs
}

function post_install
{
    local mode=$1

    if [[ $mode == "w64" ]]; then
        # Regenerate "emacs.exe".
        cd ${EMACS_INSTALL_DIR}/bin
        rm -f emacs.exe
        cp -a ${EMACS_VERSION}.exe emacs.exe

        # Copy the dependent dll files.
        copy_dlls
    fi
}

function copy_dlls
{
    cd /usr/x86_64-w64-mingw32/sys-root/mingw/bin
    cp -a \
       libgcc_s_seh-1.dll \
       libXpm-4.dll \
       libbz2-1.dll \
       libcairo-2.dll \
       libcroco-0.6-3.dll \
       libexpat-1.dll \
       libffi-6.dll \
       libfontconfig-1.dll \
       libfreetype-6.dll \
       libgdk_pixbuf-2.0-0.dll \
       libgif-4.dll \
       libgio-2.0-0.dll \
       libglib-2.0-0.dll \
       libgmodule-2.0-0.dll \
       libgmp-10.dll \
       libgnutls-30.dll \
       libgobject-2.0-0.dll \
       libharfbuzz-0.dll \
       libhogweed-4.dll \
       libintl-8.dll \
       libjpeg-8.dll \
       liblzma-5.dll \
       libnettle-6.dll \
       libp11-kit-0.dll \
       libpango-1.0-0.dll \
       libpangocairo-1.0-0.dll \
       libpangoft2-1.0-0.dll \
       libpangowin32-1.0-0.dll \
       libpcre-1.dll \
       libpixman-1-0.dll \
       libpng16-16.dll \
       librsvg-2-2.dll \
       libstdc++-6.dll \
       libtasn1-6.dll \
       libtiff-5.dll \
       libwinpthread-1.dll \
       libxml2-2.dll \
       zlib1.dll \
       ${EMACS_INSTALL_DIR}/bin
}


########################################
# Application Entry Point.
########################################
#set -u

is_download=0
is_buildonly=1 # default mode.
is_install=0
mode=none

for arg do
    case $arg in
        --help | --hel | --he | --h)
            usage
            exit 0 ;;
        --full)
            is_download=1
            ;;
        --buildonly)
            is_buildonly=1
            ;;
        --install)
            is_install=1
            ;;
        --* | -*)
            echo -e "${ERROR_PREFIX} invalid option: $arg\n"
            usage
            exit 1 ;;
        w64)
            detect_duplication_of_mode $mode && mode=w64
            ;;
        cygwin)
            detect_duplication_of_mode $mode && mode=cygwin
            ;;
        *)
            ;;
    esac
done

if [[ $mode == "none" ]]; then
    echo -e "${ERROR_PREFIX} target not found.\n"
    usage
    exit 1
fi

echo -e "${NOTICE_PREFIX} mode: $mode"
# setup build parametes. i.e. target architecture, compile options.
setup_build_parameters $mode

if [[ $is_download -eq 1 ]]; then
    echo -e "${NOTICE_PREFIX} start download and build process."
    download_and_build $mode
elif [[ $is_install -eq 1 ]]; then
    echo -e "${NOTICE_PREFIX} start install process."
    install_emacs
elif [[ $is_buildonly -eq 1 ]]; then
    echo -e "${NOTICE_PREFIX} start build only process."
    build_only
fi

# post install process. i.e. copy dll files.
post_install $mode

return 0

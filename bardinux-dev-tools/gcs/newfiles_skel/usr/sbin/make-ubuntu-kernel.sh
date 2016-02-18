#!/bin/bash
# -*- coding: utf-8 -*-

# Interactive script to create a custom Linux kernel for Ubuntu
#
# Copyright © 2009-2013  B. Clausius
#
# Use this however you want, just give credit where credit is due.

SCRIPTNAME="$(basename "$0")"

function print_usage()
{
    echo "Interactive script to create a custom Linux kernel for Ubuntu"
    echo
    echo "Usage:
${SCRIPTNAME} --help | -h
${SCRIPTNAME} FLAVOUR"
}

function print_configs()
{
    echo 'Existing configurations:'
    for flavour in $(ls -1 ../config-* | cut -d - -f 4- | sort -u); do
        echo
        echo $flavour :
        ls ../config-*-$flavour
    done
}

function print_help()
{
echo "Examples:
${SCRIPTNAME} generic
      Build the Ubuntu kernel for desktop computers
${SCRIPTNAME} server
      Build the Ubuntu kernel for servers
${SCRIPTNAME} core2
      Custom flavour (if it does not exist, it will be created)"
echo
echo \
'Notes:
    - Run the script from inside the source directory.
      It is intended to build the Linux kernel from Ubuntu 8.04.
      For source code from kernel.org the script is not suitable.
    - The used configuration tool is
      xconfig (Qt interface, package libqt3-mt-dev or libqt4-dev),
      gconfig (GTK interface, packages libgtk2.0-dev,
                                libglib2.0-dev, libglade2-dev)
      menuconfig (ncurses interface, package libncurses5-dev) oder
      config (line-oriented tool),
      whichever is found first.
    - The configuration is searched at these locations:
        1. ".config"
        2. "../config-KERNELVERSION-FLAVOUR"
        3. configuration in the source code for default flavour (generic
                                or $FLAVOUR)
    - After the configuration step the kernel configuration is stored
      in the file "../config-KERNELVERSION-FLAVOUR"'
}


[ "$1" = "" -o "$2" ] && {
    print_usage
    echo
    print_configs
    exit 1
}

[ "$1" = "-h" -o "$1" = "--help" ] && {
    print_usage
    echo
    print_help
    exit 0
}


function read_msg()
{
    echo
    echo "***** $* *****"
    read -p "[Enter: continue, Ctrl+D: skip, Ctrl+C: abort]" || { echo; return 1; }
}

function query_git_reset()
{
    [ -d .git ] && read_msg 'Discard changes in the git directory' && {
        git reset --hard
        git clean -fdx
    }
}

##### Preparations

function ubuntu_release()
{
    dpkg --compare-versions $UBUNTU_RELEASE $1 $2
}

# Supported Ubuntu version?
echo "Installed distribution:"
lsb_release -a
which lsb_release >/dev/null &&
    [ ! "$UBUNTU_RELEASE" ] &&
    [ "$(lsb_release -is)" = 'Ubuntu' ] && {
        UBUNTU_RELEASE=$(lsb_release -rs)
        #UBUNTU_CODENAME=$(lsb_release -cs)
    }
if [ ! "$UBUNTU_RELEASE" ]; then
    echo
    echo \
'Error: unknown distribution
        The environment variable UBUNTU_RELEASE must be set manually'
    exit 1
fi

[ "$(sed 's/^[0-9]\{2\}\.[0-9]\{2\}\(\.[0-9]\)\?$//' <<<$UBUNTU_RELEASE)" ] && {
    echo
    echo \
"Error: UBUNTU_RELEASE=${UBUNTU_RELEASE}
        The environment variable UBUNTU_RELEASE must be a valid
        Ubuntu version, eg 10.04, 11.10 or 12.04.
        If UBUNTU_RELEASE is not specified, the output of
        'lsb_release -rs' is used"
    exit 1
}

if ubuntu_release lt-nl 10.04; then
    echo
    echo 'Error: this script does not support versions before Ubuntu 10.04'
    exit 1
fi

echo
echo "Using method for '${UBUNTU_RELEASE}'.
(Set environment variable UBUNTU_RELEASE for different version)"

_ubuntu_codename_installed="$(lsb_release -cs)"
_ubuntu_codename_code="$(sed '1s/^[^ ]\+ [^ ]\+ \([a-z]\+\).*$/\1/;q' debian*/changelog 2>/dev/null)"
[ "$_ubuntu_codename_installed" != "$_ubuntu_codename_code" ] && {
    echo
    echo "Warning: In the source code is '${_ubuntu_codename_code}' specified,
but the installed distribution is '${_ubuntu_codename_installed}'.
Maybe the kernel can not be built."
}

# Called from source directory?
if [ ! -d kernel ] || [ ! -f MAINTAINERS ] || [ ! -f Makefile ]; then
    echo
    echo 'Error: the script must be called from source directory'
    exit 1
fi
if [ ! -d debian.master ] || [ ! -d debian ]; then
    echo
    [ -d debian.master ] || {
        echo 'Error: directory "debian.master" does not exist.'; }
    [ -d debian ] || {
        echo 'Error: directory "debian" does not exist.'; }
    echo \
'        This script only works with Ubuntu git trees
        and with code downloaded with "apt-get source",
        but not with the source code from kernel.org.
        Also, you may have assigned UBUNTU_RELEASE wrong.'
        
    query_git_reset
    exit 1
fi


# Some details about the running kernel
SYS_RELEASE=$(uname -r | awk -F- '{print $1}')
SYS_ARCH=$(uname -m)
SYS_FLAVOUR=$(uname -r | cut -d - -f 3-)
[ "$FLAVOUR" ] || FLAVOUR=generic
KARCH=$SYS_ARCH
[ $KARCH = i686 ] && KARCH=i386
[ $KARCH = x86_64 ] && KARCH=amd64
[ $KARCH = arm ] && KARCH=armel
KFLAVOUR=$1

[ "$(sed 's/^[a-zA-Z0-9]\+$//' <<<$KFLAVOUR)" ] && {
    echo
    echo \
"Warning: flavour '${KFLAVOUR}'
         flavour should contain only alphanumeric characters."
}

echo
echo \
"Details about the running kernel:
  Version:      ${SYS_RELEASE}
  Architecture: ${SYS_ARCH} (${KARCH})
  Flavour:      ${SYS_FLAVOUR}

Flavour to be created: ${KFLAVOUR}
Default flavour:       ${FLAVOUR}"


# Select configuration tool
function is_installed()
{
    dpkg -s $1 >/dev/null 2>&1 &&
        [ $(dpkg -s $1 | grep '^Status:' | awk '{print $4}') == 'installed' ]
}

if is_installed libqt4-dev; then
    CONFIGPRG=xconfig
elif is_installed libqt3-mt-dev; then
    CONFIGPRG=xconfig
elif is_installed libgtk2.0-dev && is_installed libglib2.0-dev && is_installed libglade2-dev; then
    CONFIGPRG=gconfig
elif is_installed libncurses5-dev; then
    CONFIGPRG=menuconfig
else
    CONFIGPRG=config
fi
echo
echo \
"  config        - line-oriented console tool
  menuconfig    - menu-based console tool
  xconfig       - Qt program
  gconfig       - GTK program
Use for configuration: ${CONFIGPRG}"


# Collect information from source code
printenv=$(make DEBIAN=debian.master -f debian/rules.d/0-common-vars.mk -f <(echo '
printenv:
        @echo "release           = $(release)"
        @echo "revision          = $(revision)"
        @echo "prev_revision     = $(prev_revision)"
        @echo "abinum            = $(abinum)"
        @echo "CONCURRENCY_LEVEL = $(CONCURRENCY_LEVEL)"
' | sed 's/^        /\t/') printenv)

KRELEASE=$(echo "$printenv" | grep '^release\>' | awk '{print $3}')
KREVISION=$(echo "$printenv" | grep '^revision\>' | awk '{print $3}')
KPREVISION=$(echo "$printenv" | grep '^prev_revision\>' | awk '{print $3}')
KABINUM=$(echo "$printenv" | grep '^abinum\>' | awk '{print $3}')
CONCURRENCY_LEVEL=$(echo "$printenv" | grep '^CONCURRENCY_LEVEL\>' | awk '{print $3}')
UPSTREAM_VERSION=$(make kernelversion)
echo
echo \
"Details about kernel source:
  Kernel Version:    ${UPSTREAM_VERSION}
  Release:           ${KRELEASE}
  Ubuntu Revision:   ${KREVISION}
  Previous Revision: ${KPREVISION}
  ABI-Number:        ${KABINUM}
CONCURRENCY_LEVEL: ${CONCURRENCY_LEVEL}"


# Test some directories and files
for dir in  debian.master/config/$KARCH \
            debian.master/abi/$KRELEASE-$KPREVISION \
            debian/rules.d/0-common-vars.mk \
            debian/scripts/misc/getabis; do
    [ -e $dir ] || {
        echo "'${dir}' does not exist"
        query_git_reset
        exit 1
    }
done


#### From this point, the script is interactive.

#### Reset directory

query_git_reset

#### Kernel configuration

echo
# 1) .config
if [ -f .config ]; then
    echo "Configuration: .config"
# 2) Backup configuration
elif [ -f ../config-$KRELEASE-$KABINUM-$KFLAVOUR ]; then
    echo "Configuration: ../config-$KRELEASE-$KABINUM-$KFLAVOUR"
    cat ../config-$KRELEASE-$KABINUM-$KFLAVOUR > .config
# 3) Standard configuration for default flavour
elif [ -f debian.master/config/$KARCH/config.flavour.$FLAVOUR ]; then
    echo "Configuration: debian.master/config/$KARCH/config.flavour.$FLAVOUR"
    cat debian.master/config/config.common.ubuntu >.config
    cat debian.master/config/$KARCH/config.common.$KARCH >>.config
    cat debian.master/config/$KARCH/config.flavour.$FLAVOUR >>.config
# give up
else
    echo "No suitable configuration file found."
    query_git_reset
    exit 1
fi

echo
echo "To edit the configuration with other make targets,
the script can be interrupted here."
read_msg "Edit kernel configuration (make $CONFIGPRG)" && {
    if [ $CONFIGPRG ]; then
        make $CONFIGPRG
    else
        echo 'Packages for configuration tool not installed'
    fi
}

echo
echo "Create copy of the configuration in '../config-$KRELEASE-$KABINUM-$KFLAVOUR'"
mv .config ../config-$KRELEASE-$KABINUM-$KFLAVOUR
# Cleaning up (some files hinder the compilation)
rm -r include/config/


#### Create flavour

read_msg 'Create kernel flavour' && {
        flavour_dir=debian.master/abi/$KRELEASE-$KPREVISION/$KARCH
        cp $flavour_dir/$FLAVOUR         $flavour_dir/$KFLAVOUR
        cp $flavour_dir/$FLAVOUR.modules $flavour_dir/$KFLAVOUR.modules
        
        sed -i "/getall $KARCH/s/ $KFLAVOUR//g"     debian.master/etc/getabis
        sed -i "/getall $KARCH/s/^.*$/& $KFLAVOUR/" debian.master/etc/getabis
        
        sed -i "/flavours/s/ $KFLAVOUR//g"      debian.master/rules.d/$KARCH.mk
        sed -i "/flavours/s/^.*$/& $KFLAVOUR/"  debian.master/rules.d/$KARCH.mk
        
        cp debian.master/control.d/vars.$FLAVOUR debian.master/control.d/vars.$KFLAVOUR
}

read_msg 'Update configuration' && {
    cp ../config-$KRELEASE-$KABINUM-$KFLAVOUR debian.master/config/$KARCH/config.flavour.$KFLAVOUR
    fakeroot debian/rules clean
    debian/rules updateconfigs
}

#### Compiling

read_msg 'Compiling' && {
    chmod +x debian/rules
    fakeroot debian/rules clean
    AUTOBUILD=1 NOEXTRAS=1 skipabi=true skipmodule=true fakeroot debian/rules binary-$KFLAVOUR
    AUTOBUILD=1 NOEXTRAS=1 skipabi=true skipmodule=true fakeroot debian/rules binary-indep 
}

#### List results

echo
ls -ld ../*$KRELEASE-$KABINUM*


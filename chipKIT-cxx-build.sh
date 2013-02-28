#!/bin/bash

SOURCE_GITHUB_ACCOUNT=jasonkajita
PLIB_IMAGE_TAR=plib-image-20120428.tar.bz2

GIT_CHIPKIT_CXX_REPO_ROOT=https://github.com/$SOURCE_GITHUB_ACCOUNT/chipKIT-cxx/tarball
GIT_PIC32_PART_SUPPORT_REPO_ROOT=https://github.com/$SOURCE_GITHUB_ACCOUNT/pic32-part-support/tarball
GIT_PIC32_NEWLIB_REPO_ROOT=https://github.com/$SOURCE_GITHUB_ACCOUNT/pic32-newlib/tarball
GIT_PLIB_IMAGE_TAR=https://github.com/downloads/$SOURCE_GITHUB_ACCOUNT/pic32-part-support/$PLIB_IMAGE_TAR

##############

echo "$BASH_SOURCE START BUILD..."
# Figure out which MinGW compiler we have. Candidates are:
# i586-mingw32msvc-gcc   (Ubuntu)
# i386-mingw32-gcc       (Fedora)
if [ "x$MINGW32_HOST_PREFIX" == "x" ]; then
    MINGW32_GCC=`which i586-mingw32msvc-gcc`
    if [ "x$MINGW_GCC" == "x" ] ; then
        MINGW32_HOST_PREFIX=i386-mingw32
    else
        MINGW32_HOST_PREFIX=i586-mingw32msvc
    fi
    unset MINGW32_GCC
fi
#unset MINGW32_HOST_PREFIX
#MINGW32_HOST_PREFIX=arm-unknown-linux-gnueabi

# Does notify-send exist?
if [ "x$NOTIFY_SEND" == "x" ] ; then
    WHICH_NOTIFY_SEND=`which notify-send`
    if [ "x$WHICH_NOTIFY_SEND" == "x" ] ; then
        unset NOTIFY_SEND
    else
        NOTIFY_SEND=notify-send
    fi
    unset WHICH_NOTIFY_SEND
fi

# Does growlnotify exist?
if [ "x$GROWL_SEND" == "x" ] ; then
    WHICH_GROWLSEND=`which growlnotify`
    if [ "x$WHICH_GROWLSEND" == "x" ] ; then
        unset GROWL_SEND
    else
        GROWL_SEND="growlnotify"
    fi
    unset WHICH_GROWLSEND
fi

DATE=`date +%Y%m%d`
TIME=`date +%H%M`
TVAL=master
#BUILD=chipKIT-cxx-$DATE
BUILD=chipKIT-cxx
TAG=master
FULL_ONLY=no
CHECKOUT="yes"
SKIPLIBS=""
SKIPNATIVE=""
SKIPLINUX32=""
SKIPGRAPHITE="yes"
SKIPMULTIPLENEWLIB="yes"
SKIPPLIBIMAGE=""
NATIVEIMAGE=`uname`
NATIVEIMAGE+="-image"
echo "Native image is $NATIVEIMAGE"


# Process the arguments
while getopts b:FNt:Q opt
do
    case "$opt" in
      t)
        TVAL=$OPTARG
        TAG="$TVAL"
        ;;
      b)
        TVAL=$OPTARG
        TAG="$TVAL"
        BUILD=pic32-$TVAL-$DATE
        ;;
      N)
        echo "No checkout"
        CHECKOUT="no"
        ;;
     \?) show_usage ;;
    esac
done

# Avoid double-date build (YYYYMMDD-YYYYMMDD)

if [[ ${TVAL%%$DATE} = $TVAL ]]; then
    BUILD=chipKIT-cxx-$TVAL
else
    BUILD=chipKIT-cxx-$TVAL
fi

LOGFILE=`pwd`/$BUILD.log

WORKING_DIR=`pwd`/$BUILD
echo WORKING DIR $WORKING_DIR


show_usage()
    {
        # Shows the usage screen
        echo "USAGE:  $0 [-t <tag> | -?]"
        echo "  -b <tag>      Specify the branch for which you would like to build"
        echo "  -t <tag>      Specify the tag for which you would like to build"
        echo "  -N            No svn checkout build only"
        echo "  -Q            Show svn checkout (no quiet)"
        echo "  -?            Show this usage message"
        exit 1
    }

####
# assert_success()
#   If the first parameter is non-zero, print the second parameter
#   and exit the script
####
function assert_success ()
    {
        local RESULT=$1
        local MESSAGE=$2
        if [ $RESULT != 0 ]
        then
            echo "$MESSAGE ($RESULT)"
            if [ "x$GROWL_SEND" != "x" ] ; then
                echo "$GROWL_SEND -s -p1 -t $BASH_SOURCE -m $MESSAGE"
                $GROWL_SEND "-s" "-p1" "-t" "$BASH_SOURCE" "-m" "$MESSAGE"
            elif [ "x$NOTIFY_SEND" != "x" ] ; then
                $NOTIFY_SEND "$MESSAGE" "Build Error"
            fi
            echo "$MESSAGE ($RESULT)" >> $LOGFILE
            unset GCC_FOR_TARGET
            unset CC_FOR_TARGET
            unset CXX_FOR_TARGET
            unset GXX_FOR_TARGET
            unset CPP_FOR_TARGET
            unset CC_FOR_BUILD
            unset CXX_FOR_BUILD
            unset CC
            unset CPP
            unset CXX
            unset LD
            unset AR
            exit $RESULT
        fi
    }

function status_update ()
    {
        local MESSAGE=$1
        if [ "x$GROWL_SEND" != "x" ] ; then
            $GROWL_SEND "-t" "$BASH_SOURCE:" "-m" "$MESSAGE"
        elif [ "x$NOTIFY_SEND" != "x" ] ; then
            $NOTIFY_SEND "$MESSAGE" "$BASH_SOURCE"
        fi
        echo `date` $MESSAGE >> $LOGFILE

    }

### Main script body


# Create the working directory

echo `date` " START PIC32 build." > $LOGFILE
echo `date` " Creating build in $WORKING_DIR..." >> $LOGFILE
if [ -e $WORKING_DIR ]
then
    echo `date` " $WORKING_DIR already exists..." >> $LOGFILE
else
    mkdir $WORKING_DIR
    assert_success $? "ERROR: creating directory $WORKING_DIR"
fi

cd $WORKING_DIR

# Check out the source code

GIT_PIC32_NEWLIB_REPO=$GIT_PIC32_NEWLIB_REPO_ROOT/$TAG
GIT_CHIPKIT_CXX_REPO=$GIT_CHIPKIT_CXX_REPO_ROOT/$TAG
GIT_PIC32_PART_SUPPORT_REPO=$GIT_PIC32_PART_SUPPORT_REPO_ROOT/$TAG

if [ "$CHECKOUT" = "yes" ]
then
    echo "Downloading $GIT_PIC32_NEWLIB_REPO"
    echo `date` " Downloading source from $GIT_PIC32_NEWLIB_REPO..." >> $LOGFILE
    if [ -e pic32-newlib ]
    then
        rm -rf pic32-newlib
    fi
    curl -L $GIT_PIC32_NEWLIB_REPO | tar zx
    assert_success $? "ERROR: Downloading source from $GIT_PIC32_NEWLIB_REPO"
    mv *-pic32-newlib-* pic32-newlib
    assert_success $? "Normalize pic32-newlib directory name"
fi

if [ "$CHECKOUT" = "yes" ]
then
    echo "Downloading $GIT_PIC32_PART_SUPPORT_REPO."
    echo `date` "Downloading part support from $GIT_PIC32_PART_SUPPORT_REPO..." >> $LOGFILE
    if [ -e pic32-part-support ]
    then
        rm -rf pic32-part-support
    fi
    curl -L $GIT_PIC32_PART_SUPPORT_REPO | tar zx
    assert_success $? "Downloading part support from $GIT_PIC32_PART_SUPPORT_REPO"
    mv *-pic32-part-support-* pic32-part-support
    assert_success $? "Normalize pic32-part-support directory name"
fi

if [ "$CHECKOUT" = "yes" ]
then
    echo "Downloading $GIT_CHIPKIT_CXX_REPO."
    echo `date` "Downloading compiler source from $GIT_CHIPKIT_CXX_REPO..." >> $LOGFILE
    if [ -e chipKIT-cxx ]
    then
        rm -rf chipKIT-cxx
    fi
    curl -L $GIT_CHIPKIT_CXX_REPO | tar zx
    assert_success $? "Downloading compiler source from $GIT_CHIPKIT_CXX_REPO"
    mv *-chipKIT-cxx-* chipKIT-cxx
    assert_success $? "Normalize chipKIT-cxx directory name"
fi

if [ "x$NATIVEIMAGE" == "xDarwin-image" ]
then
    LINUX32IMAGE="Linux32-image"

    # Figure out which Linux compiler we have.
    if [ "x$LINUX32_HOST_PREFIX" == "x" ]; then
        LINUX_GCC=`which i586-pc-linux-gcc`
        if [ "x$LINUX_GCC" == "x" ] ; then
            LINUX32_HOST_PREFIX=i386-linux
        else
            LINUX32_HOST_PREFIX=i586-pc-linux
        fi
        unset LINUX_GCC
    fi
    BUILDMACHINE="--build=i686-apple-darwin10"
    if [ -e "/Developer-old" ]
    then
        DEVELOPERDIR="/Developer-old"
    else
        DEVELOPERDIR="/Developer"
    fi

    if [ "x$SKIPNATIVE" == "x" ] ; then

        HOSTMACHINE="--host=i686-apple-darwin10"

        export CXX_FOR_BUILD="$DEVELOPERDIR/usr/bin/g++-4.2 -isysroot $DEVELOPERDIR/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -m32 -arch i386 -I$DEVELOPERDIR/SDKs/MacOSX10.5.sdk/usr/include/malloc"
        export CC_FOR_BUILD="$DEVELOPERDIR/usr/bin/gcc-4.2 -I$WORKING_DIR/chipKIT-cxx/src45x/gcc/gcc/ginclude -isysroot $DEVELOPERDIR/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -m32 -arch i386 -I$DEVELOPERDIR/SDKs/MacOSX10.5.sdk/usr/include/malloc"
        export CC="$DEVELOPERDIR/usr/bin/gcc-4.2 -isysroot $DEVELOPERDIR/SDKs/MacOSX10.5.sdk -I$WORKING_DIR/chipKIT-cxx/src45x/gcc/gcc/ginclude -mmacosx-version-min=10.5 -m32 -arch i386 -I$DEVELOPERDIR/SDKs/MacOSX10.5.sdk/usr/include/malloc"
        export CPP="$DEVELOPERDIR/usr/bin/cpp-4.2 -isysroot $DEVELOPERDIR/SDKs/MacOSX10.5.sdk  -mmacosx-version-min=10.5 -m32 -arch i386"
        export CXX="$DEVELOPERDIR/usr/bin/g++-4.2 -isysroot $DEVELOPERDIR/SDKs/MacOSX10.5.sdk  -mmacosx-version-min=10.5 -m32 -arch i386"
        export LD="$DEVELOPERDIR/usr/bin/gcc-4.2 -isysroot $DEVELOPERDIR/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -m32 -arch i386 -I$DEVELOPERDIR/SDKs/MacOSX10.5.sdk/usr/include/malloc"
        export AR="$DEVELOPERDIR/usr/bin/ar"
    fi  # SKIPNATIVE
    LIBHOST=""
else
    LINUX32IMAGE=""
    LINUX32_HOST_PREFIX=""
    HOSTMACHINE=""
    BUILDMACHINE=""
    LIBHOST="--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm"
fi

cd pic32-part-support

# Install headers into cross compiler's install image directory
echo "Making library headers for cross-compiler"
echo `date` "Making library headers for cross compiler's install image..." >> $LOGFILE

echo "make DESTROOT=\"$WORKING_DIR/$NATIVEIMAGE/pic32-tools\" install-headers"
make DESTROOT="$WORKING_DIR/$NATIVEIMAGE/pic32-tools" install-headers
assert_success $? "ERROR: Making headers into cross compiler's $NATIVEIMAGE install image directory"

if [ "x$LINUX32IMAGE" != "x" ] ; then
    echo "make DESTROOT=\"$WORKING_DIR/$LINUX32IMAGE/pic32-tools\" install-headers"
    make DESTROOT="$WORKING_DIR/$LINUX32IMAGE/pic32-tools" install-headers
    assert_success $? "ERROR: Making headers into cross compiler's $LINUXIMAGE install image directory"
fi

echo "make DESTROOT=\"$WORKING_DIR/export-image/pic32-tools\" install-headers"
make DESTROOT="$WORKING_DIR/export-image/pic32-tools" install-headers
assert_success $? "ERROR: Making headers into cross compiler's export-image install image directory"

echo "make DESTROOT=\"$WORKING_DIR/win32-image/pic32-tools\" install-headers"
make DESTROOT="$WORKING_DIR/win32-image/pic32-tools" install-headers
assert_success $? "ERROR: Making headers into cross compiler's win32-image install image directory"

if [ "x$LINUX32IMAGE" != "x" ]; then
    make DESTROOT="$WORKING_DIR/$LINUX32IMAGE" install-headers
    assert_success $? "ERROR: Making headers into cross compiler's $LINUX32IMAGE install image directory"
fi

cd ..

if [ "x$SKIPNATIVE" == "x" ] ; then

    # Build native cross compiler
    echo `date` " Creating cross build in $WORKING_DIR/native-build..." >> $LOGFILE

    status_update "Beginning native pic32 build"

    if [ -e native-build ]
    then
        rm -rf native-build
    fi
    mkdir native-build
    assert_success $? "ERROR: creating directory $WORKING_DIR/native-build"

    cd native-build

    if [ -e binutils ]
    then
        rm -rf binutils
    fi
    mkdir binutils
    assert_success $? "ERROR: creating directory $WORKING_DIR/native-build/binutils"

    cd binutils

    # Configure cross binutils
    echo `date` " Configuring cross binutils build in $WORKING_DIR/native-build..." >> $LOGFILE
    ../../chipKIT-cxx/src45x/binutils/configure $HOSTMACHINE --target=pic32mx --prefix="$WORKING_DIR/$NATIVEIMAGE/pic32-tools" --libexecdir="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin" --disable-nls --disable-tui --disable-gdbtk --disable-shared --enable-static --disable-threads --disable-bootstrap --with-dwarf2 --enable-multilib --without-newlib --disable-sim --with-lib-path=: --enable-poison-system-directories --program-prefix=pic32- --with-bugurl=http://www.chipkit.org/forums

    assert_success $? "ERROR: configuring cross binutils build"

    # Make cross binutils and install it
    echo `date` " Making all in $WORKING_DIR/native-build/binutils and installing..." >> $LOGFILE
    make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" all -j2
    assert_success $? "ERROR: making/installing cross binutils build"
    make install
    assert_success $? "ERROR: making/installing cross binutils build"

    NM_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-nm"
    RANLIB_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib"
    STRIP_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip"
    AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar"
    AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as"
    LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld"

    cd ..

    if [ -e gmp ]
    then
        rm -rf gmp
    fi
    mkdir gmp
    assert_success $? "ERROR: creating directory $WORKING_DIR/native-build/gmp"

    cd gmp
    echo `date` " Configuring native gmp build in $WORKING_DIR/native-build/gmp..." >> $LOGFILE
    ../../chipKIT-cxx/src45x/gmp/configure $HOSTMACHINE $BUILDMACHINE --enable-cxx --prefix=$WORKING_DIR/native-build/host-libs --disable-shared --enable-static --disable-nls --with-gnu-ld --disable-debug --disable-rpath --enable-fft --enable-hash-synchronization "--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm"

    # Make native gmp and install it
    echo `date` " Making all in $WORKING_DIR/native-build/gmp and installing..." >> $LOGFILE
    make all -j2
    assert_success $? "ERROR: making/installing gmp build"
    make install
    assert_success $? "ERROR: making/installing gmp build"

    cd ..


    if [ "x$SKIPGRAPHITE" == "x" ]; then
        if [ -e ppl ]
        then
            rm -rf ppl
        fi
        mkdir ppl
        assert_success $? "ERROR: creating directory $WORKING_DIR/linux32-build/ppl"

        cd ppl
        echo `date` " Configuring native ppl build in $WORKING_DIR/native-build/ppl..." >> $LOGFILE
        ../../chipKIT-cxx/src45x/ppl/configure --prefix=$WORKING_DIR/native-build/host-libs --disable-shared --enable-static --with-gnu-ld $HOSTMACHINE --target=pic32mx --disable-nls --with-libgmp-prefix=$WORKING_DIR/native-build/host-libs --with-gmp=$WORKING_DIR/native-build/host-libs

        # Make native ppl and install it
        echo `date` " Making all in $WORKING_DIR/native-build/ppl and installing..." >> $LOGFILE
        make all -j2
        assert_success $? "ERROR: making/installing ppl build"
        make install
        assert_success $? "ERROR: making/installing ppl build"

        cd ..

        if [ -e cloog ]
        then
            rm -rf cloog
        fi
        mkdir cloog
        assert_success $? "ERROR: creating directory $WORKING_DIR/native-build/cloog"

        cd cloog

        echo `date` " Configuring native cloog build in $WORKING_DIR/native-build/cloog..." >> $LOGFILE
        ../../chipKIT-cxx/src45x/cloog/configure $BUILDMACHINE --enable-optimization=speed --with-gnu-ld '--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm' --prefix=$WORKING_DIR/native-build/host-libs--with-gmp=$WORKING_DIR/native-build/host-libs --with-ppl=$WORKING_DIR/native-build/host-libs --target=pic32mx --disable-shared --enable-static --disable-shared

        # Make native cloog and install it
        echo `date` " Making all in $WORKING_DIR/native-build/cloog and installing..." >> $LOGFILE
        make all -j2
        assert_success $? "ERROR: making/installing cloog build"
        make install
        assert_success $? "ERROR: making/installing cloog build"

        cd ..
    fi


    if [ -e libelf ]
    then
        rm -rf libelf
    fi
    mkdir libelf
    assert_success $? "ERROR: creating directory $WORKING_DIR/native-build/libelf"

    cd libelf
    echo `date` " Configuring native libelf build in $WORKING_DIR/native-build/libelf..." >> $LOGFILE
    ../../chipKIT-cxx/src45x/libelf/configure  --prefix=$WORKING_DIR/native-build/host-libs $HOSTMACHINE --target=pic32mx --disable-shared --disable-debug --disable-nls

    # Make native libelf and install it
    echo `date` " Making all in $WORKING_DIR/native-build/libelf and installing..." >> $LOGFILE
    make all -j2
    assert_success $? "ERROR: making/installing libelf build"
    make install
    assert_success $? "ERROR: making/installing libelf build"
    cd ..

    if [ -e zlib ]
    then
        rm -rf zlib
    fi
    cp -r ../chipKIT-cxx/src45x/zlib .
    assert_success $? "ERROR: copy src45x/zlib directory to $WORKING_DIR/native-build/zlib"

    cd zlib
    echo `date` " Configuring native zlib build in $WORKING_DIR/native-build/zlib..." >> $LOGFILE
    ./configure --prefix=$WORKING_DIR/native-build/host-libs

    # Make native zlib and install it
    echo `date` " Making all in $WORKING_DIR/native-build/zlib and installing..." >> $LOGFILE
    make all -j2
    assert_success $? "ERROR: making/installing zlib build"
    make install
    assert_success $? "ERROR: making/installing zlib build"

    cd ..

    if [ -e gcc ]
    then
        rm -rf gcc
    fi
    mkdir gcc
    assert_success $? "ERROR: creating directory $WORKING_DIR/native-build/gcc"

    cd gcc

    # Configure cross compiler
    echo `date` " Configuring cross compiler build in $WORKING_DIR/native-build..." >> $LOGFILE
    AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ar" AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as" LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld" ../../chipKIT-cxx/src45x/gcc/configure --target=pic32mx --program-prefix=pic32- --disable-threads --disable-libmudflap --disable-libssp --enable-sgxx-sde-multilibs --with-gnu-as --with-gnu-ld --enable-languages=c,c++ --disable-shared --enable-static --with-newlib --disable-nls --disable-libgomp --without-headers --disable-libffi --disable-bootstrap --disable-decimal-float --disable-libquadmath --disable-__cxa_atexit --disable-libfortran --disable-libstdcxx-pch --prefix="$WORKING_DIR/$NATIVEIMAGE/pic32-tools" --libexecdir="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin" --with-dwarf2 --with-gmp="$WORKING_DIR/native-build/host-libs" "$LIBHOST" --disable-lto  --with-bugurl=http://www.chipkit.org/forums  XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-enforce-eh-specs" --enable-cxx-flags="-fno-exceptions -ffunction-sections"
    assert_success $? "ERROR: configuring cross build"

    # Make cross compiler and install it
    echo `date` " Making all in $WORKING_DIR/native-build/gcc and installing..." >> $LOGFILE
    make all-gcc CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" \
    NM_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-nm" \
    RANLIB_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib" \
    STRIP_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip"  \
    AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar"  \
    AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as" \
    LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld" -j2
    make all-gcc CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" \
    NM_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-nm" \
    RANLIB_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib" \
    STRIP_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip"  \
    AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar"  \
    AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as" \
    LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld"
    assert_success $? "ERROR: making/installing cross build all-gcc"
    make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" install-gcc
    assert_success $? "ERROR: making/installing cross build install-gcc"

    cd ..

    if [ -e newlib ]
    then
        rm -rf newlib
    fi
    mkdir newlib
    assert_success $? "ERROR: creating directory $WORKING_DIR/native-build/gcc"

    cd newlib
    status_update "Building newlib"

    #build newlib here
    GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src45x/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld ../../pic32-newlib/configure --target=pic32mx --disable-threads --enable-static --disable-libmudflap --disable-libssp --disable-libstdcxx-pch  --with-arch=pic32mx --enable-sgxx-sde-multilib --with-gnu-as --with-gnu-ld --enable-languages=c,c++ --disable-shared --disable-nls --with-dwarf2 --disable-bootstrap --enable-obsolete --disable-sjlj-exceptions --disable-__cxa_atexit --disable-libfortran --prefix=$WORKING_DIR/export-image/pic32-tools --libexecdir=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin --with-bugurl=http://chipkit.org/forum --disable-libgomp --disable-libffi --program-prefix=pic32- --with-newlib --enable-newlib-io-long-long --enable-newlib-register-fini --disable-newlib-multithread --disable-libgloss --disable-newlib-supplied-syscalls --disable-nls XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-enforce-eh-specs" --enable-cxx-flags="-fno-exceptions -ffunction-sections"
    assert_success $? "ERROR: Configure Newlib for native build"

    make all -j2
    make all
    assert_success $? "ERROR: Make newlib for native build"
    make install
    assert_success $? "ERROR: Install newlib for native build"

    cd $WORKING_DIR
    if [ "x$NATIVEIMAGE" != "x" ]
    then
      rsync -qavzC --include "*/" --include "*" export-image/pic32-tools/ $NATIVEIMAGE/pic32-tools/
      assert_success $? "ERROR: Install newlib in $NATIVEIMAGE"
    fi
    if [ "x$INUX32IMAGE" != "x" ]
    then
      rsync -qavzC --include "*/" --include "*" export-image/pic32-tools/ $LINUX32IMAGE/pic32-tools/
      assert_success $? "ERROR: Install newlib in $LINUX32IMAGE"
    fi
    if [ -e win32-image ]
    then
      rsync -qavzC --include "*/" --include "*" export-image/pic32-tools/ win32-image/pic32-tools/
      assert_success $? "ERROR: Install newlib in win32-image"
    fi

    cd native-build

    if [ -e gcc ]
    then
        rm -rf gcc
    fi
    mkdir gcc
    assert_success $? "ERROR: creating directory $WORKING_DIR/native-build/gcc"

    cd gcc

    GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld ../../chipKIT-cxx/src45x/gcc/configure --target=pic32mx --disable-threads --enable-static --disable-libmudflap --disable-libssp --disable-libstdcxx-pch  --with-arch=pic32mx --enable-sgxx-sde-multilib --with-gnu-as --with-gnu-ld --enable-languages=c,c++ --disable-shared --disable-nls --with-dwarf2 --disable-bootstrap --enable-obsolete --disable-sjlj-exceptions --disable-__cxa_atexit --disable-libfortran --prefix=$WORKING_DIR/$NATIVEIMAGE/pic32-tools --libexecdir=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin --with-gmp="$WORKING_DIR/native-build/host-libs" "$LIBHOST" --with-bugurl=http://chipkit.org/forum --disable-libgomp --disable-libffi --program-prefix=pic32- --with-newlib XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-enforce-eh-specs" --enable-cxx-flags="-fno-exceptions -ffunction-sections" CFLAGS_FOR_BUILD="-O3" --enable-poison-system-directories
    assert_success $? "ERROR: Configure gcc after Newlib for native build"

    make all \
    NM_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-nm" \
    RANLIB_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib" \
    STRIP_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip"  \
    AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar"  \
    AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as" \
    LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld" -j2
    make all
    assert_success $? "ERROR: making/installing cross build all"
    make install
    assert_success $? "ERROR: making/installing cross build install"

    # GCC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc" \
    # CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc"  \
    # CPP_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++"  \

    status_update "Cross build complete"

    cd ../..

    # strip native-image
    cd $NATIVEIMAGE/pic32-tools
    if [ "x$NATIVEIMAGE" == "xDarwin-image" ] ; then
        find . -type f -perm -g+x -follow | xargs file | grep Mach-O | cut -d: -f1 | xargs $DEVELOPERDIR/usr/bin/strip
    elif [ "x$LINUX32_HOST_PREFIX" != "x" ] ; then
        find . -type f -perm -g+x -follow | xargs file | grep ELF | cut -d: -f1 | xargs $LINUX32_HOST_PREFIX-strip
    fi
    cd $WORKING_DIR
    # end strip native-image

fi # skipping native


# end build native toolchain

unset  CC
unset  CPP
unset  CXX
unset  LD
unset  AR

# Set up path so that we can build the libraries and the win32 cross
# compiler using the cross compiler we just built
OLDPATH=$PATH
PATH=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin:$PATH
#PATH=/usr/local/i386-mingw32-4.3.0/bin:$PATH
#PATH=/usr/local/gcc-4.5.2-for-linux32/bin:$PATH

if [ "x$SKIPLIBS" == "x" ] ; then

    cd pic32-part-support

    # Build cross compiler libraries
    echo `date` " Making and installing cross-compiler libraries to $WORKING_DIR/$NATIVEIMAGE/pic32-tools..." >> $LOGFILE

    make DESTROOT=$WORKING_DIR/$NATIVEIMAGE/pic32-tools all
    assert_success $? "ERROR: making libraries for cross build"

    make DESTROOT=$WORKING_DIR/$NATIVEIMAGE/pic32-tools install -j2
    assert_success $? "ERROR: making libraries for $NATIVEIMAGE cross build"

    if [ "x$LINUX32IMAGE" != "x" ] ; then
        make DESTROOT="$WORKING_DIR/$LINUX32IMAGE/pic32-tools" install -j2
        assert_success $? "ERROR: making libraries for linux32-image cross build"
    fi

    make DESTROOT="$WORKING_DIR/export-image/pic32-tools" install -j2
    assert_success $? "ERROR: making libraries for export-image cross build"
    make DESTROOT="$WORKING_DIR/win32-image/pic32-tools" install -j2
    assert_success $? "ERROR: making libraries for win32-image cross build"

    status_update "cross-compiler library build complete"

    cd ..

fi # skip library build

# Build linux compiler

if [ "x$SKIPLINUX32" == "x" ] ; then

    if [ "x$LINUX32IMAGE" != "x" ] ; then
        #unset CXX_FOR_BUILD
        #unset CC_FOR_BUILD
        unset CC
        unset CPP
        unset CXX

        echo `date` " Creating linux cross build in $WORKING_DIR/linux32-build..." >> $LOGFILE
        cd $WORKING_DIR
        if [ -e linux32-build ]
        then
            rm -rf linux32-build
        fi
        mkdir linux32-build
        assert_success $? "ERROR: creating directory $WORKING_DIR/linux32-build"

        cd linux32-build

        if [ -e binutils ]
        then
            rm -rf binutils
        fi
        mkdir binutils
        assert_success $? "ERROR: creating directory $WORKING_DIR/linux32-build/binutils"

        cd binutils

        # Configure linux-cross binutils
        echo `date` " Configuring linux32 binutils build in $WORKING_DIR/linux32-build..." >> $LOGFILE
        ../../chipKIT-cxx/src45x/binutils/configure $BUILDMACHINE --target=pic32mx --prefix=$WORKING_DIR/$LINUX32IMAGE/pic32-tools --libexecdir=$WORKING_DIR/$LINUX32IMAGE/pic32-tools/pic32mx/bin --host=$LINUX32_HOST_PREFIX --disable-nls --disable-tui --disable-gdbtk --disable-shared --enable-static --disable-threads --disable-bootstrap  --with-dwarf2 --enable-multilib --without-newlib --disable-sim --with-lib-path=: --enable-poison-system-directories --program-prefix=pic32- --with-bugurl=http://www.chipkit.org/forums
        assert_success $? "ERROR: configuring linux32 binutils build"

        # Make linux-cross binutils and install it
        echo `date` " Making all in $WORKING_DIR/linux32-build/binutils and installing..." >> $LOGFILE
        make all CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" -j2
        assert_success $? "ERROR: making/installing linux32 Canadian-cross binutils build"
        make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" install
        assert_success $? "ERROR: making/installing linux32 Canadian-cross binutils build"

        cd ..

        if [ -e gmp ]
        then
            rm -rf gmp
        fi
        mkdir gmp
        assert_success $? "ERROR: creating directory $WORKING_DIR/linux32-build/gmp"

        cd gmp

        echo `date` " Configuring linux gmp build in $WORKING_DIR/linux32-build/gmp..." >> $LOGFILE
        CFLAGS="-fexceptions" ../../chipKIT-cxx/src45x/gmp/configure --enable-cxx  --prefix=$WORKING_DIR/linux32-build/linux-libs --disable-shared --target=$LINUX32_HOST_PREFIX --host=$LINUX32_HOST_PREFIX --disable-nls --with-gnu-ld --disable-debug --disable-rpath --enable-fft --enable-hash-synchronization "--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm"

        # Make linux gmp and install it
        echo `date` " Making all in $WORKING_DIR/linux32-build/gmp and installing..." >> $LOGFILE
        make all -j2
        assert_success $? "ERROR: making/installing gmp build"
        make install
        assert_success $? "ERROR: making/installing gmp build"

        cd ..

        if [ "x$SKIPGRAPHITE" == "x" ]; then
            if [ -e ppl ]
            then
                rm -rf ppl
            fi
            mkdir ppl
            assert_success $? "ERROR: creating directory $WORKING_DIR/linux32-build/ppl"

            cd ppl
            echo `date` " Configuring linux32 ppl build in $WORKING_DIR/linux32-build/ppl..." >> $LOGFILE
            ../../chipKIT-cxx/src45x/ppl/configure  --prefix=$WORKING_DIR/linux32-build/linux-libs --disable-shared --enable-static --with-gnu-ld --host=$LINUX32_HOST_PREFIX --target=pic32mx --disable-nls --with-libgmp-prefix=$WORKING_DIR/linux32-build/linux-libs --with-gmp=$WORKING_DIR/linux32-build/linux-libs

            # Make native ppl and install it
            echo `date` " Making all in $WORKING_DIR/linux32-build/ppl and installing..." >> $LOGFILE
            make all -j2
            assert_success $? "ERROR: making/installing ppl build"
            make install
            assert_success $? "ERROR: making/installing ppl build"

            cd ..

            if [ -e cloog ]
            then
                rm -rf cloog
            fi
            mkdir cloog
            assert_success $? "ERROR: creating directory $WORKING_DIR/linux32-build/cloog"

            cd cloog

            echo `date` " Configuring linux cloog build in $WORKING_DIR/linux32-build/cloog..." >> $LOGFILE
            ../../chipKIT-cxx/src45x/cloog/configure $BUILDMACHINE --enable-optimization=speed --with-gnu-ld '--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm' --prefix=$WORKING_DIR/linux32-build/linux-libs --host=$LINUX32_HOST_PREFIX --with-gmp=$WORKING_DIR/linux32-build/linux-libs --with-ppl=$WORKING_DIR/linux32-build/linux-libs --target=pic32mx --disable-shared --enable-static --disable-shared

            # Make native cloog and install it
            echo `date` " Making all in $WORKING_DIR/linux32-build/cloog and installing..." >> $LOGFILE
            make all -j2
            assert_success $? "ERROR: making/installing cloog build"
            make install
            assert_success $? "ERROR: making/installing cloog build"

            cd ..
        fi

        if [ -e libelf ]
        then
            rm -rf libelf
        fi
        mkdir libelf
        assert_success $? "ERROR: creating directory $WORKING_DIR/linux32-build/libelf"

        cd libelf
        echo `date` " Configuring native libelf build in $WORKING_DIR/linux32-build/libelf..." >> $LOGFILE
        ../../chipKIT-cxx/src45x/libelf/configure  --prefix=$WORKING_DIR/linux32-build/linux-libs --host=$LINUX32_HOST_PREFIX --target=pic32mx --disable-shared --disable-debug --disable-nls

        # Make native libelf and install it
        echo `date` " Making all in $WORKING_DIR/linux32-build/libelf and installing..." >> $LOGFILE
        make all -j2
        assert_success $? "ERROR: making/installing libelf build"
        make install
        assert_success $? "ERROR: making/installing libelf build"
        cd ..

        if [ -e zlib ]
        then
            rm -rf zlib
        fi
        cp -r ../chipKIT-cxx/src45x/zlib .
        assert_success $? "ERROR: copy src45x/zlib directory to $WORKING_DIR/linux32-build/zlib"

        cd zlib
        echo `date` " Configuring linux zlib build in $WORKING_DIR/linux32-build/zlib..." >> $LOGFILE
        CC=$LINUX32_HOST_PREFIX-gcc AR="$LINUX32_HOST_PREFIX-ar" RANLIB=$LINUX32_HOST_PREFIX-ranlib ./configure --prefix=$WORKING_DIR/linux32-build/linux-libs

        # Make linux zlib and install it
        echo `date` " Making all in $WORKING_DIR/linux32-build/zlib and installing..." >> $LOGFILE
        make all -j2
        assert_success $? "ERROR: making/installing zlib build - all"
        make install
        assert_success $? "ERROR: making/installing zlib build - install"
        cd ..

        if [ -e gcc ]
        then
            rm -rf gcc
        fi
        mkdir gcc
        assert_success $? "ERROR: creating directory $WORKING_DIR/linux32-build/gcc"

        cd gcc

        # Configure linux cross compiler
        echo `date` " Configuring linux cross compiler build in $WORKING_DIR/linux32-build..." >> $LOGFILE

        AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32mx/bin/ar" AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32mx/bin/as" LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32mx/bin/ld" GCC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/bin/pic32-gcc" CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/bin/pic32-gcc" CXX_FOR_TARGET='pic32-gcc' target_alias=pic32- ../../chipKIT-cxx/src45x/gcc/configure $BUILDMACHINE --host=$LINUX32_HOST_PREFIX --target=pic32mx --program-prefix=pic32- --disable-threads --disable-libmudflap --disable-libssp --disable-libstdcxx-pch --enable-sgxx-sde-multilibs --disable-threads --with-gnu-as --with-gnu-ld --disable-sim --disable-bootstrap --enable-obsolete --disable-__cxa_atexit --disable-libfortran --enable-languages=c,c++ --disable-shared --with-newlib --disable-nls --prefix=$WORKING_DIR/$LINUX32IMAGE/pic32-tools --disable-libgomp --without-headers --disable-libffi --enable-poison-system-directories --libexecdir=$WORKING_DIR/$LINUX32IMAGE/pic32-tools/pic32mx/bin --with-dwarf2 "--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm" --with-libelf=$WORKING_DIR/linux32-build/linux-libs --with-gmp=$WORKING_DIR/linux32-build/linux-libs --with-ppl=$WORKING_DIR/linux32-build/linux-libs --with-cloog=$WORKING_DIR/linux32-build/linux-libs --with-bugurl=http://www.chipkit.org/forums XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-enforce-eh-specs" --enable-cxx-flags="-fno-exceptions -ffunction-sections"
        assert_success $? "ERROR: configuring linux32 cross build"

        # Make cross compiler and install it
        echo `date` " Making all in $WORKING_DIR/linux32-build/gcc and installing..." >> $LOGFILE
        make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" all-gcc \
        NM_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-nm" \
        RANLIB_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib" \
        STRIP_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip" \
        AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar" \
        AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as" \
        LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld" \
        GCC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc" \
        CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc" -j2
        assert_success $? "ERROR: making/installing linux Canadian-cross compiler build"
        make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" install-gcc
        assert_success $? "ERROR: making/installing linux Canadian-cross compiler build"

        cd ..

        if [ "xSKIPMULTIPLENEWLIB" != x ]; then

        if [ -e newlib ]
        then
            rm -rf newlib
        fi
        mkdir newlib
        assert_success $? "ERROR: creating directory $WORKING_DIR/LINUXIMAGE/newlib"

        cd newlib

        echo `date` " Configure newlib for $LINUX32IMAGE..." >> $LOGFILE

        #build newlib here

        GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src45x/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld ../../pic32-newlib/configure --target=pic32mx --disable-threads --enable-static --disable-libmudflap --disable-libssp --disable-libstdcxx-pch  --with-arch=pic32mx --enable-sgxx-sde-multilib --with-gnu-as --with-gnu-ld --enable-languages=c,c++ --disable-shared --disable-nls --with-dwarf2 --disable-bootstrap --enable-obsolete --disable-sjlj-exceptions --disable-__cxa_atexit --disable-libfortran --prefix=$WORKING_DIR/$LINUX32IMAGE/pic32-tools --libexecdir=$WORKING_DIR/$LINUX32IMAGE/pic32-tools/pic32mx/bin --with-bugurl=http://chipkit.org/forum --disable-libgomp --disable-libffi --program-prefix=pic32- --with-newlib --enable-newlib-io-long-long --enable-newlib-register-fini --disable-newlib-multithread --disable-libgloss --disable-newlib-supplied-syscall XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-enforce-eh-specs" --enable-cxx-flags="-fno-exceptions -ffunction-sections"

        echo `date` " Make newlib for $LINUX32IMAGE..." >> $LOGFILE

        make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" all -j2
        make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" all
        assert_success $? "ERROR: Make newlib for cross build"
        make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" install
        assert_success $? "ERROR: Install newlib for cross build"

        cd ..
        fi

        if [ -e gcc ]
        then
            rm -rf gcc
        fi
        mkdir gcc
        assert_success $? "ERROR: creating directory $WORKING_DIR/linux32-build/gcc"

        cd gcc

        echo `date` " Configure gcc after making Newlib for $LINUX32IMAGE..." >> $LOGFILE
        GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src45x/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld ../../chipKIT-cxx/src45x/gcc/configure target_alias=pic32- $BUILDMACHINE --host=$LINUX32_HOST_PREFIX --target=pic32mx --program-prefix=pic32- --disable-threads --disable-libmudflap --disable-libssp --disable-libstdcxx-pch --enable-sgxx-sde-multilibs --disable-threads --with-gnu-as --with-gnu-ld --disable-sim --disable-bootstrap  --disable-sjlj-exceptions --enable-obsolete --disable-__cxa_atexit --disable-libfortran --enable-languages=c,c++ --disable-shared --with-newlib --disable-nls --prefix=$WORKING_DIR/$LINUX32IMAGE/pic32-tools --disable-libgomp --disable-libffi --enable-poison-system-directories --libexecdir=$WORKING_DIR/$LINUX32IMAGE/pic32-tools/pic32mx/bin --with-dwarf2 "--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm" --with-libelf=$WORKING_DIR/linux32-build/linux-libs --with-gmp=$WORKING_DIR/linux32-build/linux-libs --with-ppl=$WORKING_DIR/linux32-build/linux-libs --with-cloog=$WORKING_DIR/linux32-build/linux-libs --with-bugurl=http://www.chipkit.org/forums XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-enforce-eh-specs" --enable-cxx-flags="-fno-exceptions -ffunction-sections"
        assert_success $? "ERROR: configuring linux32 cross build 2"

        make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" all \
        GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src45x/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld  -j2
        make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" all \
        GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src45x/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld
        assert_success $? "ERROR: making linux Canadian-cross compiler build"
        make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" install
        assert_success $? "ERROR: installing linux Canadian-cross compiler build"

        cd ../..
        status_update "Make linux32 Canadian cross build complete"

        unset CC
        unset CPP
        unset CXX

        # strip Linux32-image
        cd $WORKING_DIR/$LINUX32IMAGE/pic32-tools
        find ./bin -type f -perm -g+x -follow | xargs file | grep ELF | cut -d: -f1 | xargs $LINUX32_HOST_PREFIX-strip
        find ./pic32mx/bin -type f -perm -g+x -follow | xargs file | grep ELF | cut -d: -f1 | xargs $LINUX32_HOST_PREFIX-strip
        cd $WORKING_DIR

    fi
fi

unset CC
unset CPP
unset CXX

cd $WORKING_DIR

################ end build linux compiler ##############

# Build mingw32 cross compiler
echo `date` " Creating cross build in $WORKING_DIR/win32-build..." >> $LOGFILE
if [ -e win32-build ]
then
    rm -rf win32-build
fi
mkdir win32-build
assert_success $? "ERROR: creating directory $WORKING_DIR/win32-build"

cd win32-build

if [ -e binutils ]
then
    rm -rf binutils
fi
mkdir binutils
assert_success $? "ERROR: creating directory $WORKING_DIR/win32-build/binutils"

cd binutils

# Configure mingw32-cross binutils
echo `date` " Configuring win32 binutils build in $WORKING_DIR/win32-build..." >> $LOGFILE
../../chipKIT-cxx/src45x/binutils/configure  --target=pic32mx --prefix=$WORKING_DIR/win32-image/pic32-tools --libexecdir=$WORKING_DIR/win32-image/pic32mx/bin --host=$MINGW32_HOST_PREFIX --disable-nls --disable-tui --disable-gdbtk --disable-shared --enable-static --disable-threads --disable-bootstrap  --with-dwarf2 --enable-multilib --without-newlib --disable-sim --with-lib-path=: --enable-poison-system-directories --program-prefix=pic32- --with-bugurl=http://www.chipkit.org/forums
assert_success $? "ERROR: configuring win32 binutils build"

# Make MinGW32-cross binutils and install it
echo `date` " Making all in $WORKING_DIR/win32-build/binutils and installing..." >> $LOGFILE
make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" all -j2
assert_success $? "ERROR: making/installing win32 Canadian-cross binutils build"
make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" install
assert_success $? "ERROR: making/installing win32 Canadian-cross binutils build"
cd ..

if [ -e gmp ]
then
    rm -rf gmp
fi
mkdir gmp
assert_success $? "ERROR: creating directory $WORKING_DIR/win32-build/gmp"

cd gmp

echo `date` " Configuring win32 gmp build in $WORKING_DIR/win32-build/gmp..." >> $LOGFILE
CPPFLAGS="-fexceptions" ../../chipKIT-cxx/src45x/gmp/configure --enable-cxx --prefix=$WORKING_DIR/win32-build/host-libs --disable-shared --host=$MINGW32_HOST_PREFIX --disable-nls --with-gnu-ld --disable-debug --disable-rpath --enable-fft "--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm"

# Make win32 gmp and install it
echo `date` " Making all in $WORKING_DIR/win32-build/gmp and installing..." >> $LOGFILE
make CPPFLAGS="-fexceptions" all -j2
assert_success $? "ERROR: making/installing gmp build"
make install
assert_success $? "ERROR: making/installing gmp build"

cd ..

if [ "x$SKIPGRAPHITE" == "x" ]; then

    if [ -e ppl ]
    then
        rm -rf ppl
    fi
    mkdir ppl
    assert_success $? "ERROR: creating directory $WORKING_DIR/win32-build/ppl"

    cd ppl
    echo `date` " Configuring native ppl build in $WORKING_DIR/win32-build/ppl..." >> $LOGFILE
    ../../chipKIT-cxx/src45x/ppl/configure --prefix=$WORKING_DIR/win32-build/host-libs --disable-shared --enable-static --with-gnu-ld --host=$MINGW32_HOST_PREFIX --target=pic32mx --disable-nls --enable-optimization=speed --disable-rpath --with-gmp-=$WORKING_DIR/win32-build/host-libs --with-libgmp-prefix=$WORKING_DIR/win32-build/host-libs

    # Make native ppl and install it
    echo `date` " Making all in $WORKING_DIR/win32-build/ppl and installing..." >> $LOGFILE
    make all -j2
    assert_success $? "ERROR: making/installing ppl build"
    make install
    assert_success $? "ERROR: making/installing ppl build"

    cd ..

    if [ -e cloog ]
    then
        rm -rf cloog
    fi
    mkdir cloog
    assert_success $? "ERROR: creating directory $WORKING_DIR/win32-build/cloog"

    cd cloog

    echo `date` " Configuring win32 cloog build in $WORKING_DIR/win32-build/cloog..." >> $LOGFILE
    ../../chipKIT-cxx/src45x/cloog/configure $BUILDMACHINE --with-gnu-ld --prefix=$WORKING_DIR/win32-build/host-libs --host=$MINGW32_HOST_PREFIX --target=pic32mx --with-gmp=$WORKING_DIR/win32-build/host-libs --with-ppl=$WORKING_DIR/win32-build/host-libs --target=pic32mx --disable-shared --enable-static --disable-shared

    # Make native cloog and install it
    echo `date` " Making all in $WORKING_DIR/win32-build/cloog and installing..." >> $LOGFILE
    make all -j2
    assert_success $? "ERROR: making/installing cloog build"
    make install
    assert_success $? "ERROR: making/installing cloog build"

    cd ..
fi

if [ -e libelf ]
then
    rm -rf libelf
fi
mkdir libelf
assert_success $? "ERROR: creating directory $WORKING_DIR/win32-build/libelf"

cd libelf
echo `date` " Configuring native libelf build in $WORKING_DIR/win32-build/libelf..." >> $LOGFILE
GCC_FOR_TARGET='pic32-gcc' CC_FOR_TARGET='pic32-gcc' CPP_FOR_TARGET='pic32-g++' AS_FOR_TARGET=pic32-as LD_FOR_TARGET=pic32-ld CFLAGS_FOR_BUILD="-O2" ../../chipKIT-cxx/src45x/libelf/configure  --prefix=$WORKING_DIR/win32-build/host-libs --host=$MINGW32_HOST_PREFIX $BUILDMACHINE --target=pic32mx --disable-shared --disable-debug --disable-nls

# Make native libelf and install it
echo `date` " Making all in $WORKING_DIR/win32-build/libelf and installing..." >> $LOGFILE
make all -j2
assert_success $? "ERROR: making/installing libelf build"
make install
assert_success $? "ERROR: making/installing libelf build"
cd ..

if [ -e zlib ]
then
    rm -rf zlib
fi
cp -r ../chipKIT-cxx/src45x/zlib .
assert_success $? "ERROR: copy src45x/zlib directory to $WORKING_DIR/win32-build/zlib"

cd zlib
echo `date` " Configuring win32 zlib build in $WORKING_DIR/win32-build/zlib..." >> $LOGFILE
CC=$MINGW32_HOST_PREFIX-gcc AR="$MINGW32_HOST_PREFIX-ar" RANLIB=$MINGW32_HOST_PREFIX-ranlib ./configure --prefix=$WORKING_DIR/win32-build/host-libs

# Make win32 zlib and install it
echo `date` " Making all in $WORKING_DIR/win32-build/zlib and installing..." >> $LOGFILE
make all -j2
assert_success $? "ERROR: making/installing zlib build - all"
make install
assert_success $? "ERROR: making/installing zlib build - install"
cd ..

if [ -e gcc ]
then
    rm -rf gcc
fi
mkdir gcc
assert_success $? "ERROR: creating directory $WORKING_DIR/win32-build/gcc"

cd gcc

# Configure win32 cross compiler
echo `date` " Configuring win32 cross compiler build in $WORKING_DIR/win32-build..." >> $LOGFILE

AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32mx/bin/ar" AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32mx/bin/as" LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32mx/bin/ld" GCC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/bin/pic32-gcc" CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/bin/pic32-gcc" CXX_FOR_TARGET='pic32-gcc' target_alias=pic32- ../../chipKIT-cxx/src45x/gcc/configure $BUILDMACHINE --host=$MINGW32_HOST_PREFIX --target=pic32mx --program-prefix=pic32- --disable-threads --disable-libmudflap --disable-libssp --disable-libstdcxx-pch --enable-sgxx-sde-multilibs --disable-threads --with-gnu-as --with-gnu-ld --disable-sim --disable-bootstrap --enable-obsolete --disable-__cxa_atexit --disable-libfortran --enable-languages=c,c++ --disable-shared --with-newlib --disable-nls --prefix=$WORKING_DIR/win32-image/pic32-tools --disable-libgomp --without-headers --disable-libffi --enable-poison-system-directories --libexecdir=$WORKING_DIR/win32-image/pic32-tools/pic32mx/bin --with-dwarf2  --with-libelf=$WORKING_DIR/win32-build/host-libs --with-gmp=$WORKING_DIR/win32-build/host-libs --with-bugurl=http://www.chipkit.org/forums XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-enforce-eh-specs" --enable-cxx-flags="-fno-exceptions -ffunction-sections"
#"--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm"
# --with-ppl=$WORKING_DIR/win32-build/host-libs
# --with-cloog=$WORKING_DIR/win32-build/host-libs
assert_success $? "ERROR: configuring win3232 cross build"

# Make cross compiler and install it
echo `date` " Making all in $WORKING_DIR/win32-build/gcc and installing..." >> $LOGFILE
make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" all-gcc \
NM_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-nm" \
RANLIB_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib" \
STRIP_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip" \
AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar" \
AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as" \
LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld" \
GCC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc" \
CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc" -j2
assert_success $? "ERROR: making/installing win32 Canadian-cross compiler build"
make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" install-gcc
assert_success $? "ERROR: making/installing win32 Canadian-cross compiler build"

cd ..

if [ "xSKIPMULTIPLENEWLIB" != x ]; then

if [ -e newlib ]
then
    rm -rf newlib
fi
mkdir newlib
assert_success $? "ERROR: creating directory $WORKING_DIR/win32IMAGE/newlib"

cd newlib

echo `date` " Configure newlib for win32-image..." >> $LOGFILE

#build newlib here

GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src45x/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld ../../pic32-newlib/configure --target=pic32mx --disable-threads --enable-static --disable-libmudflap --disable-libssp --disable-libstdcxx-pch  --with-arch=pic32mx --enable-sgxx-sde-multilib --with-gnu-as --with-gnu-ld --enable-languages=c,c++ --disable-shared --disable-nls --with-dwarf2 --disable-bootstrap --enable-obsolete --disable-sjlj-exceptions --disable-__cxa_atexit --disable-libfortran --prefix=$WORKING_DIR/win32-image/pic32-tools --libexecdir=$WORKING_DIR/win32-image/pic32-tools/pic32mx/bin --with-bugurl=http://chipkit.org/forum --disable-libgomp --disable-libffi --program-prefix=pic32- --with-newlib --enable-newlib-io-long-long --enable-newlib-register-fini --disable-newlib-multithread --disable-libgloss --disable-newlib-supplied-syscall XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-enforce-eh-specs" --enable-cxx-flags="-fno-exceptions -ffunction-sections"

echo `date` " Make newlib for win32-image..." >> $LOGFILE

make all -j2
make all
assert_success $? "ERROR: Make newlib for cross build"
make install
assert_success $? "ERROR: Install newlib for cross build"

cd ..
fi

if [ -e gcc ]
then
    rm -rf gcc
fi
mkdir gcc
assert_success $? "ERROR: creating directory $WORKING_DIR/win32-build/gcc"

cd gcc

echo `date` " Configure gcc after making Newlib for win32-image..." >> $LOGFILE
GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src45x/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld ../../chipKIT-cxx/src45x/gcc/configure target_alias=pic32- $BUILDMACHINE --host=$MINGW32_HOST_PREFIX --target=pic32mx --program-prefix=pic32- --disable-threads --disable-libmudflap --disable-libssp --disable-libstdcxx-pch --enable-sgxx-sde-multilibs --disable-threads --with-gnu-as --with-gnu-ld --disable-sim --disable-bootstrap  --disable-sjlj-exceptions --enable-obsolete --disable-__cxa_atexit --disable-libfortran --enable-languages=c,c++ --disable-shared --with-newlib --disable-nls --prefix=$WORKING_DIR/win32-image/pic32-tools --disable-libgomp --disable-libffi --enable-poison-system-directories --libexecdir=$WORKING_DIR/win32-image/pic32-tools/pic32mx/bin --with-dwarf2 --with-libelf=$WORKING_DIR/win32-build/host-libs --with-gmp=$WORKING_DIR/win32-build/host-libs --with-bugurl=http://www.chipkit.org/forums XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-enforce-eh-specs" --enable-cxx-flags="-fno-exceptions -ffunction-sections" --with-ppl=$WORKING_DIR/win32-build/host-libs --with-cloog=$WORKING_DIR/win32-build/host-libs
#"--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm"
assert_success $? "ERROR: configuring win3232 cross build 2"

make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" all \
GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src45x/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld  -j2
make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" all \
GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src45x/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld
assert_success $? "ERROR: making win32 Canadian-cross compiler build"
make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" install
assert_success $? "ERROR: installing win32 Canadian-cross compiler build"

cd ../..
status_update "Make win32 Canadian cross build complete"

unset CC
unset CPP
unset CXX

cd $WORKING_DIR/win32-image/pic32-tools
find . -type f -name "*.exe" | xargs $MINGW_HOST_PREFIX-strip

status_update "Make minGW32 Canadian cross build complete"

cd $WORKING_DIR

###
# In the resultant install directory, there are a few extra directories
# that we don"t want for our Windows build.
###
echo `date` " Removing unecessary directories from build..." >> $LOGFILE
echo "Directory clean up for pic-tools"

rmdir  $WORKING_DIR/win32-image/pic32-tools/include
rm -rf $WORKING_DIR/win32-image/pic32-tools/man
rm -rf $WORKING_DIR/win32-image/pic32-tools/info
rm -rf $WORKING_DIR/win32-image/pic32-tools/share
rm -rf $WORKING_DIR/win32-image/pic32-tools/libsrc

rmdir  $WORKING_DIR/$NATIVEIMAGE/pic32-tools/include
rm -rf $WORKING_DIR/$NATIVEIMAGE/pic32-tools/man
rm -rf $WORKING_DIR/$NATIVEIMAGE/pic32-tools/info
rm -rf $WORKING_DIR/$NATIVEIMAGE/pic32-tools/share
rm -rf $WORKING_DIR/$NATIVEIMAGE/pic32-tools/libsrc

rm -rf $WORKING_DIR/export-image/pic32-tools/man
rm -rf $WORKING_DIR/export-image/pic32-tools/info
rm -rf $WORKING_DIR/export-image/pic32-tools/share
rm -rf $WORKING_DIR/export-image/pic32-tools/libsrc

if [ "x$LINUX32IMAGE" != "x" ] ; then
    rmdir  $WORKING_DIR/$LINUX32IMAGE/pic32-tools/include
    rm -rf $WORKING_DIR/$LINUX32IMAGE/pic32-tools/man
    rm -rf $WORKING_DIR/$LINUX32IMAGE/pic32-tools/info
    rm -rf $WORKING_DIR/$LINUX32IMAGE/pic32-tools/share
    rm -rf $WORKING_DIR/$LINUX32IMAGE/pic32-tools/libsrc
fi

if [ "x$SKIPPLIBIMAGE" == "x" ]
then
    cd $WORKING_DIR
    echo "Downloading $GIT_PLIB_IMAGE_TAR."
    echo `date` "Downloading $GIT_PLIB_IMAGE_TAR..." >> $LOGFILE
    if [ -e plib-image ]
    then
        rm -rf plib-image
    fi
    curl -L $GIT_PLIB_IMAGE_TAR | tar jx
    assert_success $? "Downloading the peripheral-library image from $GIT_PLIB_IMAGE_TAR"

    if [ "x$NATIVEIMAGE" != "x" ]
    then
      rsync -qavzC --include "*/" --include "*" plib-image/ $NATIVEIMAGE/pic32-tools/
      assert_success $? "ERROR: Install plib in $NATIVEIMAGE"
    fi
    if [ "x$LINUX32IMAGE" != "x" ]
    then
      rsync -qavzC --include "*/" --include "*" plib-image/ $LINUX32IMAGE/pic32-tools/
      assert_success $? "ERROR: Install plib in $LINUX32IMAGE"
    fi
    if [ -e win32-image ]
    then
      rsync -qavzC --include "*/" --include "*" plib-image/ win32-image/pic32-tools/
      assert_success $? "ERROR: Install plib in win32-image"
    fi
fi

cd $WORKING_DIR

echo "Making zip files"
#ZIP installation directory.

echo `date` " Tar components to $WORKING_DIR/zips directory..." >> $LOGFILE
echo `date` " Tar installation directory..." >> $LOGFILE
cd $WORKING_DIR
if [[ ! -e zips ]] ; then
    mkdir zips
fi

cd $WORKING_DIR

REV=${BUILD##pic32-}
#tar cjf $WORKING_DIR/zips/pic32-tools-$REV-win32-image.tar.bz2 win32-image
#tar cjf $WORKING_DIR/zips/pic32-tools-$REV-$NATIVEIMAGE.tar.bz2 $NATIVEIMAGE
#tar cjf $WORKING_DIR/zips/pic32-tools-$REV-export-image.tar.bz2 export-image
#if [ "x$LINUX32IMAGE" != "x" ]; then
#    tar cjf $WORKING_DIR/zips/pic32-tools-$REV-$LINUX32IMAGE.tar.bz2 #$LINUX32IMAGE
#fi

cd win32-image
zip -9 -r $WORKING_DIR/zips/pic32-tools-$REV-win32-image.zip pic32-tools
cd ../$NATIVEIMAGE
zip -9 -r $WORKING_DIR/zips/pic32-tools-$REV-$NATIVEIMAGE.zip pic32-tools
cd ../export-image
zip -9 -r $WORKING_DIR/zips/pic32-tools-$REV-export-image.zip pic32-tools
cd ..
if [ "x$LINUX32IMAGE" != "x" ]; then
    cd $LINUX32IMAGE
    zip -9 -r $WORKING_DIR/zips/pic32-tools-$REV-$LINUX32IMAGE.zip pic32-tools
    cd ..
fi

unset GCC_FOR_TARGET
unset CC_FOR_TARGET
unset CXX_FOR_TARGET
unset GXX_FOR_TARGET
unset CPP_FOR_TARGET
unset CC_FOR_BUILD
unset CXX_FOR_BUILD
unset CC
unset CPP
unset CXX
unset LD
unset AR

PATH=$OLDPATH
echo `date` " DONE..." >> $LOGFILE
echo DONE.
status_update "DONE"

exit 0

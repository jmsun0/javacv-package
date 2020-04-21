#!/bin/sh

BASE_DIR=$(cd `dirname $0`; pwd)
ANDROID_TMP_DIR=/data/local/tmp
ANDROID_INSTALL_DIR=$ANDROID_TMP_DIR/javacv-package
LIB_DIR=dependency_lib
OSS='linux|android|windows|ios|macosx'
ARCHS='x86|x86_64|arm|arm64'
PKG_PREFIX=javacv

function get_jars(){
[ -d $LIB_DIR ] && return 0
mvn dependency:copy-dependencies -DoutputDirectory=$LIB_DIR
}

 function build_common(){
get_jars || return 1
[[ -f $PKG_PREFIX.jar && -f $PKG_PREFIX.dex ]] && return 0
rm -rf tmp && mkdir tmp || return 1
find $LIB_DIR -name '*.jar' | grep -E -v "$OSS" | xargs -i unzip -q -o -d tmp {}
rm -rf tmp/META-INF/versions
jar cf $PKG_PREFIX.jar -C tmp .
dx --dex --multi-dex --output . $PKG_PREFIX.jar
ls class*.dex | while read file;do mv $file ${file/classes/$PKG_PREFIX};done
}

 function build_native(){
get_jars || return 1
{ [[ "$1" == "" || "$2" == "" ]] || ! echo "$OSS" | grep -q -E "(^|\|)$1(\$|\|)" || ! echo "$ARCHS" | grep -q -E "(^|\|)$2(\$|\|)"; } &&
echo "Usage: $0 build_native {OS|$OSS} {ARCH|$ARCHS}" && return 1
find . -maxdepth 1 -name "native-$1-$2.*" | grep -E -q ".+" && return 0
rm -rf tmp && mkdir tmp || return 1
find $LIB_DIR -name '*.jar' | grep $1-$2 | xargs -i unzip -q -o -d tmp {}
[ "$1" == "android" ] && tar czf $PKG_PREFIX-$1-$2.tar.gz -C tmp lib || jar cf $PKG_PREFIX-$1-$2.jar -C tmp .
}

 function build_all(){
build_common || return 1
build_native linux x86_64 || return 1
build_native windows x86_64 || return 1
build_native android arm || return 1
build_native android arm64 || return 1
build_native android x86_64 || return 1
build_native android x86 || return 1
}

 function clean(){
rm -rf $LIB_DIR tmp *.jar *.dex *.tar.gz
}

cd $BASE_DIR
[ "`type -t $1`" != "function" ] && 
cat $0 | awk 'match($0,/ function\s+(\w+)/,a){str=(str)a[1]"|"}END{print "Usage: '$0' {COMMAND|"substr(str,1,length(str)-1)"} {OPTIONS}"}' && exit 1
"$@"






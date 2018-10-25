# release build script
#
# Prerequisites:
# 1. node-rfc-release, at the same level as node-rfc
# 2. Python 2.7, required by node-gyp
#
# Run:
# source build.sh (bash build.sh)
#

# https://nodejs.org/en/download/releases/

# abi required as long node < 6.14.2 support needed
# https://github.com/nodejs/node-addon-api/issues/310#issuecomment-406659222

# Prerequisites:
# nvm install $lts
# npm -g install npm yarn

declare -a LTS_BUILD=("6.9.0" "8.9.0" "10.0.0")
declare -a LTS_TEST=("6.9.0" "6.14.3" "8.9.0" "8.11.4" "10.0.0" "10.9.0")

version=`cat ./VERSION` 

platform=`uname`

if [ "$platform" == "MSYS" ]; then
	osext="win32"
elif [ "$platform" == "Linux" ]; then
	osext="linux"
elif [ "$platform" == "Darwin" ]; then
	osext="darwin"
else
	printf "\nPlatform not supported: $platform\n"
fi

BUILD_LOG="test/pass-$osext.log"
rm $BUILD_LOG
touch $BUILD_LOG

#
# Build
#

if [ "$1" != "test" ]; then

    rm -rf lib/binding/$osext-*

    for lts in "${LTS_BUILD[@]}"
    do
        printf "\n============= building: $lts =============\n"
        nvm use $lts
        if [ $? -ne 0 ]; then
            nvm install $lts
        fi
        npm -g i npm
        rm -Rf node_modules
        npm i

        node-pre-gyp configure build package && printf "build: node: $(node -v) npm:$(npm -v) abi:$(node -e 'console.log(process.versions.modules)')\n" >> $BUILD_LOG
    done

    npm run build

fi

#
# Test
#
for lts in "${LTS_TEST[@]}"
do
    nvm use $lts
    if [ $? -ne 0 ]; then
        nvm install $lts
    fi
    printf "\n============= testing: $lts =============\n"
    npm run test
    if [ $? == 0 ]; then
        test="pass :"
    else
        test="fail $?:"
    fi
    printf $test  >> $BUILD_LOG && printf " node: $(node -v) npm:$(npm -v) abi:$(node -e 'console.log(process.versions.modules)') napi:$(node -e 'console.log(process.versions.napi)')\n" >> $BUILD_LOG
    cat $BUILD_LOG
done
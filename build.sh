#!/bin/bash

./LitGit -v

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  TOOL_DIRECTORY="$( cd -P "$( dirname "$SOURCE" )" >/dev/null && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$TOOL_DIRECTORY/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
TOOL_DIRECTORY="$( cd -P "$( dirname "$SOURCE" )" >/dev/null && pwd )"

TOOLS_DIR=$TOOL_DIRECTORY/tools

NUGET=$TOOLS_DIR/nuget.exe

MONO=/usr/lib/mono

if test -e "$MONO"
then
    MONO=mono
fi

if test -e "$NUGET"
then
    ZFLAG="-z '$NUGET'"
else
    ZFLAG=
fi

mkdir -p $TOOLS_DIR

curl -o "$NUGET" $ZFLAG "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"

$MONO $NUGET pack LitGit.nuspec -OutputDirectory output

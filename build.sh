#!/bin/bash

./LitGit

TOOLS_DIR=./tools

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
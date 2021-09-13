#!/bin/bash

rm -rf ../output/*
rm -rf packages/*

pushd ..
./build.sh
VERSION=$(ls ./output/* | grep -oP '(?<=LitGit.).*(?=.nupkg)')
popd

echo "###### VERSION: $VERSION"

echo '<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">'>LitGitPackage.target
echo '  <ItemGroup>'>>LitGitPackage.target
echo "    <PackageReference Include=\"LitGit\" Version=\"$VERSION\" PrivateAssets=\"all\" />">>LitGitPackage.target
echo '  </ItemGroup>'>>LitGitPackage.target
echo '</Project>'>>LitGitPackage.target

rm ProjectSettings.target 2> /dev/null

dotnet clean Test.csproj
dotnet run Test.csproj # 2&>logfile


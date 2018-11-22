./LitGit.ps1


$TOOLS_DIR=./tools

$NUGET=$TOOLS_DIR/nuget.exe

New-Item -ItemType Directory -Force -Path $TOOLS_DIR

wget "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -outfile $NUGET

$NUGET pack LitGit.nuspec -OutputDirectory output
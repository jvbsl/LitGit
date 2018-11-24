./LitGit.ps1

$TOOL_DIRECTORY=(split-path -parent $MyInvocation.MyCommand.Definition)

$MONO="mono"

$TOOLS_DIR="$TOOL_DIRECTORY/tools"

$NUGET="$TOOLS_DIR/nuget.exe"

New-Item -ItemType Directory -Force -Path $TOOLS_DIR

(new-object System.Net.WebClient).DownloadFile("https://dist.nuget.org/win-x86-commandline/latest/nuget.exe", $NUGET)


&$MONO $NUGET pack LitGit.nuspec -OutputDirectory output
./LitGit.ps1 -v

$TOOL_DIRECTORY=(split-path -parent $MyInvocation.MyCommand.Definition)

$TOOLS_DIR="$TOOL_DIRECTORY/tools"

$NUGET="$TOOLS_DIR/nuget.exe"

New-Item -ItemType Directory -Force -Path $TOOLS_DIR

(new-object System.Net.WebClient).DownloadFile("https://dist.nuget.org/win-x86-commandline/latest/nuget.exe", $NUGET)


if(!([System.Environment]::OSVersion.Platform -eq "Win32NT"))
{
    $ADDITIONAL_ARGS=$NUGET
    $NUGET="mono"
}

&$NUGET $ADDITIONAL_ARGS pack LitGit.nuspec -OutputDirectory output

tar -czvf ./output/litgit.tar.gz LitGit LitGit.ps1 Glob.psm1
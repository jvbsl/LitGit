function InstallAndLoadGlobDependency() {
    $packagemanagement_module = (Get-Module -ListAvailable PackageManagement -PSEdition $PSEdition -ErrorAction SilentlyContinue) | Select -First 1
    if (-Not $packagemanagement_module) { $packagemanagement_module = (Get-Module -ListAvailable PackageManagement -ErrorAction SilentlyContinue) | Select -First 1 }
    Import-Module -ModuleInfo $packagemanagement_module
    $SysGlobbingPackage=Get-Package -Name Microsoft.Extensions.FileSystemGlobbing -ErrorAction SilentlyContinue
    if (-Not $?) {
		$null = Install-Package -Source "https://api.nuget.org/v3/index.json" -Name Microsoft.Extensions.FileSystemGlobbing -Scope CurrentUser -RequiredVersion 5.0.0 -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
		if (-Not $?) {
			$null = Install-Package -Source "https://www.nuget.org/api/v2" -Name Microsoft.Extensions.FileSystemGlobbing -Scope CurrentUser -RequiredVersion 5.0.0 -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
		}
        if ($?) {
            $SysGlobbingPackage=Get-Package -Name Microsoft.Extensions.FileSystemGlobbing
        }
        else {
            Write-Error "Error: Could not install nuget package: 'Microsoft.Extensions.FileSystemGlobbing'." ; exit 1;
        }
        
        if (-Not $USE_TEMP_PROVIDER) {
            $null = Unregister-PackageSource -Name tempnuget -ErrorAction SilentlyContinue
        }
    }
    
    $SysGlobbingParentDir=Split-Path $SysGlobbingPackage.Source
    $SysGlobbingAssemblyPath=Join-Path -Path $SysGlobbingParentDir -ChildPath "lib/netstandard2.0/Microsoft.Extensions.FileSystemGlobbing.dll" -Resolve
    
    $null = [System.Reflection.Assembly]::LoadFrom($SysGlobbingAssemblyPath)
    
}

function LastPathSep {
    param([string]$str, [int]$startIndex)

    $ind1 = $str.LastIndexOf([System.IO.Path]::DirectorySeparatorChar, $startIndex)
    $ind2 = $str.LastIndexOf([System.IO.Path]::AltDirectorySeparatorChar, $startIndex)
    return [System.Math]::Max($ind1, $ind2)
}
function FirstPat {
    param([string]$path)

    $i1 = $path.IndexOf('*', 0);
    $i2 = $path.IndexOf('[', 0);
    $i3 = $path.IndexOf(']', 0);
    $i4 = $path.IndexOf('?', 0);
    
    $i1 = if ($i1 -eq -1) { [System.Int32]::MaxValue } else { $i1 }
    $i2 = if ($i2 -eq -1) { [System.Int32]::MaxValue } else { $i2 }
    $i3 = if ($i3 -eq -1) { [System.Int32]::MaxValue } else { $i3 }
    $i4 = if ($i4 -eq -1) { [System.Int32]::MaxValue } else { $i4 }
    
    return [System.Math]::Min([System.Math]::Min($i1, $i2), [System.Math]::Min($i3, $i4));
}

function SplitPattern {
    param (
        [string]$Directory
    )
    $ind = FirstPat($Directory)
    if ($ind -gt $Directory.Length) {
        return $Directory, ""
    }
    
    $ind = LastPathSep -str $Directory -startIndex $ind
    if ($ind -eq -1) {
        return ".", $Directory
    }
    return $Directory.Substring(0, $ind + 1), $Directory.Substring($ind + 1, $Directory.Length - $ind - 1);
}
function GlobSearch {
    param (
        [string]$IncludePattern
    )
    
    #try {
    #    if (Get-Command bash -ErrorAction Ignore) {
    #        $FIND_DIR=Split-Path $IncludePattern
    #        $FIND_PATTERN=Split-Path $IncludePattern -Leaf
    #        $FIND_COMMAND=-join("find $FIND_DIR -maxdepth 1 -name '", $FIND_PATTERN, "'");
    #        $res=bash -c "$FIND_COMMAND"
    #        if ($?) {
    #            return $res
    #        }
    #    }
    #}catch {}
    InstallAndLoadGlobDependency
    
    $p1,$p2 = SplitPattern -Directory $IncludePattern
    
    if (-Not $p2) {
        return @($p1)
    }
    
    $folder=[System.IO.DirectoryInfo]::new($p1);
    $matcher=[Microsoft.Extensions.FileSystemGlobbing.Matcher]::new();
    $null = $matcher.AddInclude($p2)
    
    $res=$matcher.Execute([Microsoft.Extensions.FileSystemGlobbing.Abstractions.DirectoryInfoWrapper]::new($folder))

    return $res.Files | ForEach-Object Path
}

<#
https://stackoverflow.com/questions/4998173/how-do-i-write-to-standard-error-in-powershell
.SYNOPSIS
Writes text to stderr when running in a regular console window,
to the host''s error stream otherwise.

.DESCRIPTION
Writing to true stderr allows you to write a well-behaved CLI
as a PS script that can be invoked from a batch file, for instance.

Note that PS by default sends ALL its streams to *stdout* when invoked from
cmd.exe.

This function acts similarly to Write-Host in that it simply calls
.ToString() on its input; to get the default output format, invoke
it via a pipeline and precede with Out-String.

#>
function Write-StdErr {
  param ([PSObject] $InputObject)
  $outFunc = if ($Host.Name -eq 'ConsoleHost') {
    [Console]::Error.WriteLine
  } else {
    $host.ui.WriteErrorLine
  }
  if ($InputObject) {
    [void] $outFunc.Invoke($InputObject.ToString())
  } else {
    [string[]] $lines = @()
    $Input | % { $lines += $_.ToString() }
    [void] $outFunc.Invoke($lines -join "`r`n")
  }
}
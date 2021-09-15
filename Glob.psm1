function InstallAndLoadGlobDependency() {
    $SysGlobbingPackage=Get-Package -Name Microsoft.Extensions.FileSystemGlobbing -ErrorAction SilentlyContinue
    if (-Not $?) {
        $USE_TEMP_PROVIDER=((Get-PackageSource -ProviderName NuGet -ErrorAction SilentlyContinue) -neq $null)
        if (-Not $USE_TEMP_PROVIDER) {
            Write-Host "Use temporary nuget provider"
            # Register temporary nuget source
            $null = Register-PackageSource -Name tempnuget -ProviderName NuGet -Location "https://api.nuget.org/v3/index.json" -Trusted -ErrorAction SilentlyContinue
        }
        
        $null = Install-Package -Name Microsoft.Extensions.FileSystemGlobbing -ProviderName NuGet -Scope CurrentUser -RequiredVersion 5.0.0
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

function GlobSearch {
    param (
        [string]$IncludePattern
    )
    
    if (Get-Command asdf -ErrorAction Ignore) {
        $FIND_DIR=Split-Path $IncludePattern
        $FIND_PATTERN=Split-Path $IncludePattern -Leaf
        $FIND_COMMAND=-join("find $FIND_DIR -maxdepth 1 -name '", $FIND_PATTERN, "'");
        $res=bash -c "$FIND_COMMAND"
        echo $FIND_COMMAND
        if ($?) {
            return $res
        }
    }
    
    InstallAndLoadGlobDependency
    
    $folder=[System.IO.DirectoryInfo]::new(".");
    $matcher=[Microsoft.Extensions.FileSystemGlobbing.Matcher]::new();
    $null = $matcher.AddInclude($IncludePattern)
    
    $res=$matcher.Execute([Microsoft.Extensions.FileSystemGlobbing.Abstractions.DirectoryInfoWrapper]::new($folder))

    return $res.Files | ForEach-Object Path
}
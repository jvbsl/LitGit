Import-Module $PSScriptRoot/Glob.psm1







$TOOL_DIRECTORY=(split-path -parent $MyInvocation.MyCommand.Definition)

$TEMPLATE_SEARCH_DIR="$TOOL_DIRECTORY"
$CONFIG_FILE="$TOOL_DIRECTORY/LitGit.config"

if (Test-Path "$CONFIG_FILE") {
    [System.Collections.ArrayList]$External_Variables = Get-Content -Path "$CONFIG_FILE" -ErrorAction SilentlyContinue
} else {
    [System.Collections.ArrayList]$External_Variables = @()
}


$TEMPLATE_FILES=@()
$OUTPUT_FILES=@()
$PARSING_TEMPLATE_FILES=$FALSE
$PARSING_OUTPUT_FILES=$FALSE
$USE_MACHINE_OUTPUT=$FALSE
$VERBOSE_OUTPUT=$FALSE
for ($i=0; $i -lt $args.Length; $i++)
{
	$key=$args[$i]
    if ($key -eq "-h" -Or $key -eq "--help")
    {
        Write-Host "Usage: LitGit [options]"
        Write-Host "Extracts meta information from git. Like version information from tag and commit. Authors and many more."
        Write-Host "see https://github.com/jvbsl/LitGit"
        Write-Host ""
        Write-Host "Options:"
        Write-Host "`t-c, --config <config file>`t`t`tPath to a LitGit configuration file(This can be used more than once, order is kept between config files and parameters):"
        Write-Host "`t`t`t`t`t`t`t`t see https://github.com/jvbsl/LitGit"
        Write-Host "`t-p, --parameter `"PARAMETERNAME=VALUE`"`t`tConfiguration property to set(This can be used more than once, order is kept between config files and parameters)"
        Write-Host "`t-s, --searchpath <path>`t`t`t`tPath to a directory in which to search for *.template files. Default is directory of script."
        Write-Host "`t-d, --destination-dir <path>`t`t`tThe output directory to which the templated files are written, if not specified otherwise by (-o | --outputs)."
        Write-Host "`t-t, --templates`t<templatefile1> <templatefile2>`tSpecific *.template files to process corresponding to a specific outputfile declaration."
        Write-Host "`t`t`t`t`t`t`t   If no corresponding outputfile is specified the output name is derived from template file name without '.template' extension"
        Write-Host "`t`t`t`t`t`t`t   and the output directory is the specified or default (-d | --destination-dir)."
        Write-Host "`t-o, --outputs`t<outputfile1>   <outputfile2>`tThe output files generated from the corresponding template files. see (-t | --templates)."
        Write-Host "`t-m, --machine-output`t`t`t`tGenerate machine friendlier output."
        Write-Host "`t-v, --verbose`t`t`t`tGenerate verbose output."   
        exit 0
    }
	elseif ($key -eq "-c" -Or $key -eq "--config")
	{
		$PARSING_TEMPLATE_FILES=$FALSE
		$PARSING_OUTPUT_FILES=$FALSE
		$CONFIG_FILE=$args[++$i]
		$CONFIG_FILES=GlobSearch -IncludePattern $CONFIG_FILE
	    if ($CONFIG_FILES.Count -eq 0) {Write-StdErr "Error: Configfile '$CONFIG_FILE' not found! Aborting." ; exit 1;}
	    foreach($CONFIG_FILE in $CONFIG_FILES)
	    {
		    $External_Variables.AddRange((Get-Content -Path "$CONFIG_FILE" -ErrorAction SilentlyContinue))
	    }
	}
	elseif ($key -eq "-p" -Or $key -eq "--parameter")
	{
		$PARSING_TEMPLATE_FILES=$FALSE
		$PARSING_OUTPUT_FILES=$FALSE
	    $External_Variables.Add($args[++$i])
	}
    elseif ($key -eq "-s" -Or $key -eq "--searchpath")
	{
		$PARSING_TEMPLATE_FILES=$FALSE
		$PARSING_OUTPUT_FILES=$FALSE
		$TEMPLATE_SEARCH_DIR=$args[++$i]
		# TODO: other way to check? if (-Not (Test-Path "$TEMPLATE_SEARCH_DIR")) {Write-StdErr "Error: Template search directory '$TEMPLATE_SEARCH_DIR' not found! Aborting." ; exit 1;}
	}
	
    elseif ($key -eq "-d" -Or $key -eq "--destination-dir")
	{
		$PARSING_TEMPLATE_FILES=$FALSE
		$PARSING_OUTPUT_FILES=$FALSE
		$OUTPUT_DIR=$args[++$i]
		New-Item "$OUTPUT_DIR" -ItemType Directory -Force -ea stop
		# mkdir -p "$OUTPUT_DIR" || { Write-StdErr "Error: Could not create output directory '$OUTPUT_DIR'. Aborting."; exit 1; }
	}
	elseif ($key -eq "-t" -Or $key -eq "--templates")
	{
		$PARSING_TEMPLATE_FILES=$TRUE
		$PARSING_OUTPUT_FILES=$FALSE
	}
	elseif ($key -eq "-o" -Or $key -eq "--outputs")
	{
		$PARSING_TEMPLATE_FILES=$FALSE
		$PARSING_OUTPUT_FILES=$TRUE
	}
	elseif ($key -eq "-m" -Or $key -eq "--machine-output")
	{
		$USE_MACHINE_OUTPUT=$TRUE
	}
	elseif ($key -eq "-v" -Or $key -eq "--verbose")
	{
		$VERBOSE_OUTPUT=$TRUE
	}
	elseif ($key)
	{
    	if ($PARSING_TEMPLATE_FILES)
		{
			$TEMPLATE_FILES+=$key
		}
		elseif ($PARSING_OUTPUT_FILES)
		{
			$OUTPUT_FILES+=$key
		}
		else
		{
			Write-StdErr "Error: Invalid Argument: '$key! Aborting." ; exit 1;
		}
	}
}

if ($OUTPUT_FILES.Length -gt $TEMPLATE_FILES.Length)
{
	Write-StdErr "Error: Too many output files specified! Aborting." ; exit 1;
}
if ($TEMPLATE_FILES.Length -eq 0)
{
    # echo (Join-Path -Path $TEMPLATE_SEARCH_DIR -ChildPath "*.template")
	$TEMPLATE_FILES+=(GlobSearch -IncludePattern (Join-Path -Path $TEMPLATE_SEARCH_DIR -ChildPath "*.template") | Get-ChildItem)
}

$TMP=$TEMPLATE_FILES
$TEMPLATE_FILES=@()
for ($i=0; $i -lt $TMP.Length ;$i++) {
    $pattern=if ([System.IO.Path]::IsPathRooted($TMP[$i])) { $TMP[$i] } else { Join-Path -Path $TEMPLATE_SEARCH_DIR -ChildPath $TMP[$i] }
    $TEMPLATE_FILES+=(GlobSearch -IncludePattern $pattern | Get-ChildItem)
}

for ($i=0; $i -lt $TEMPLATE_FILES.Length ;$i++)
{
	if ($OUTPUT_FILES.Length -le $i)
	{
		if (-Not (Test-Path $TEMPLATE_FILES[$i])) {Write-StdErr "Error: Template file '${$TEMPLATE_FILES[$i]}' not found! Aborting." ; exit 1;}

        $OUTPUT_FILE=$TEMPLATE_FILES[$i]
        if (!$OUTPUT_DIR)
        {
            $TEMP_OUTPUT_DIR=[System.IO.Path]::GetDirectoryName($OUTPUT_FILE)
        } else {
            $TEMP_OUTPUT_DIR=$OUTPUT_DIR
        }
		$OUTPUT_FILE=[System.IO.Path]::GetFileNameWithoutExtension($OUTPUT_FILE)

		$OUTPUT_FILES+= "$TEMP_OUTPUT_DIR/$OUTPUT_FILE"
	}
}

if ($null -eq (Get-Command "git" -ErrorAction SilentlyContinue)  ) { Write-StdErr "Error: git command not found in PATH. Aborting."; exit 1; }


git rev-parse --git-dir 2>&1 | out-null
if ( -Not $LASTEXITCODE -eq 0)  { Write-StdErr "Error: no git repository found in path. Aborting."; exit 1; }

$LAST_TAG=(git describe --abbrev=0 --tags)

while(-Not ($LAST_TAG -Match "^([0-9]+\.)*[0-9]+\-*.*?$"))
{
    $LAST_TAG=(git describe --abbrev=0 --tags $LAST_TAG^)
}



$CURRENT_COMMIT=(git log -1 --pretty="%H")

if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Verbose output activated" }

$MATCHING_COMMIT=$(git rev-parse $LAST_TAG)
if ($USE_MACHINE_OUTPUT) {
    Write-StdErr "$LAST_TAG $MATCHING_COMMIT"
}
Write-Host "Last Tag: $LAST_TAG on commit $MATCHING_COMMIT"


# git cat-file -p $MATCHING_COMMIT

$CURRENT_BRANCH=(git rev-parse --abbrev-ref HEAD)
if ($CURRENT_BRANCH -eq "HEAD")
{
    (git branch --remote --verbose --no-abbrev --contains) -match "^[^\/]*\/([^ ]+).*"
    $CURRENT_BRANCH=$Matches[1]
}
if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Current branch: $CURRENT_BRANCH" }

if ($LAST_TAG -Match "-")
{
	$TEMP=$LAST_TAG.Split("-",2, [StringSplitOptions]"None")
	$BASE_VERSION=$TEMP[0]
	if($TEMP.Length -gt 1)
	{
		$VERSION_ADDITIONAL="-$($TEMP[1])"
	}
}
else
{
	if ($CURRENT_BRANCH -eq "master")
	{
		$VERSION_ADDITIONAL=""
	}
	else
	{
		$VERSION_ADDITIONAL="-alpha"
	}
	$BASE_VERSION=$LAST_TAG
}

if ($USE_MACHINE_OUTPUT){
    Write-StdErr "$CURRENT_BRANCH -> $BASE_VERSION*$VERSION_ADDITIONAL"
}
if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Current Branch: $CURRENT_BRANCH -> $BASE_VERSION*$VERSION_ADDITIONAL" }

$TEMP_VERSION=$BASE_VERSION.Split(".", 4 , [StringSplitOptions]"None")
$VERSION_MAJOR=$TEMP_VERSION[0]
$VERSION_MINOR=$TEMP_VERSION[1]
$VERSION_BUILD=$TEMP_VERSION[2]
$VERSION_REVISION=$TEMP_VERSION[3]

if ("$VERSION_MAJOR".Length -eq 0) { $VERSION_MAJOR="0" }
if ("$VERSION_MINOR".Length -eq 0) { $VERSION_MINOR="0" }
if ("$VERSION_BUILD".Length -eq 0) { $VERSION_BUILD="0" }
if ("$VERSION_REVISION".Length -eq 0) { $VERSION_REVISION="0" }

$INITIAL_COMMIT=(git rev-list --max-parents=0 HEAD)

$REMOTE_URL=((git remote get-url --all origin 2> $null) | Select-Object -first 1)


if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Initial Commit: $INITIAL_COMMIT" }

if ($REMOTE_URL -Match "@")
{
	$TEMP=$REMOTE_URL.Split("@",2, [StringSplitOptions]"None")[1].Replace(":","/")
	$REMOTE_URL_HTTPS="https://$TEMP"
	$REMOTE_URL_SSH=$REMOTE_URL
}
else
{
	$REMOTE_URL_HTTPS=$REMOTE_URL
}

if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Remote url: $REMOTE_URL_HTTPS" }

$YEAR=(Get-Date).year
# SET DEFAULT VALUES
$PRODUCT=if([System.IO.Path]::GetExtension($REMOTE_URL) -Match ".git" ) {[System.IO.Path]::GetFileNameWithoutExtension($REMOTE_URL)} else {[System.IO.Path]::GetFileName($REMOTE_URL)}
# AUTHORS=(git log --all --format='%aN %cE' | sort-object | Get-Unique â€“AsString)WW
$AUTHORS=(git --no-pager show -s --format='%an' "$INITIAL_COMMIT") # Author of initiial commit
$COMPANY="$AUTHORS"
$PROJECT_URL="$REMOTE_URL_HTTPS"
$COPYRIGHT="Copyright (c) $AUTHORS $YEAR"
$DESCRIPTION=""

if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Before Additional parsing" }
if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Year: $YEAR" }
if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Product: $PRODUCT" }
if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Authors: $AUTHORS" }
if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Company: $COMPANY" }
if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Project url: $PROJECT_URL" }
if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Copyright: $COPYRIGHT" }
if ($VERBOSE_OUTPUT) {  Write-Host "" }


function expandVarsStrict
(
	[String] $inputFile,
	[String] $outputFile
)
{
	$inputContent = [IO.File]::ReadAllText($inputFile)
	
	$inputContent = $inputContent.Replace('\\', '\') -replace '\$(?!{)','`$'

	$expandedContent = $ExecutionContext.InvokeCommand.ExpandString($inputContent)

	[IO.File]::WriteAllText($outputFile, $expandedContent)
}


$VERSION_REVISION=[int]$VERSION_REVISION+(git log --no-merges --oneline "$MATCHING_COMMIT..." | Measure-Object -Line).Lines

$VERSION_SHORT="$VERSION_MAJOR.$VERSION_MINOR"
$VERSION_SHORT_BUILD="$VERSION_MAJOR.$VERSION_MINOR.$VERSION_BUILD"
$VERSION_LONG="$VERSION_MAJOR.$VERSION_MINOR.$VERSION_BUILD.$VERSION_REVISION"
$VERSION_FULL="$VERSION_LONG$VERSION_ADDITIONAL"
$INFORMATIONAL_VERSION="$VERSION_FULL+${CURRENT_BRANCH}:$CURRENT_COMMIT"

$AVAILABLE_VARIABLES = @{}

foreach ($string in $External_Variables)
{
	if ("$string" -Match "=")
	{
		$TEMP=$string.Split("=",2, [StringSplitOptions]"None")
		$NAME=$TEMP[0]
		$ESCAPED=$TEMP[1].Trim('"') -replace '\$(?!{)','`$'
		$VALUE=$ExecutionContext.InvokeCommand.ExpandString($ESCAPED)
		Set-Variable -Name "$NAME" -Value $VALUE
		if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Config - Set variable '$NAME' = $VALUE" }
		$AVAILABLE_VARIABLES["$NAME"]=$VALUE
	}
}




if (-Not $AVAILABLE_VARIABLES.ContainsKey("VERSION_SHORT")) { $VERSION_SHORT="$VERSION_MAJOR.$VERSION_MINOR" }
if (-Not $AVAILABLE_VARIABLES.ContainsKey("VERSION_SHORT_BUILD")) { $VERSION_SHORT_BUILD="$VERSION_MAJOR.$VERSION_MINOR.$VERSION_BUILD" }
if (-Not $AVAILABLE_VARIABLES.ContainsKey("VERSION_LONG")) { $VERSION_LONG="$VERSION_MAJOR.$VERSION_MINOR.$VERSION_BUILD.$VERSION_REVISION" }
if (-Not $AVAILABLE_VARIABLES.ContainsKey("VERSION_FULL")) { $VERSION_FULL="$VERSION_LONG$VERSION_ADDITIONAL" }
if (-Not $AVAILABLE_VARIABLES.ContainsKey("INFORMATIONAL_VERSION")) { $INFORMATIONAL_VERSION="$VERSION_FULL+${CURRENT_BRANCH}:$CURRENT_COMMIT" }

$AVAILABLE_VARIABLES["VERSION_MAJOR"]=$VERSION_MAJOR
$AVAILABLE_VARIABLES["VERSION_MINOR"]=$VERSION_MINOR
$AVAILABLE_VARIABLES["VERSION_BUILD"]=$VERSION_BUILD
$AVAILABLE_VARIABLES["VERSION_REVISION"]=$VERSION_REVISION
$AVAILABLE_VARIABLES["CURRENT_BRANCH"]=$CURRENT_BRANCH
$AVAILABLE_VARIABLES["MATCHING_COMMIT"]=$MATCHING_COMMIT
$AVAILABLE_VARIABLES["LAST_TAG"]=$LAST_TAG
$AVAILABLE_VARIABLES["CURRENT_COMMIT"]=$CURRENT_COMMIT
$AVAILABLE_VARIABLES["VERSION_SHORT"]=$VERSION_SHORT
$AVAILABLE_VARIABLES["VERSION_SHORT_BUILD"]=$VERSION_SHORT_BUILD
$AVAILABLE_VARIABLES["VERSION_LONG"]=$VERSION_LONG
$AVAILABLE_VARIABLES["VERSION_FULL"]=$VERSION_FULL
$AVAILABLE_VARIABLES["INFORMATIONAL_VERSION"]=$INFORMATIONAL_VERSION
$AVAILABLE_VARIABLES["YEAR"]=$YEAR
$AVAILABLE_VARIABLES["PRODUCT"]=$PRODUCT
$AVAILABLE_VARIABLES["AUTHORS"]=$AUTHORS
$AVAILABLE_VARIABLES["COMPANY"]=$COMPANY
$AVAILABLE_VARIABLES["PROJECT_URL"]=$PROJECT_URL
$AVAILABLE_VARIABLES["COPYRIGHT"]=$COPYRIGHT



if ($USE_MACHINE_OUTPUT) {
    Write-StdErr $AVAILABLE_VARIABLES.count
    foreach ($h in $AVAILABLE_VARIABLES.GetEnumerator()) {
        Write-StdErr "$($h.Name)=$($h.Value)"
    }
}


if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] After Additional parsing" }
if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Year: $YEAR" }
if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Product: $PRODUCT" }
if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Authors: $AUTHORS" }
if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Company: $COMPANY" }
if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Project url: $PROJECT_URL" }
if ($VERBOSE_OUTPUT) {  Write-Host "[INFO] Copyright: $COPYRIGHT" }
if ($VERBOSE_OUTPUT) {  Write-Host "" }

for ($i=0; $i -lt $TEMPLATE_FILES.Length ;$i++) {
	$INPUT_FILE=$TEMPLATE_FILES[$i]
    if (-Not (Test-Path "$INPUT_FILE")) { continue }
	$OUTPUT_FILE=$OUTPUT_FILES[$i]
    if ($USE_MACHINE_OUTPUT) {
	    Write-StdErr "$OUTPUT_FILE"
    }
    Write-Host "Create templated file $OUTPUT_FILE..."
	expandVarsStrict "$INPUT_FILE" "$OUTPUT_FILE"
}

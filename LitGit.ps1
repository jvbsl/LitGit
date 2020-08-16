







$TOOL_DIRECTORY=(split-path -parent $MyInvocation.MyCommand.Definition)

$TEMPLATE_SEARCH_DIR="$TOOL_DIRECTORY"
$CONFIG_FILE="$TOOL_DIRECTORY/LitGit.config"

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
        echo "Usage: LitGit [options]"
        echo "Extracts meta information from git. Like version information from tag and commit. Authors and many more."
        echo "see https://github.com/jvbsl/LitGit"
        echo ""
        echo "Options:"
        echo "`t-c, --config <config file>`t`t`tPath to a LitGit configuration file: see https://github.com/jvbsl/LitGit"
        echo "`t-s, --searchpath <path>`t`t`t`tPath to a directory in which to search for *.template files. Default is directory of script."
        echo "`t-d, --destination-dir <path>`t`t`tThe output directory to which the templated files are written, if not specified otherwise by (-o | --outputs)."
        echo "`t-t, --templates`t<templatefile1> <templatefile2>`tSpecific *.template files to process corresponding to a specific outputfile declaration."
        echo "`t`t`t`t`t`t`t   If no corresponding outputfile is specified the output name is derived from template file name without '.template' extension"
        echo "`t`t`t`t`t`t`t   and the output directory is the specified or default (-d | --destination-dir)."
        echo "`t-o, --outputs`t<outputfile1>   <outputfile2>`tThe output files generated from the corresponding template files. see (-t | --templates)."
        echo "`t-m, --machine-output`t`t`t`tGenerate machine friendlier output."
        echo "`t-v, --verbose`t`t`t`tGenerate verbose output."   
        exit 0
    }
	elseif ($key -eq "-c" -Or $key -eq "--config")
	{
		$PARSING_TEMPLATE_FILES=$FALSE
		$PARSING_OUTPUT_FILES=$FALSE
		$CONFIG_FILE=$args[++$i]
		if (-Not (Test-Path "$CONFIG_FILE")) {Write-Error "Error: Configfile '$CONFIG_FILE' not found! Aborting." ; exit 1;}
	}
	
    
    elseif ($key -eq "-s" -Or $key -eq "--searchpath")
	{
		$PARSING_TEMPLATE_FILES=$FALSE
		$PARSING_OUTPUT_FILES=$FALSE
		$TEMPLATE_SEARCH_DIR=$args[++$i]
		if (-Not (Test-Path "$TEMPLATE_SEARCH_DIR")) {Write-Error "Error: Template search directory '$TEMPLATE_SEARCH_DIR' not found! Aborting." ; exit 1;}
	}
	
    elseif ($key -eq "-d" -Or $key -eq "--destination-dir")
	{
		$PARSING_TEMPLATE_FILES=$FALSE
		$PARSING_OUTPUT_FILES=$FALSE
		$TEMPLATE_SEARCH_DIR=$args[++$i]
		New-Item "$OUTPUT_DIR" -ItemType Directory -ea stop
		# mkdir -p "$OUTPUT_DIR" || { Write-Error "Error: Could not create output directory '$OUTPUT_DIR'. Aborting."; exit 1; }
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
	else
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
			Write-Error "Error: Invalid Argument: '$key! Aborting." ; exit 1;
		}
	}
}

if ($OUTPUT_FILES.Length -gt $TEMPLATE_FILES.Length)
{
	Write-Error "Error: Too many output files specified! Aborting." ; exit 1;
}
if ($TEMPLATE_FILES.Length -eq 0)
{
	$TEMPLATE_FILES+=(Get-ChildItem "$TEMPLATE_SEARCH_DIR/" -Filter "*.template")
}
for ($i=0; $i -lt $TEMPLATE_FILES.Length ;$i++)
{
	if ($OUTPUT_FILES.Length -le $i)
	{
		if (-Not (Test-Path $TEMPLATE_FILES[$i])) {Write-Error "Error: Template file '${$TEMPLATE_FILES[$i]}' not found! Aborting." ; exit 1;}

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

if ((Get-Command "git" -ErrorAction SilentlyContinue) -eq $null) { Write-Error "Error: git command not found in PATH. Aborting."; exit 1; }


git rev-parse --git-dir 2>&1 | out-null
if ( -Not $LASTEXITCODE -eq 0)  { Write-Error "Error: no git repository found in path. Aborting."; exit 1; }

$LAST_TAG=(git describe --abbrev=0 --tags)

if ($VERBOSE_OUTPUT) {  echo "[INFO] Verbose output activated" }

$MATCHING_COMMIT=$(git rev-parse $LAST_TAG)
if ($USE_MACHINE_OUTPUT) {
    echo "$LAST_TAG $MATCHING_COMMIT"
} else {
    echo "Last Tag: $LAST_TAG on commit $MATCHING_COMMIT"
}

# git cat-file -p $MATCHING_COMMIT

$CURRENT_BRANCH=(git rev-parse --abbrev-ref HEAD)
if ($CURRENT_BRANCH -eq "HEAD")
{
    (git branch --remote --verbose --no-abbrev --contains) -match "^[^\/]*\/([^ ]+).*"
    $CURRENT_BRANCH=$Matches[1]
}
if ($VERBOSE_OUTPUT) {  echo "[INFO] Current branch: $CURRENT_BRANCH" }

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

if (!$USE_MACHINE_OUTPUT){
    echo "Current Branch: $CURRENT_BRANCH -> $BASE_VERSION*$VERSION_ADDITIONAL"
} else {
    if ($VERBOSE_OUTPUT) {  echo "[INFO] Current Branch: $CURRENT_BRANCH -> $BASE_VERSION*$VERSION_ADDITIONAL" }
}
$TEMP_VERSION=$BASE_VERSION.Split(".", 4 , [StringSplitOptions]"None")
$VERSION_MAJOR=$TEMP_VERSION[0]
$VERSION_MINOR=$TEMP_VERSION[1]
$VERSION_BUILD=$TEMP_VERSION[2]
$VERSION_REVISION=$TEMP_VERSION[3]

$INITIAL_COMMIT=(git rev-list --max-parents=0 HEAD)

$REMOTE_URL=((git remote get-url --all origin 2> $null) | select -first 1)


if ($VERBOSE_OUTPUT) {  echo "[INFO] Initial Commit: $INITIAL_COMMIT" }

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

if ($VERBOSE_OUTPUT) {  echo "[INFO] Remote url: $REMOTE_URL_HTTPS" }

$YEAR=(Get-Date).year
# SET DEFAULT VALUES
$PRODUCT=if([System.IO.Path]::GetExtension($REMOTE_URL) -Match ".git" ) {[System.IO.Path]::GetFileNameWithoutExtension($REMOTE_URL)} else {[System.IO.Path]::GetFileName($REMOTE_URL)}
# AUTHORS=(git log --all --format='%aN %cE' | sort-object | Get-Unique â€“AsString)WW
$AUTHORS=(git --no-pager show -s --format='%an' "$INITIAL_COMMIT") # Author of initiial commit
$COMPANY="$AUTHORS"
$PROJECT_URL="$REMOTE_URL_HTTPS"
$COPYRIGHT="Copyright (c) $AUTHORS $YEAR"
$DESCRIPTION=""

if ($VERBOSE_OUTPUT) {  echo "[INFO] Before Additional parsing" }
if ($VERBOSE_OUTPUT) {  echo "[INFO] Year: $YEAR" }
if ($VERBOSE_OUTPUT) {  echo "[INFO] Product: $PRODUCT" }
if ($VERBOSE_OUTPUT) {  echo "[INFO] Authors: $AUTHORS" }
if ($VERBOSE_OUTPUT) {  echo "[INFO] Company: $COMPANY" }
if ($VERBOSE_OUTPUT) {  echo "[INFO] Project url: $PROJECT_URL" }
if ($VERBOSE_OUTPUT) {  echo "[INFO] Copyright: $COPYRIGHT" }
if ($VERBOSE_OUTPUT) {  echo "" }


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


$External_Variables = Get-Content -Path "$CONFIG_FILE" -ErrorAction SilentlyContinue
foreach ($string in $External_Variables)
{
	if ("$string" -Match "=")
	{
		$TEMP=$string.Split("=",2, [StringSplitOptions]"None")
		$NAME=$TEMP[0]
		$ESCAPED=$TEMP[1].Trim('"') -replace '\$(?!{)','`$'
		$VALUE=$ExecutionContext.InvokeCommand.ExpandString($ESCAPED)
		Set-Variable -Name "$NAME" -Value $VALUE
	}
}


if ("$VERSION_REVISION".Length -eq 0)
{
    $VERSION_REVISION=(git log --no-merges --oneline "$MATCHING_COMMIT..." | Measure-Object -Line).Lines
}

$VERSION_SHORT="$VERSION_MAJOR.$VERSION_MINOR"
$VERSION_SHORT_BUILD="$VERSION_MAJOR.$VERSION_MINOR.$VERSION_BUILD"
$VERSION_LONG="$VERSION_MAJOR.$VERSION_MINOR.$VERSION_BUILD.$VERSION_REVISION"
$VERSION_FULL="$VERSION_LONG$VERSION_ADDITIONAL"

$INFORMATIONAL_VERSION="$VERSION_FULL+${CURRENT_BRANCH}:$MATCHING_COMMIT"

if ($VERBOSE_OUTPUT) {  echo "[INFO] After Additional parsing" }
if ($VERBOSE_OUTPUT) {  echo "[INFO] Year: $YEAR" }
if ($VERBOSE_OUTPUT) {  echo "[INFO] Product: $PRODUCT" }
if ($VERBOSE_OUTPUT) {  echo "[INFO] Authors: $AUTHORS" }
if ($VERBOSE_OUTPUT) {  echo "[INFO] Company: $COMPANY" }
if ($VERBOSE_OUTPUT) {  echo "[INFO] Project url: $PROJECT_URL" }
if ($VERBOSE_OUTPUT) {  echo "[INFO] Copyright: $COPYRIGHT" }
if ($VERBOSE_OUTPUT) {  echo "" }

for ($i=0; $i -lt $TEMPLATE_FILES.Length ;$i++) {
	$INPUT_FILE=$TEMPLATE_FILES[$i]
    if (-Not (Test-Path "$INPUT_FILE")) { continue }
	$OUTPUT_FILE=$OUTPUT_FILES[$i]
    if ($USE_MACHINE_OUTPUT) {
	    echo "$OUTPUT_FILE"
    } else {
        echo "Create templated file $OUTPUT_FILE..."
    }
	expandVarsStrict "$INPUT_FILE" "$OUTPUT_FILE"
}

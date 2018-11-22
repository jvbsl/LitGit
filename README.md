# LitGit
git version extraction and templating tool

```
Usage: LitGit [options]
Extracts meta information from git. Like version information from tag and commit. Authors and many more.
see https://github.com/jvbsl/LitGit

Options:
	-c, --config					Path to a LitGit configuration file: see https://github.com/jvbsl/LitGit
	-s, --searchpath				Path to a directory in which to search for *.template files. Default is directory of script.
	-d, --destination-dir				The output directory to which the templated files are written, if not specified otherwise by (-o | --outputs).
	-t, --templates	<templatefile1> <templatefile2>	Specific *.template files to process corresponding to a specific outputfile declaration.
							   If no corresponding outputfile is specified the output name is derived from template file name without '.template' extension
							   and the output directory is the specified or default (-d | --destination-dir).
	-o, --outputs	<outputfile1>   <outputfile2>	The output files generated from the corresponding template files. see (-t | --templates).
 ``` 
 
 LitGit.config files example:
 ```
 COMPANY="jvbsl"
AUTHORS="jvbsl"
PROJECT_URL="https://github.com/jvbsl/engenious"
PRODUCT="engenious"
COPYRIGHT="Copyright (c) ${AUTHORS} ${YEAR}"
DESCRIPTION="3D Engine similar structure to XNA."

NUGET_ID="${PRODUCT}"
NUGET_TITLE="${PRODUCT}"
NUGET_REQUIRESLICENSEACCEPTANCE="false"
 ```
 
 Template files can use these variables via e.g. `${COMPANY}` other content can be as you want it to be, while the variables will be replaced.

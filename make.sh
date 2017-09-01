#!/bin/bash
set -e

function print_help {
	printf "Available Commands:\n";
	awk -v sq="'" '/^function run_([a-zA-Z0-9-]*)\s*/ {print "-e " sq NR "p" sq " -e " sq NR-1 "p" sq }' make.sh \
		| while read line; do eval "sed -n $line make.sh"; done \
		| paste -d"|" - - \
		| sed -e 's/^/  /' -e 's/function run_//' -e 's/#//' -e 's/{/	/' \
		| awk -F '|' '{ print "  " $2 "\t" $1}' \
		| expand -t 30
}

function run_checkout-6906 { #checkout the Delft3D version tagged as 6906
	svn co https://svn.oss.deltares.nl/repos/delft3d/tags/6906/
}

function run_build-6906 { #build the Delft3D Docker container for 6906
if [ ! -d "6906" ]; then echo "please checkout the source code first"; exit 1; fi;
	docker build -t quay.io/nerdalize/deltares-delft3d:6906 -f 6906.Dockerfile .
}

function run_checkout-6906-extwithr { #checkout the Delft3D version with R and extended boundary
	svn co https://svn.oss.deltares.nl/repos/delft3d/tags/6906/ 6906-extwithr
	#TODO: automate boundary changes
}

function run_build-6906-extwithr { #build the Delft3D Docker container with R and extended boundary
if [ ! -d "6906-extwithr" ]; then echo "please checkout the source code first"; exit 1; fi;
	docker build -t quay.io/nerdalize/deltares-delft3d:6906-extwithr -f 6906-extwithr.Dockerfile .
}

function run_push-6906-extwithr { #push the Delft3D Docker container with R and extended boundary
if [ ! -d "6906-extwithr" ]; then echo "please checkout the source code first"; exit 1; fi;
	docker push quay.io/nerdalize/deltares-delft3d:6906-extwithr
}

case $1 in
	"checkout-6906") run_checkout-6906 ;;
	"build-6906") run_build-6906 ;;
	"checkout-6906-extwithr") run_checkout-6906-extwithr ;;
	"build-6906-extwithr") run_build-6906-extwithr ;;
	"push-6906-extwithr") run_push-6906-extwithr ;;
	*) print_help ;;
esac

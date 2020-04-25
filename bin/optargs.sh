#!/bin/bash 
VERSION="1.3.1"
BLD_ROOT="to_path_default"
PREFIX="to_path_install_default"
ACTION="all"
while getopts "v:b:p:m:t:h" opt; do
  case ${opt} in
    h )
	   echo "Usage: [-h] [-v|-p|-b|-m] value]"
	   echo "v	VERSION"
	   echo "b	BUILD DIRECTORY where to clone the target repository"
	   echo "p	Installation direcotry prefix"
	   echo "m	Path to modulefiles to append to variable MODULEPATH"
	   echo "t	Type of action\n
	   		all 		- Get source, build and install\
			get_source	- Only get soruce\n
			build		- Only run build recepie"
	   exit
      ;;
    v )
      export VERSION=$OPTARG
      ;;
    b )
      export BLD_ROOT=$OPTARG
      ;;
    p )
      export PREFIX=$OPTARG
      ;;
    m )
      export MODULEPATH_PREPEND=$OPTARG
      ;;
    t )
      export ACTION=$OPTARG
      ;;
    \? ) echo "Usage: cmd [-h] [-v] [-b] [-p] [-m] [-t]"
	    exit
      ;;
  esac
done
shift $((OPTIND -1))




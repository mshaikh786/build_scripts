#!/bin/bash

APP_NAME="nccl-tests"

if [ $# -eq 0 ]; then
	source optargs.sh -h
	exit
else
	source optargs.sh $@
fi

export NCCL_TESTS_VERSION=$VERSION
export SOFTWARE_ROOT=$BLD_ROOT
export BLD_DIR="${SOFTWARE_ROOT}/build/${APP_NAME}-${NCCL_TESTS_VERSION}"
export PREFIX=$PREFIX
export MODULEPATH=$MODULEPATH_PREPEND:$MODULEPATH
if [ -z "${MAX_JOBS}" ];then
		export MAX_JOBS=1
fi

function set_env {
	module load dl
	module load cuda/10.2.89
	module load openmpi-gpu/4.0.3
	module load nccl/2.6.4.1
	module list
}


function get_source {
echo "Running git clone recipe"
	if [ ! -d ${BLD_DIR} ]; then
     	echo "${BLD_DIR} dose not exist. Cloning"
     	git clone https://github.com/NVIDIA/nccl-tests.git ${BLD_DIR}
   
		if [ -d ${BLD_DIR} ]; then
			cd ${BLD_DIR}
			git fetch --tags --all
			git checkout v${NCCL_TESTS_VERSION}
		fi
	fi
}
function build {
	cd ${BLD_DIR}
	make clean
	echo "make MPI=1 MPI_HOME=${OPENMPI_HOME} CUDA_HOME=${CUDATOOLKIT_HOME} NCCL_HOME=${NCCL_HOME}"
	make MPI=1 MPI_HOME=${OPENMPI_HOME} CUDA_HOME=${CUDATOOLKIT_HOME} NCCL_HOME=${NCCL_HOME}
	mkdir -p ${NCCL_HOME}/bin
	cp -r build/* ${NCCL_HOME}/bin/
}

if [ ${ACTION} = "all" ]
 then
	set_env
	get_source
	build
elif [ ${ACTION} = "build" ] 
 then
	set_env
	build
elif [ ${ACTION} = "dryrun" ]
 then
	echo $NCCL_TESTS_VERSION
	echo $BLD_DIR
	echo $PREFIX
	echo $MODULEPATH

else 
	echo "Unrecognized ACTION"
	exit
fi



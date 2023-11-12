#!/bin/bash
APP_NAME="horovod"

if [ $# -eq 0 ]; then
	source optargs.sh -h
	exit
else
	source optargs.sh $@
fi
export HOROVOD_VERSION=$VERSION
export SOFTWARE_ROOT=$BLD_ROOT
export BLD_DIR="${SOFTWARE_ROOT}/build/${APP_NAME}-${HOROVOD_VERSION}"
export PREFIX=$PREFIX
export MODULEPATH=$MODULEPATH_PREPEND:$MODULEPATH
if [ -z "${MAX_JOBS}" ];then
		export MAX_JOBS=1
fi

function set_env(){
	module load cmake/3.28.0-rc4
	module load pytorch/2.0.1
}

function get_source(){
     	git clone https://github.com/horovod/horovod horovod-${HOROVOD_VERSION}
	if [ -d ${BLD_DIR} ]; then
		cd ${BLD_DIR}
		git fetch --tags --all
		git checkout ${HOROVOD_VERSION}
		# if you are updating an existing checkout
		git submodule sync
		git submodule update --init --recursive
	fi
	echo "sed -i 's/set(CMAKE_CXX_STANDARD 14)/set(CMAKE_CXX_STANDARD 17)/g' ${PWD}/horovod-${HOROVOD_VERSION}/horovod/torch/CMakeLists.txt"
	sed -i 's/set(CMAKE_CXX_STANDARD 14)/set(CMAKE_CXX_STANDARD 17)/g' ${PWD}/horovod-${HOROVOD_VERSION}/horovod/torch/CMakeLists.txt
}

function build(){
	
	cd ${BLD_DIR}
	export CC=mpicc CXX=mpicxx
	export HOROVOD_NCCL_HOME=${NCCL_HOME}
	
	export HOROVOD_WITH_MPI=1
	export HOROVOD_CUDA_HOME=${CUDATOOLKIT_HOME}
	export HOROVOD_BUILD_CUDA_CC_LIST=60,70,80,86
	export HOROVOD_GPU_OPERATIONS=NCCL
	export HOROVOD_ALLOW_MIXED_GPU_IMPL=0
	export HOROVOD_WITH_PYTORCH=1 
	export HOROVOD_WITHOUT_TENSORFLOW=1
	export HOROVOD_WITHOUT_MXNET=1
	export HOROVOD_WITHOUT_GLOO=1
	export MPI_C_COMPILE_OPTIONS='-std=c17'
	export MPI_CXX_COMPILE_OPTIONS='-std=c++17'
	
	
	mkdir -p ${PREFIX}/lib/python${PYTHON_MAJ_MIN_VER}/site-packages
	export PYTHONPATH=${PREFIX}/lib/python${PYTHON_MAJ_MIN_VER}/site-packages:$PYTHONPATH
	python setup.py install --prefix=${PREFIX} -v 
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
	echo $HOROVOD_VERSION
	echo $BLD_DIR
	echo $PREFIX
	echo $MODULEPATH

else 
	echo "Unrecognized ACTION"
	exit
fi

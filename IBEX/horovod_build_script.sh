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
	module load cuda/10.2.89
	module load pytorch/1.5.1
	module load /ibex/scratch/shaima0d/software/modulefiles/cmake/3.16.1
	module list
}

function get_source(){
     	git clone --recursive https://github.com/horovod/horovod horovod-${HOROVOD_VERSION}
	if [ -d ${BLD_DIR} ]; then
		cd ${BLD_DIR}
		git fetch --tags --all
		git checkout v${HOROVOD_VERSION}
		# if you are updating an existing checkout
		git submodule sync
		git submodule update --init --recursive
	fi
}

function build(){
	
	cd ${BLD_DIR}
	export CC=mpicc CXX=mpicxx
	export HOROVOD_NCCL_INCLUDE=${NCCL_HOME}/include
	export HOROVOD_NCCL_LIB=${NCCL_HOME}/lib
	export HOROVOD_WITH_MPI=1
	export HOROVOD_CUDA_HOME=${CUDATOOLKIT_HOME}
	export HOROVOD_GPU_ALLREDUCE=NCCL HOROVOD_GPU_BROADCAST=NCCL HOROVOD_GPU_ALLGATHER=MPI
	export HOROVOD_ALLOW_MIXED_GPU_IMPL=0
	export HOROVOD_WITH_PYTORCH=1 
	export HOROVOD_WITHOUT_TENSORFLOW=1
	export HOROVOD_WITHOUT_MXNET=1
	export HOROVOD_WITHOUT_GLOO=1
	
	
	mkdir -p ${PREFIX}/lib/python${PYTHON_MAJ_MIN_VER}/site-packages
	export PYTHONPATH=${PREFIX}/lib/python${PYTHON_MAJ_MIN_VER}/site-packages:$PYTHONPATH
	python setup.py install --prefix=$PREFIX
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

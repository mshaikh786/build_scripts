#!/bin/bash
export HOROVOD_VERSION=0.19.0
export TARBALL="/ibex/scratch/shaima0d/software/src/horovod-v${HOROVOD_VERSION}.tar.gz"
export BLD_DIR="/ibex/scratch/shaima0d/software/build/horovod-${HOROVOD_VERSION}"
export PREFIX="/ibex/scratch/shaima0d/software/apps/horovod/${HOROVOD_VERSION}"

function set_env(){
	module load /sw/hidden/modulefiles/compilers/python/3.6.2
	module load pytorch/1.3.1
	module load cmake
	module list
}

function get_source(){
     	git clone --recursive -b v${HOROVOD_VERSION} https://github.com/horovod/horovod horovod-${HOROVOD_VERSION}
	if [ -d ${BLD_DIR} ]; then
		cd ${BLD_DIR}
		# if you are updating an existing checkout
		git submodule sync
		git submodule update --init --recursive
	fi
	#wget https://github.com/horovod/horovod/archive/v${HOROVOD_VERSION}.tar.gz -O /ibex/scratch/shaima0d/software/src/horovod-v${HOROVOD_VERSION}.tar.gz
}

function build(){
	#tar xvf ${TARBALL}
	cd ${BLD_DIR}
	export CC=mpicc CXX=mpicxx
	export HOROVOD_NCCL_INCLUDE=${NCCL_HOME}/include
	export HOROVOD_NCCL_LIB=${NCCL_HOME}/lib
	export HOROVOD_WITH_MPI=1
	export HOROVOD_CUDA_HOME=${CUDATOOLKIT_HOME}
	export HOROVOD_GPU_ALLREDUCE=NCCL HOROVOD_GPU_BROADCAST=NCCL HOROVOD_GPU_ALLGATHER=MPI
	export HOROVOD_ALLOW_MIXED_GPU_IMPL=0
	export HOROVOD_WITH_PYHOROVOD=1 
	export HOROVOD_WITHOUT_TENSORFLOW=1
	export HOROVOD_WITHOUT_MXNET=1
	export HOROVOD_WITHOUT_GLOO=1
	export MAX_JOBS=1
	
	mkdir -p ${PREFIX}/lib/python3.6/site-packages
	export PYTHONPATH=${PREFIX}/lib/python3.6/site-packages:$PYTHONPATH
	python setup.py install --prefix=$PREFIX
}

ARG=$1
if [ ${ARG} = "all" ] || [ "${ARG}x" = "x" ]
 then
	set_env
	get_source
	build
elif [ ${ARG} = "build" ] 
 then
	set_env
	build
fi

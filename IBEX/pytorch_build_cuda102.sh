#!/bin/bash
export TORCH_VERSION=1.3.1
export BLD_DIR="/ibex/scratch/shaima0d/software/build/pytorch-${TORCH_VERSION}"
export PREFIX="/ibex/scratch/shaima0d/software/apps/pytorch/${TORCH_VERSION}"

function set_env(){
	module load cmake
	module load /sw/hidden/modulefiles/compilers/python/3.6.2
	module load gcc/6.4.0
	module load cuda/10.2.89
	module load nccl/2.4.8.1
	module load openmpi-gpu/3.1.2_cuda102
	module load pyyaml/5.2
	module load mkl/2019
}

function get_source(){
     	git clone --recursive -b v${TORCH_VERSION} https://github.com/pytorch/pytorch pytorch-${TORCH_VERSION}
	if [ -d ${BLD_DIR} ]; then
		cd ${BLD_DIR}
		# if you are updating an existing checkout
		git submodule sync
		git submodule update --init --recursive
	fi
}

function build(){
	cd ${BLD_DIR}
	if [ -d "./build" ]
	 then
		rm -rf ./build/*
	fi
	export CMAKE_C_COMPILER=gcc CMAKE_CXX_COMPILER=g++ 
	export MPICC=mpicc MPICXX=mpicxx
	export REL_WITH_DEB_INFO=ON
	export USE_CUDA=ON USE_CUDNN=ON USE_NCCL=ON USE_SYSTEM_NCCL=ON
	export USE_OPENMP=ON  USE_MKLDNN=ON USE_MKLDNN_CBLAS=ON BLAS=MKL
	export USE_DISTRIBUTED=ON
	export INTEL_MKL_DIR=$MKLROOT USE_GLOO=0 USE_ROCM=0
	export PYTORCH_BUILD_VERSION=${TORCH_VERSION} PYTORCH_BUILD_NUMBER=1
	export CUDA_HOME=${CUDATOOLKIT_HOME}
	export TORCH_CUDA_ARCH_LIST="6.0;7.0"
	export CMAKE_LIBRARY_PATH="${MKLROOT}/lib/intel64" 
	export CMAKE_INCLUDE_PATH="${MKLROOT}/include"
	export CMAKE_CXX_FLAGS="-I${CUDATOOLKIT_HOME}/include -I${NCCL_HOME}/include"
	export CMAKE_C_FLAGS="-I${CUDATOOLKIT_HOME}/include -I${NCCL_HOME}/include"
	export NCCL_INCLUDE_DIR="${NCCL_HOME}/include" NCCL_LIB_DIR="${NCCL_HOME}/lib"

	export MAX_JOBS=20
#	python setup.py build --verbose
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



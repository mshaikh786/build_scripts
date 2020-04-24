#!/bin/bash
export TORCH_VERSION=1.3.1
export BLD_DIR="/ibex/scratch/shaima0d/software/build/pytorch-${TORCH_VERSION}"
export PREFIX="/ibex/scratch/shaima0d/software/apps/pytorch/${TORCH_VERSION}"

function set_env(){
	module load cmake
	module load /sw/hidden/modulefiles/compilers/python/3.6.2
	module load gcc/6.4.0
	module load cuda/10.2.89
	module load nccl/2.6.4.1
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
	mkdir -p build
	cd build
	export CC=gcc CXX=g++ MPICC=mpicc MPICXX=mpicxx
	cmake -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ \
	-DUSE_CUDA=ON -DUSE_CUDNN=ON -DUSE_NCCL=ON -DUSE_SYSTEM_NCCL=ON \
	-DUSE_OPENMP=ON  -DUSE_MKLDNN=ON -DUSE_MKLDNN_CBLAS=ON -DBLAS=MKL \
	-DUSE_DISTRIBUTED=ON \
	-DINTEL_MKL_DIR=$MKLROOT -DUSE_GLOO=0 -DUSE_ROCM=0 \
	-DPYTORCH_BUILD_VERSION=${TORCH_VERSION} -DPYTORCH_BUILD_NUMBER=1 \
	-DCUDA_HOME=${CUDATOOLKIT_HOME} \
	-DTORCH_CUDA_ARCH_LIST="6.0;7.0" \
	-DCMAKE_EXE_LINK_FLAGS=-L ${BLD_DIR}/build/lib \
	-DCMAKE_INCLUDE_PATH="${MKLROOT}/include" \
	-DCMAKE_CXX_FLAGS="-I${CUDATOOLKIT_HOME}/include -I${NCCL_HOME}/include" \
	-DCMAKE_C_FLAGS="-I${CUDATOOLKIT_HOME}/include -I${NCCL_HOME}/include" \
	-DNCCL_INCLUDE_DIR="${NCCL_HOME}/include" -DNCCL_LIB_DIR="${NCCL_HOME}/lib" \
	-DARCH_OPT_FLAGS="-ax=CORE_AVX512" \
	-DCMAKE_INSTALL_PREFIX=$PREFIX \
	..

	
	make -j 32 VERBOSE=1
        cd ..

	LDFLAGS=$(echo -L${BLD_DIR}/build/lib)
	LDFLAGS=$LDFLAGS python setup.py install --prefix=$PREFIX
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



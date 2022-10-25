#!/bin/bash

APP_NAME="pytorch"

if [ $# -eq 0 ]; then
	source optargs.sh -h
	exit
else
	source optargs.sh $@
fi

export TORCH_VERSION=$VERSION
export SOFTWARE_ROOT=$BLD_ROOT
export BLD_DIR="${SOFTWARE_ROOT}/build/${APP_NAME}-${TORCH_VERSION}"
export PREFIX=$PREFIX
export MODULEPATH=$MODULEPATH_PREPEND:$MODULEPATH
if [ -z "${MAX_JOBS}" ];then
		export MAX_JOBS=1
fi

function set_env {
	module load cmake
	module use /sw/csgv/dl/modulefiles
	module load intelpython3
	module load cuda/11.2.2
	module load cudnn/8.2.2
	module load gcc/10.2.0
	module load mkl/2019
	module load openmpi-gpu/4.0.3
	module load nccl/2.10.3.1
	module list
}


function get_source {
echo "Running git clone recipe"
     	git clone --recursive https://github.com/pytorch/pytorch ${BLD_DIR}
	if [ -d ${BLD_DIR} ]; then
		cd ${BLD_DIR}
		git fetch --tags --all
		git checkout v${TORCH_VERSION}
		# if you are updating an existing checkout
		git submodule sync
		git submodule update --init --recursive
	fi
}
function build {
	cd ${BLD_DIR}
	if [ -d "./build" ]
	 then
		rm -rf ./build/*
	fi
	mkdir -p build
	cd build

	cmake -GNinja -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ MPICC=mpicc MPICXX=mpicxx \
	-DUSE_CUDA=ON -DUSE_CUDNN=ON -DUSE_NCCL=ON -DUSE_SYSTEM_NCCL=ON \
	-DUSE_OPENMP=ON  -DUSE_MKLDNN=ON -DUSE_MKLDNN_CBLAS=ON -DBLAS=MKL \
	-DUSE_DISTRIBUTED=ON -USE_MPI=ON \
	-DCUDNN_ROOT=${CUDNN_HOME} \
	-DINTEL_MKL_DIR=$MKLROOT -DUSE_GLOO=0 -DUSE_ROCM=0 \
	-DPYTORCH_BUILD_VERSION=${TORCH_VERSION} -DPYTORCH_BUILD_NUMBER=1 \
	-DCUDA_HOME=${CUDATOOLKIT_HOME} \
	-DTORCH_CUDA_ARCH_LIST="6.0;7.0;8.0;8.6" \
	-DCMAKE_EXE_LINK_FLAGS=-L ${BLD_DIR}/build/lib \
	-DCMAKE_INCLUDE_PATH="${MKLROOT}/include" \
	-DCMAKE_CXX_FLAGS="-I${CUDATOOLKIT_HOME}/include -I${NCCL_HOME}/include" \
	-DCMAKE_C_FLAGS="-I${CUDATOOLKIT_HOME}/include -I${NCCL_HOME}/include" \
	-DNCCL_INCLUDE_DIR="${NCCL_HOME}/include" -DNCCL_LIB_DIR="${NCCL_HOME}/lib" \
	-DCMAKE_INSTALL_PREFIX=$PREFIX \
	..

	#make -j ${MAX_JOBS} VERBOSE=1
    cd ..
	
	LDFLAGS=$(echo -L${BLD_DIR}/build/lib)
	LDFLAGS=$LDFLAGS python setup.py install --prefix=$PREFIX
	ln -s $PREFIX/bin $PREFIX/lib/python${PYTHON_MAJ_MIN_VER}/site-packages/torch/bin
	ln -s $PREFIX/lib $PREFIX/lib/python${PYTHON_MAJ_MIN_VER}/site-packages/torch/lib
	mkdir -p $PREFIX/lib/python${PYTHON_MAJ_MIN_VER}/site-packages/torch/include
	ln -s $PREFIX/include/* $PREFIX/lib/python${PYTHON_MAJ_MIN_VER}/site-packages/torch/include/
	
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
	echo $TORCH_VERSION
	echo $BLD_DIR
	echo $PREFIX
	echo $MODULEPATH

else 
	echo "Unrecognized ACTION"
	exit
fi



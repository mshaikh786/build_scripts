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

	module load cmake/3.28.0-rc4
	module load openmpi/4.1.4/gnu11.2.1-cuda11.8
	module load python/3.9.16
	module load cuda/11.8
	module load openblas/0.3.24/gcc11.3.0
	module load nccl/2.17.1-cuda11.8 
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

	echo "Running CMAKE in ${PWD}"
	export CC=gcc MPICC=mpicc MPICXX=mpicxx
	export USE_CUDA=1 USE_CUDNN=1 USE_ROCM=0
	export USE_MKLDNN=0 USE_ITT=0 
	export USE_FBGEMM=0 USE_NUMPY=1
	export ATEN_THREADING=OMP 
	export USE_NCCL=1 USE_SYSTEM_NCCL=1 NCCL_ROOT=${NCCL_HOME}
	export USE_OPENMP=1 USE_DISTRIBUTED=1 USE_MPI=1 USE_GLOO=0 
	export TORCH_CUDA_ARCH_LIST="6.0;7.0;8.0;8.6"
	export CUDA_HOME=${CUDATOOLKIT_HOME}
	export BLAS=OpenBLAS
	export CFLAGS='-std=c17'
	export CXXFLAGS='-std=c++17'


	echo "Running python setup.py in ${PWD}"
	#LDFLAGS=$(echo -L${BLD_DIR}/build/lib)
	#LDFLAGS=$LDFLAGS 
	python setup.py install --prefix=$PREFIX -v
	# echo "Setting symlink in ${PWD} for site-package creation "
	# ln -s $PREFIX/bin $PREFIX/lib/python${PYTHON_MAJ_MIN_VER}/site-packages/torch/bin
	# ln -s $PREFIX/lib $PREFIX/lib/python${PYTHON_MAJ_MIN_VER}/site-packages/torch/lib
	# mkdir -p $PREFIX/lib/python${PYTHON_MAJ_MIN_VER}/site-packages/torch/include
	# ln -s $PREFIX/include/* $PREFIX/lib/python${PYTHON_MAJ_MIN_VER}/site-packages/torch/include/
	
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



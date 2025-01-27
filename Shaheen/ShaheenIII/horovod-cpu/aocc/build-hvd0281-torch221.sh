#!/bin/bash
#SBATCH -p ppn
#SBATCH -c 64


module swap PrgEnv-$(echo ${PE_ENV} | tr '[:upper:]'  '[:lower:]') PrgEnv-aocc
module load pytorch
module load cmake
module list

export TMPDIR=$SCRATCH/tmpdir

export HOROVOD_VERSION=0.28.1
export SOFTWARE_ROOT=${PWD}/horovod-${HOROVOD_VERSION}
export BLD_DIR="${SOFTWARE_ROOT}"
export PREFIX=${PWD}

if [ ! -d ${BLD_DIR} ]; then
  echo "untarring archive"
 git clone https://github.com/horovod/horovod horovod-${HOROVOD_VERSION}
 if [ -d ${BLD_DIR} ]; then
		cd ${BLD_DIR}
		git fetch --tags --all
		git checkout v${HOROVOD_VERSION}
		# if you are updating an existing checkout
		git submodule sync
		git submodule update --init --recursive
	fi
  cd ${BLD_DIR}
	echo "sed -i 's/set(CMAKE_CXX_STANDARD 14)/set(CMAKE_CXX_STANDARD 17)/g' ${PWD}/horovod/torch/CMakeLists.txt"
	sed -i 's/set(CMAKE_CXX_STANDARD 14)/set(CMAKE_CXX_STANDARD 17)/g' ${PWD}/CMakeLists.txt
	sed -i 's/set(CMAKE_CXX_STANDARD 14)/set(CMAKE_CXX_STANDARD 17)/g' ${PWD}/horovod/torch/CMakeLists.txt
fi

cd ${BLD_DIR}
if [ -d "./build" ]; then
	rm -rf build
fi
export PYTHONPATH=${PREFIX}/lib/python${PYTHON_MAJ_MIN_VER}/site-packages:${PYTHONPATH}
export CC=cc CXX=CC MPICC=cc MPICXX=CC
export LIBS="ldmapp"
export HOROVOD_MPICXX_SHOW="CC --cray-print-opts=all"
export HOROVOD_WITH_MPI=1
export HOROVOD_WITH_PYTORCH=1
export HOROVOD_WITH_PYHOROVOD=1 
export HOROVOD_WITHOUT_TENSORFLOW=1
export HOROVOD_WITHOUT_MXNET=1
export HOROVOD_WITHOUT_GLOO=1
export HOROVOD_CPU_OPERATIONS=MPI
export MAKEFLAGS=20
	
python setup.py clean	
CXXFLAGS="-include 'stdexcept'" python setup.py install --prefix=$PREFIX 
cp -r build/lib.linux-x86_64-cpython-310/horovod ${PREFIX}/lib/python${PYTHON_MAJ_MIN_VER}/site-packages/ 

#!/bin/bash
#SBATCH -p ppn


module swap PrgEnv-cray PrgEnv-gnu
module load pytorch/2.2.1
module load cmake/3.30.5
module list

export TMPDIR=$SCRATCH/tmpdir


export HOROVOD_VERSION=0.28.1
export SOFTWARE_ROOT=${PWD}/horovod-${HOROVOD_VERSION}
export BLD_DIR="${SOFTWARE_ROOT}"
export PREFIX=${PWD}/install/torch221


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
export MAKEFLAGS=20
	
python setup.py clean	
CXXFLAGS="-include 'stdexcept'" python setup.py install --prefix=$PREFIX 
cp -r build/lib.linux-x86_64-cpython-310/horovod ${PREFIX}/lib/python${PYTHON_MAJ_MIN_VER}/site-packages/ 


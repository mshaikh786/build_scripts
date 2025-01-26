#!/bin/bash

module swap PrgEnv-$(echo ${PE_ENV} | tr '[:upper:]'  '[:lower:]') PrgEnv-gnu
module load cmake/3.30.5 
module load python
module unload cray-libsci
module load mkl
module list

export PREFIX=/sw/ex111genoa/pytorch/2.2.1/gcc13.2.1/with_mkl

export LD_LIBRARY_PATH=${MKLROOT}/lib:${MKLROOT}/lib32:${PREFIX}/lib:${LD_LIBRARY_PATH}
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
export PYTHONPATH=${PREFIX}/lib/python3.10/site-packages:$PYTHONPATH
export MAX_JOBS=64

cd  pytorch-v2.2.1
python setup.py clean
USE_ROCM=0 USE_MKL=1 \
USE_MKLDNN=1 MKLDNN_CPU_RUNTIME=MKL \
USE_OPENMP=1 USE_MPI=1 ATEN_THREADING=OMP USE_FBGEMM=1 \
CC=cc CXX=CC CFLAGS='-craype-verbose' \
CXXFLAGS='-craype-verbose' \
MAX_JOBS=${MAX_JOBS} \
python setup.py install -vvv --prefix=${PREFIX} | tee ../build_with_mkl.log

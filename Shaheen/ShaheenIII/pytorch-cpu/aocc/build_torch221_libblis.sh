#!/bin/bash
#SBATCH -p ppn
#SBATCH -c 64
#SBATCH -t 02:30:00
#SBATCH --hint=nomultithread
#SBATCH -A k01

module swap PrgEnv-$(echo ${PE_ENV} | tr '[:upper:]'  '[:lower:]') PrgEnv-aocc
module load aocl
module load cmake 
module load python
module list
export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH

export MAX_JOBS=64
export PREFIX=/sw/ex111genoa/pytorch/2.2.1/aocc4.2.0

mkdir -p ${PREFIX}
cd  pytorch2.2.1

# Applying patches to enable Cray AOC
# patch -p 1 cmake/Modules/FindBLAS.cmake ../aocc_patches/BLAS_cmake.patch
# patch -p 1 cmake/Dependencies.cmake ../aocc_patches/Dependencies_cmake.patch
# patch -p 1 third_party/fbgemm/CMakeLists.txt ../aocc_patches/CMakeLists_fbgemm.patch
# patch -p 1 third_party/NNPACK/CMakeLists.txt ../aocc_patches/CMakeLists_NNPACK.patch

LDFLAGS=$(echo -L${AOCL_HOME}/lib)

python setup.py clean
USE_ROCM=0 USE_MKL=0  
	USE_MKLDNN=1 USE_MKLDNN_CBLAS=1 \
	MKLDNN_CPU_RUNTIME=OMP \
	USE_NUMA=1 \
	BLAS=AOCL  LIBS='-lblis -lomp' \
	BLAS_INCLUDE_DIR=${AOCC_HOME}/include \
	USE_OPENMP=1 USE_MPI=1 ATEN_THREADING=OMP USE_FBGEMM=1 \
	CC=cc CXX=CC CFLAGS='-craype-verbose' LDFLAGS=${LDFLAGS} \
	CXXFLAGS='-craype-verbose' \
	MAX_JOBS=${MAX_JOBS} \
	python setup.py install -vvv --prefix=${PREFIX} | tee ../build.log


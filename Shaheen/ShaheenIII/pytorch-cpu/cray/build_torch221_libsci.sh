#!/bin/bash
#SBATCH -p ppn
#SBATCH -c 64
#SBATCH -t 02:30:00
#SBATCH --hint=nomultithread
#SBATCH -A k01
module load cmake 
module load python
module list
export LD_LIBRARY_PATH=$PWD/deps/numa/lib:$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH

export MAX_JOBS=64
export PREFIX=/sw/ex111genoa/pytorch/2.2.1/cce18.0.0

mkdir -p ${PREFIX}
cd  pytorch2.2.1

# Applying patches to enable Cray CCE
#patch -p 1 cmake/Modules/FindBLAS.cmake ../cce_patches/BLAS_cmake.patch
#patch -p 1 cmake/Dependencies.cmake ../cce_patches/Dependencies_cmake.patch
#patch -p 1 cmake/Modules/FindOpenMP.cmake ../cce_patches/OpenMP_cmake.patch
#patch -p 1 third_party/fbgemm/CMakeLists.txt ../cce_patches/CMakeLists_fbgemm.patch
#patch -p 1 third_party/NNPACK/CMakeLists.txt ../cce_patches/CMakeLists_NNPACK.patch

python setup.py clean
USE_ROCM=0 USE_MKL=0  \
	USE_MKLDNN=1 USE_MKLDNN_CBLAS=1 \
	MKLDNN_CPU_RUNTIME=OMP \
	USE_NUMA=OFF \
	BLAS=CRAY \
	BLAS_INCLUDE_DIR=${CRAY_LIBSCI_PREFIX_DIR}/include \
	USE_OPENMP=1 USE_MPI=1 ATEN_THREADING=OMP USE_FBGEMM=1 \
	CC=cc CXX=CC CFLAGS='-craype-verbose' \
	CXXFLAGS='-craype-verbose' \
	MAX_JOBS=${MAX_JOBS} \
	python setup.py build
	python setup.py install -vvv --prefix=${PREFIX} | tee ../build.log

#LIBS='-lsci_cray_mp' \
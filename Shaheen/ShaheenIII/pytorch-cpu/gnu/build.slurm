#!/bin/bash

#SBATCH -p ppn
#SBATCH -t 04:0:0
#SBATCH -c 64
#SBATCH --hint=nomultithread
#SBATCH -A k01

export GIT_DISCOVERY_ACROSS_FILESYSTEM=1
./build_mkl.sh | tee build_with_mkl.log

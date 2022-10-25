#!/bin/bash
VERSION=1.8.0
TYPE=cpu
cd ucx-${VERSION}

BUILD_ROOT=/ibex/scratch/shaima0d/software
export PREFIX=$BUILD_ROOT/apps/ucx-${TYPE}/${VERSION}

module use $BUILD_ROOT/modulefiles

./configure --with-rc --with-ud --with-mlx5-dv --with-verbs=/usr --prefix=${PREFIX} --enable-mt --enable-stats


if [ $? = 0 ]; then
	echo "Running install"
	make -j 20 VERBOSE=1
fi


if [ $? = 0 ]; then
	echo "Running make install"
	make install
fi

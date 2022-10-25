#!/bin/bash
APP_NAME="gdrcopy"

if [ $# -eq 0 ]; then
	source optargs.sh -h
	exit
else
	source optargs.sh $@
fi
export GDRCOPY_VERSION=$VERSION
export SOFTWARE_ROOT=$BLD_ROOT
export BLD_DIR="${SOFTWARE_ROOT}/build/${APP_NAME}-${VERSION}"
export PREFIX=$PREFIX
export MODULEPATH=$MODULEPATH_PREPEND:$MODULEPATH
if [ -z "${MAX_JOBS}" ];then
		export MAX_JOBS=1
fi

function set_env(){
	module load /ibex/scratch/shaima0d/software/modulefiles/cmake/3.16.1
	module load cuda/10.2.89
	module list
}

function get_source(){
	 cd ${SOFTWARE_ROOT}/build
	 git clone https://github.com/libcheck/check.git
	 git clone https://github.com/NVIDIA/gdrcopy.git ${APP_NAME}-${GDRCOPY_VERSION}
}

function build(){
	 cd ${SOFTWARE_ROOT}/build/check
 	 if [ -d "./build" ]; then
		rm -rf ./build/*
	 fi
	 mkdir -p build
	 cd build
	 
	 cmake -DCMAKE_C_COMPILER=gcc -DCMAKE_INSTALL_PREFIX=${BLD_DIR} ..
	 if [ $? = 0 ]; then
	 	make clean
		echo "Running install"
		make -j ${MAX_JOBS} VERBOSE=1
	 fi
	 if [ $? = 0 ]; then
		echo "Running make install"
		make install
		sed -i 's/libdir=\${exec_prefix}\/lib/libdir=\${exec_prefix}\/lib64/g' ${BLD_DIR}/lib64/pkgconfig/check.pc
	 fi
	 
	 if [ $? = 0 ]; then
		 cd ${BLD_DIR} 
	 	 export PKG_CONFIG_PATH=${BLD_DIR}/lib64/pkgconfig:$PKG_CONFIG_PATH
	 	 make clean
	 	 make PREFIX=${PREFIX} CUDA=${CUDATOOLKIT_HOME} all install
	 fi
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
#!/bin/bash
APP_NAME="osu-micro-benchmarks"

if [ $# -eq 0 ]; then
	source optargs.sh -h
	exit
else
	source optargs.sh $@
fi
export OSU_VERSION=$VERSION
export SOFTWARE_ROOT=$BLD_ROOT
export BLD_DIR="${SOFTWARE_ROOT}/build/${APP_NAME}-${VERSION}"
export PREFIX=$PREFIX
export MODULEPATH=$MODULEPATH_PREPEND:$MODULEPATH
if [ -z "${MAX_JOBS}" ];then
		export MAX_JOBS=1
fi

function set_env(){
	module load cuda/10.2.89
	module load openmpi-gpu/3.1.2
	module list
}

function get_source(){
	 MAJ_VERSION=$(echo $VERSION | cut -d "." -f 1,2)
	 wget http://mvapich.cse.ohio-state.edu/download/mvapich/${APP_NAME}-${OSU_VERSION}.tar.gz -O ${BLD_ROOT}/src/${APP_NAME}-${OSU_VERSION}.tar.gz
}

function build(){
	 cd ${BLD_ROOT}/build
	 tar xvf $SOFTWARE_ROOT/src/${APP_NAME}-${OSU_VERSION}.tar.gz 
	 cd ${BLD_DIR}
	 CC=mpicc CXX=mpicxx ./configure --enable-cuda --with-cuda=${CUDATOOLKIT_HOME} --prefix=${OPENMPI_HOME}
	 
	 if [ $? = 0 ]; then
	 	make clean
		echo "Running install"
		make -j ${MAX_JOBS} VERBOSE=1
	 fi
	 if [ $? = 0 ]; then
		echo "Running make install"
		make install
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

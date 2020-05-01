#!/bin/bash
APP_NAME="horovod"

if [ $# -eq 0 ]; then
	source optargs.sh -h
	exit
else
	source optargs.sh $@
fi

export HOROVOD_VERSION=$VERSION
export SOFTWARE_ROOT=$BLD_ROOT
export BLD_DIR="${SOFTWARE_ROOT}/build/${APP_NAME}-${HOROVOD_VERSION}"
export PREFIX=$PREFIX
export MODULEPATH=$MODULEPATH_PREPEND:$MODULEPATH


function set_env(){
	module swap PrgEnv-cray PrgEnv-gnu
	module load cmake
	module load pytorch/1.3.1
	module unload atp
	module list
	
	export PYTHON_VERSION=$(python -c 'import platform; print(platform.python_version())')
	export PYTHON_VERSION_MAJ=$(python -c 'import platform; print(platform.python_version())' | cut -d '.' -f 1,2)
}

function get_source(){
     	git clone --recursive -b v${HOROVOD_VERSION} https://github.com/horovod/horovod ${BLD_DIR} 
	if [ -d ${BLD_DIR} ]; then
		cd ${BLD_DIR}
		# if you are updating an existing checkout
		git submodule sync
		git submodule update --init --recursive
	fi
	#wget https://github.com/horovod/horovod/archive/v${HOROVOD_VERSION}.tar.gz -O /ibex/scratch/shaima0d/software/src/horovod-v${HOROVOD_VERSION}.tar.gz
}

function build(){

	cd ${BLD_DIR}
	if [ -d "./build" ]; then
		rm -rf build
	fi
	export CC=cc CXX=CC MPICC=cc MPICXX=CC
	export HOROVOD_MPICXX_SHOW="CC --cray-print-opts=all"
	export HOROVOD_WITH_MPI=1
	export HOROVOD_WITH_PYTORCH=1
	export HOROVOD_WITH_PYHOROVOD=1 
	export HOROVOD_WITHOUT_TENSORFLOW=1
	export HOROVOD_WITHOUT_MXNET=1
	export HOROVOD_WITHOUT_GLOO=1
	export MAX_JOBS=1
	
	mkdir -p ${PREFIX}/lib/python${PYTHON_VERSION_MAJ}/site-packages
	export PYTHONPATH=${PREFIX}/lib/python${PYTHON_VERSION_MAJ}/site-packages:$PYTHONPATH
	
	python setup.py install -f --prefix=$PREFIX 
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
	echo $HOROVOD_VERSION
	echo $BLD_DIR
	echo $PREFIX
	echo $MODULEPATH

else 
	echo "Unrecognized ACTION"
	exit
fi

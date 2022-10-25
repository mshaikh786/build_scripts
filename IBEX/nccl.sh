#!/bin/bash
APP_NAME="nccl"

if [ $# -eq 0 ]; then
	source optargs.sh -h
	exit
else
	source optargs.sh $@
fi
export NCCL_VERSION=$VERSION
export SOFTWARE_ROOT=$BLD_ROOT
export BLD_DIR="${SOFTWARE_ROOT}/build/${APP_NAME}-${VERSION}"
export PREFIX=$PREFIX
export MODULEPATH=$MODULEPATH_PREPEND:$MODULEPATH
if [ -z "${MAX_JOBS}" ];then
		export MAX_JOBS=1
fi

function set_env(){
	module load cuda/10.2.89
	module list
}

function get_source(){
	 git clone https://github.com/NVIDIA/nccl.git ${BLD_DIR}
     	if [ -d ${BLD_DIR} ]; then
			cd ${BLD_DIR}
			git fetch --tags --all
			git checkout v${NCCL_VERSION}
		fi
 
}

function build(){
	 cd ${BLD_DIR}
	 make -j src.build CUDA_HOME=${CUDATOOLKIT_HOME}
	 
	 if [ $? = 0 ]; then
		make -j src.install PREFIX=${PREFIX}
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

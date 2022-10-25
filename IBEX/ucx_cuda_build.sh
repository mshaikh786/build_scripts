#!/bin/bash
APP_NAME="ucx"

if [ $# -eq 0 ]; then
	source optargs.sh -h
	exit
else
	source optargs.sh $@
fi
export UCX_VERSION=$VERSION
export SOFTWARE_ROOT=$BLD_ROOT
export BLD_DIR="${SOFTWARE_ROOT}/build/${APP_NAME}-${VERSION}"
export PREFIX=$PREFIX
export MODULEPATH=$MODULEPATH_PREPEND:$MODULEPATH
if [ -z "${MAX_JOBS}" ];then
		export MAX_JOBS=1
fi

function set_env(){
	module load dl
	module load cuda/10.2.89
	#module load gdrcopy/2.0
	module list
}

function get_source(){
     wget https://github.com/openucx/ucx/releases/download/v${UCX_VERSION}/ucx-${UCX_VERSION}.tar.gz -O $SOFTWARE_ROOT/src/ucx-${UCX_VERSION}.tar.gz
}

function build(){
	 cd ${BLD_ROOT}/build
	 tar xvf $SOFTWARE_ROOT/src/${APP_NAME}-${UCX_VERSION}.tar.gz
	 cd ${BLD_DIR}
	 
	 ./configure --with-rc --with-ud --without-cm --with-dc --with-mlx5-dv --with-rdmacm \
	 --enable-mt --with-verbs=/usr --with-cuda=${CUDATOOLKIT_HOME} \
	 --without-gdrcopy --prefix=${PREFIX}
	 #./configure --with-rc --with-ud --without-cm --with-mlx5-dv --with-rdmacm \
	 #--enable-mt --with-verbs=/usr --with-cuda=${CUDATOOLKIT_HOME} \
	 #--with-gdrcopy=${GDRCOPY_HOME} --prefix=${PREFIX}

	 
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

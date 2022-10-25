#!/bin/bash
APP_NAME="openmpi"

if [ $# -eq 0 ]; then
	source optargs.sh -h
	exit
else
	source optargs.sh $@
fi
export OPENMPI_VERSION=$VERSION
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
	module load ucx-gpu/1.10.0_cuda102
	module list
}

function get_source(){
	 MAJ_VERSION=$(echo $VERSION | cut -d "." -f 1,2)
     wget https://download.open-mpi.org/release/open-mpi/v${MAJ_VERSION}/openmpi-${OPENMPI_VERSION}.tar.bz2 -O $SOFTWARE_ROOT/src/openmpi-${OPENMPI_VERSION}.tar.bz2
 
}

function build(){
	 cd ${BLD_ROOT}/build
	 tar xvf $SOFTWARE_ROOT/src/openmpi-${OPENMPI_VERSION}.tar.bz2
	 cd ${BLD_DIR}
	 
	 ./configure --with-slurm --with-pmi=/opt/slurm/cluster/ibex/install --with-ucx=${UCX_HOME} \
	 --with-cuda=${CUDATOOLKIT_HOME} --with-verbs=/usr --enable-openib-udcm --enable-openib-rdmacm \
         --without-libfabric --without-ofi --with-mxm=no --prefix=${PREFIX} --enable-mca-no-build=btl-uct
	 
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

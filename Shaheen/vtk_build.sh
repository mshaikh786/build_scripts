#!/bin/bash

APP_NAME="VTK"

if [ $# -eq 0 ]; then
	source optargs.sh -h
	exit
else
	source optargs.sh $@
fi

export VTK_VERSION=$VERSION
export SOFTWARE_ROOT=$BLD_ROOT
export BLD_DIR="${SOFTWARE_ROOT}/build/${APP_NAME}-${VTK_VERSION}"
export PREFIX=$PREFIX
export MODULEPATH=$MODULEPATH_PREPEND:$MODULEPATH


function set_env {
	module load cmake
	module swap PrgEnv-$(echo ${PE_ENV}|tr [:upper:] [:lower:]) PrgEnv-gnu
	module load eigen
	module load cray-hdf5 cray-netcdf
	module load python/3.8.0-cdl
	module list
	export CRAYPE_LINK_TYPE=dynamic
}


function get_source {
	echo "Running git clone recipe"
	cd ${BLD_ROOT}/src
	VERSION_MAJ_MIN=$(echo $VTK_VERSION | cut -d "." -f 1,2)
	wget https://www.vtk.org/files/release/${VERSION_MAJ_MIN}/VTK-${VTK_VERSION}.tar.gz

	cd ${BLD_ROOT}/build
	tar xvf ${BLD_ROOT}/src/VTK-${VTK_VERSION}.tar.gz 
	cd ${BLD_ROOT}
}

function build() {
	echo "Running build recipe."
	cd ${BLD_DIR}
	if [ -d "./build" ]
	then
		echo "Removing $PWD/build"
		rm -rf ./build/*
	fi
	mkdir -p build 
	cd build
	echo "launcing cmake in $PWD"

    	cmake \
		-DBUILD_SHARED_LIBS=on -DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=${SW_BLDDIR} -DVTK_DATA_ROOT=${SW_BLDDIR}/VTKData \
	       	-DVTK_WRAP_PYTHON:BOOL=ON -DVTK_Group_MPI=ON -DVTK_USE_SYSTEM_LIBRARIES=ON \
		-DVTK_Group_QT=OFF -DVTK_Group_Rendering=ON -DVTK_Group_StandAlone=ON \
		-DVTK_WRAP_TCL=ON -DModule_vtkRenderingParallel:BOOL=ON \
		..
	       	
#	cmake -DBUILD_SHARED_LIBS=on -DCMAKE_BUILD_TYPE=Release \
#	-DCMAKE_INSTALL_PREFIX=${PREFIX} \
#	-DNETCDF_LIBRARY=${NETCDF_DIR}/lib -DNETCDF_INCLUDE_DIR=${NETCDF_DIR}/include \
#	-DVTK_DATA_ROOT=${PREFIX}/VTKData \
#	-DVTK_WRAP_PYTHON:BOOL=ON -DVTK_Group_MPI=OFF -DVTK_USE_SYSTEM_LIBRARIES=ON\
#	-DVTK_Group_QT=OFF -DVTK_Group_Rendering=ON -DVTK_Group_StandAlone=ON \
#	-DVTK_WRAP_TCL=ON -DModule_vtkRenderingParallel:BOOL=ON \
#	-DVTK_USE_SYSTEM_LIBRARIES=OFF \
#	-DMPI_C_COMPILER=cc -DMPI_CXX_COMPILER=CC -DMPIEXEC=srun \
#	-DPython3_ROOT_DIR=/sw/xc40cle7/python/3.8.0/cle7_gnu8.3.0 \
#	..

	files=$(grep -r isystem . |cut -d ':' -f 1) && echo $files | xargs sed -i 's;-isystem\ \/;-I\/;g' $files

	if [ $? -eq 0 ]
	then
		if [ -z $MAX_JOBS ]; then
		       make -j 24 VERBOSE=1
		else
		       make -j $MAX_JOBS VERBOSE=1
		fi
	fi
	if [ $? -eq 0 ]
	then
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
	echo VTK_VERSION $VTK_VERSION
	echo BLD_DIR $BLD_DIR
	echo PREFIX $PREFIX
	echo MODULEPATH $MODULEPATH

else 
	echo "Unrecognized ACTION"
	exit
fi



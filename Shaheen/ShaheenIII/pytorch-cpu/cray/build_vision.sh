#!/bin/bash

module swap PrgEnv-$(echo ${PE_ENV} | tr '[:upper:]'  '[:lower:]') PrgEnv-cray
module load cmake python
module load pytorch/2.2.1
module list

APP=torchvision
VERSION=0.17.0
if [ ! -d "vision-${VERSION}" ]; then
  echo "untarring archive"
  tar xvf /sw/sources/${APP}/*0.17.0*.tar.gz
fi
cd  vision-${VERSION}
export PREFIX=$(dirname ${PWD})


export CC=cc CXX=CC CFLAGS="-craype-verbose" CXXFLAGS="-craype-verbose"
python setup.py clean
python setup.py build 
python setup.py bdist_wheel

pip install --prefix=${PREFIX} dist/torchvision-0.17.0-cp310-cp310-linux_x86_64.whl

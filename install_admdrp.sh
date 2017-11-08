#!/bin/bash


module load python
CWD=`pwd`

## Paths for different installer components
#   - modify however you like...
PREFIX_ALL=$PROJWORK/bip149/$USER/admdrp/

# Subdirectories to make for runtime data
# and run scripts/io
FOLDER_ADMDRP_DATA=
FOLDER_ADMDRP_RUNS=
FOLDER_ADMDRP_ENV=admdrpenv/

# CONDA is used to provide the Task environment
#   - AdaptiveMD is not installed here
#     in the current AdaptiveMD-RP setup
INSTALL_CONDA=$PROJWORK/bip149/$USER/

# VirtualEnv is used to provide the Application Environment
#   - AdaptiveMD & RP Client, as well as RP Instance
#     run in this environment
INSTALL_ENV=$PREFIX_ALL
INSTALL_ADAPTIVEMD=$PREFIX_ALL
INSTALL_ADMDRP_DATA=$PREFIX_ALL$FOLDER_ADMDRP_DATA
INSTALL_ADMDRP_RUNS=$PREFIX_ALL$FOLDER_ADMDRP_RUNS

## Options & Versions:
ADAPTIVEMD_VERSION=jrossyra/adaptivemd.git
ADAPTIVEMD_BRANCH=rp_integration
ADAPTIVEMD_INSTALLMETHOD="-e"

CONDA_ENV_NAME=py27
CONDA_ENV_PYTHON=2.7
CONDA_VERSION=2
CONDA_PKG_VERSION=4.3.23

NUMPY_VERSION_TASK=1.12
NUMPY_VERSION_APP=1.12
OPENMM_VERSION=7.0
MONGODB_VERSION=3.3.0
PYMONGO_VERSION=3.5

# Application Package dependencies
ADMD_APP_PKG="pyyaml zmq six ujson numpy==$NUMPY_VERSION_APP"

# Task Package dependencies
ADMD_TASK_PKG="numpy=$NUMPY_VERSION_TASK openmm=$OPENMM_VERSION mdtraj pyemma"

# CONDA tries to upgrade itself at every turn
# - must stop it if installing in the outer conda
# - inside an env, conda won't update so its ok
if [[ -z "$CONDA_ENV_NAME" ]]; then
  ADMD_TASK_PKG+=" conda=$CONDA_PKG_VERSION"
fi
echo "AdaptiveMD Task Stack Installer: ", $ADMD_TASK_PKG

################################################################################
#  Create Root folder                                                          #
################################################################################
if [ ! -d $PREFIX_ALL ]; then
  mkdir $PREFIX_ALL
fi

################################################################################
#  Install MongoDB                                                             #
################################################################################
if [ ! -x "$(command -v mongod)" ]; then
  cd $INSTALL_ADMD_DB
  echo "Installing Mongo in: $INSTALL_ADMD_DB"
  curl -O https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-$MONGODB_VERSION.tgz
  tar -zxvf mongodb-linux-x86_64-$MONGODB_VERSION.tgz
  mkdir mongodb
  mv mongodb-linux-x86_64-$MONGODB_VERSION/ $FOLDER_ADMD_DB
  mkdir -p ${FOLDER_ADMD_DB}/data/db
  rm mongodb-linux-x86_64-$MONGODB_VERSION.tgz
  echo "# APPENDING PATH VARIABLE with AdaptiveMD Environment" >> ~/.bashrc
  echo "export ADMD_DB=${INSTALL_ADMD_DB}${FOLDER_ADMD_DB}/" >> ~/.bashrc
  echo "export PATH=${INSTALL_ADMD_DB}${FOLDER_ADMD_DB}/mongodb-linux-x86_64-$MONGODB_VERSION/bin/:\$PATH" >> ~/.bashrc
  echo "Done installing Mongo, appended PATH with mongodb bin folder"
  # Mongo should default to using /tmp/mongo-27017.sock as socket
  echo -e "net:\n   unixDomainSocket:\n      pathPrefix: ${INSTALL_ADMD_DB}${FOLDER_ADMD_DB}/data/\n   bindIp: 0.0.0.0" > ${INSTALL_ADMD_DB}${FOLDER_ADMD_DB}/mongo.cfg
  source ~/.bashrc
  echo "MongoDB daemon installed here: "
else
  echo "Found MongoDB already installed at: "
fi
which mongod

################################################################################
#  Install Env                                                                 #
################################################################################
if [ ! -d "$INSTALL_ENV$FOLDER_ADMDRP_ENV" ]; then
  mkdir $INSTALL_ENV
  cd $INSTALL_ENV
  virtualenv $INSTALL_ENV$FOLDER_ADMDRP_ENV
  echo "export ADMDRP_ENV=$INSTALL_ENV$FOLDER_ADMDRP_ENV" >> ~/.bashrc
  echo "export ADMDRP_ENV_ACTIVATE=\${ADMDRP_ENV}bin/activate" >> ~/.bashrc
  echo -e "\n# MORE ENVIRONMENT VARIABLES" >> $INSTALL_ENV$FOLDER_ADMDRP_ENV/bin/activate
  echo "export LD_PRELOAD=/lib64/librt.so.1" >> $INSTALL_ENV$FOLDER_ADMDRP_ENV/bin/activate
  echo "export RP_ENABLE_OLD_DEFINES=True" >> $INSTALL_ENV$FOLDER_ADMDRP_ENV/bin/activate
  echo "export RADICAL_PILOT_DBURL='mongodb://rp:rp@ds015335.mlab.com:15335/rp'" >> $INSTALL_ENV$FOLDER_ADMDRP_ENV/bin/activate
  source ~/.bashrc
else
  echo "Found VirtualEnv already installed at: "
  echo $INSTALL_ENV$FOLDER_ADMDRP_ENV
fi

################################################################################
#  Install AdaptiveMD (and RP via AdaptiveMD package specifications)           #
################################################################################
source $ADMDRP_ENV_ACTIVATE
if [ ! -d "$INSTALL_ADAPTIVEMD/adaptivemd" ]; then
  mkdir $INSTALL_ADAPTIVEMD
  cd $INSTALL_ADAPTIVEMD
  git clone https://github.com/$ADAPTIVEMD_VERSION
  cd adaptivemd
  git checkout $ADAPTIVEMD_BRANCH
  pip install $ADMD_APP_PKG
  pip install $ADAPTIVEMD_INSTALLMETHOD .
  python -W ignore -c "import adaptivemd" || echo "something wrong with adaptivemd install"
  echo "if no errors then AdaptiveMD & dependencies installed"
else
  echo "Seems AdaptiveMD is already installed, source located here:"
  echo $INSTALL_ADAPTIVEMD/adaptivemd
  python -W ignore -c "import adaptivemd; print adaptivemd.__version__"
fi
deactivate

################################################################################
#  Install Miniconda                                                           #
################################################################################
if [ -z ${CONDAPATH+x} ]; then
  mkdir $INSTALL_CONDA
  cd $INSTALL_CONDA
  curl -O https://repo.continuum.io/miniconda/Miniconda$CONDA_VERSION-latest-Linux-x86_64.sh
  bash Miniconda$CONDA_VERSION-latest-Linux-x86_64.sh -p ${INSTALL_CONDA}miniconda$CONDA_VERSION/
  echo "Miniconda conda executable here: "
  echo "export CONDAPATH=${INSTALL_CONDA}miniconda$CONDA_VERSION/bin/" >> ~/.bashrc
  source ~/.bashrc
  PATH=$CONDAPATH:$PATH
  conda config --append channels conda-forge
  conda config --append channels omnia
  conda install conda=$CONDA_PKG_VERSION
  rm Miniconda$CONDA_VERSION-latest-Linux-x86_64.sh
else
  echo "Conda is already installed, binaries folder located here:"
  PATH=$CONDAPATH:$PATH
  echo $CONDAPATH
fi

################################################################################
#  Install Conda Environment for AdaptiveMD                                    #
################################################################################
if [[ ! -z "$CONDA_ENV_NAME" ]]; then
  ENVS=`conda env list`
  if ! echo "$ENVS" | grep -q "$CONDA_ENV_NAME"; then
    echo "Creating and Activating new conda env: $CONDA_ENV_NAME"
    conda create -n $CONDA_ENV_NAME python=$CONDA_ENV_PYTHON
################################################################################
#   Install AdaptiveMD Task Stack in Conda Environment                         #
################################################################################
    source $CONDAPATH/activate $CONDA_ENV_NAME
    echo "Installing these Packages in AdaptiveMD Task Layer"
    echo $ADMD_TASK_PKG
    conda install $ADMD_TASK_PKG
    source deactivate
  fi
fi

################################################################################
#   Copy the running scripts over and make data directory                      #
################################################################################
mkdir $INSTALL_ADMDRP_DATA
mkdir $INSTALL_ADMDRP_RUNS
cp -r $CWD/runs/ $INSTALL_ADMDRP_RUNS

echo "export ADMDRP_DATA=$INSTALL_ADMDRP_DATA" >> ~/.bashrc
echo "export ADMDRP_RUNS=${INSTALL_ADMDRP_RUNS}runs/" >> ~/.bashrc

################################################################################
#  Finalize & Cleanup                                                          #
################################################################################
cd $CWD
module unload python/2.7.9


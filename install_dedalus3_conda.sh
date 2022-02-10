#!/usr/bin/env bash

# Dedalus stack builder using conda, with options for own MPI and FFTW.
# Run this file after installing conda and activating the base environment.

#############
## Options ##
#############

# Conda environment name
CONDA_ENV="dedalus3"

# Skip conda prompts
CONDA_YES=1

# Quiet conda output
CONDA_QUIET=1

# Install openmpi from conda, otherwise MPI_PATH must be set
INSTALL_MPI=1
#export MPI_PATH=

# Install fftw from conda, otherwise FFTW_PATH must be set
INSTALL_FFTW=1
#export FFTW_PATH=

# Install hdf5 from conda, otherwise HDF5_DIR must be set
INSTALL_HDF5=1
#export HDF5_DIR=

# BLAS options for numpy/scipy: "openblas" or "mkl"
BLAS="openblas"

# Python version
PYTHON_VERSION="3.8"

############
## Script ##
############

# Check requirements
if [ "${CONDA_DEFAULT_ENV}" != "base" ]
then
    >&2 echo "ERROR: Conda base environment must be activated"
    exit 1
fi

if [ ${INSTALL_MPI} -ne 1 ]
then
    if [ -z ${MPI_PATH} ]
    then
        >&2 echo "ERROR: MPI_PATH must be set"
        exit 1
    else
        echo "MPI_PATH set to '${MPI_PATH}'"
    fi
fi

if [ ${INSTALL_FFTW} -ne 1 ]
then
    if [ -z ${FFTW_PATH} ]
    then
        >&2 echo "ERROR: FFTW_PATH must be set"
        exit 1
    else
        echo "FFTW_PATH set to '${FFTW_PATH}'"
    fi
fi

if [ ${INSTALL_HDF5} -ne 1 ]
then
    if [ -z ${HDF5_DIR} ]
    then
        >&2 echo "ERROR: HDF5_DIR must be set"
        exit 1
    else
        echo "HDF5_DIR set to '${HDF5_DIR}'"
    fi
fi

prompt_to_proceed () {
    while true; do
        read -p "Proceed ([y]/n)? " proceed
        case "${proceed}" in
            "y" | "") break ;;
            "n") exit 1 ;;
            *) ;;
        esac
    done
}

CARGS=(-n ${CONDA_ENV})
if [ ${CONDA_YES} -eq 1 ]
then
    CARGS+=(-y)
fi
if [ ${CONDA_QUIET} -eq 1 ]
then
    CARGS+=(-q)
fi

echo "Setting up conda with 'source ${CONDA_PREFIX}/etc/profile.d/conda.sh'"
source ${CONDA_PREFIX}/etc/profile.d/conda.sh

echo "Preventing conda from looking in ~/.local with 'export PYTHONNOUSERSITE=1'"
export PYTHONNOUSERSITE=1

echo "Preventing conda from looking in PYTHONPATH with 'unset PYTHONPATH'"
unset PYTHONPATH

# Check if conda environment exists
conda activate ${CONDA_ENV} >&/dev/null
if [ $? -eq 0 ]
then
    echo "WARNING: Conda environment '${CONDA_ENV}' already exists"
    prompt_to_proceed
else
    echo "Building new conda environment '${CONDA_ENV}'"
    conda create "${CARGS[@]}" -c conda-forge "python=${PYTHON_VERSION}"
    conda activate ${CONDA_ENV}
fi

echo "Updating conda-forge pip, wheel, setuptools, cython"
conda install "${CARGS[@]}" -c conda-forge pip wheel setuptools cython

case "${BLAS}" in
"openblas")
    echo "Installing conda-forge openblas, numpy, scipy"
    conda install "${CARGS[@]}" -c conda-forge "libblas=*=*openblas" numpy scipy
    # Dynamically link FFTW
    export FFTW_STATIC=0
    ;;
"mkl")
    echo "Installing conda-forge mkl, numpy, scipy"
    conda install "${CARGS[@]}" -c conda-forge "libblas=*=*mkl" numpy scipy
    # Statically link FFTW to avoid MKL symbols
    export FFTW_STATIC=1
    ;;
*)
    >&2 echo "ERROR: BLAS must be 'openblas' or 'mkl'"
    exit 1
    ;;
esac

if [ ${INSTALL_MPI} -eq 1 ]
then
    echo "Installing conda-forge compilers, openmpi, mpi4py"
    conda install "${CARGS[@]}" -c conda-forge compilers openmpi openmpi-mpicc mpi4py
else
    echo "Not installing openmpi"
    echo "Installing mpi4py with pip"
    # Make sure mpicc will appear on path
    export PATH=${MPI_PATH}/bin:${PATH}
    echo "which mpicc: `which mpicc`"
    # no-cache to avoid wheels from previous pip installs
    python3 -m pip install --no-cache mpi4py
fi

if [ ${INSTALL_FFTW} -eq 1 ]
then
    echo "Installing conda-forge fftw"
    # no-deps to avoid pulling openmpi
    conda install "${CARGS[@]}" -c conda-forge --no-deps "fftw=*=*openmpi*"
else
    echo "Not installing fftw"
fi

if [ ${INSTALL_HDF5} -eq 1 ]
then
    echo "Installing conda-forge hdf5, h5py"
    conda install "${CARGS[@]}" -c conda-forge hdf5 h5py
else
    echo "Not installing hdf5"
    echo "Installing h5py with pip"
    # no-cache to avoid wheels from previous pip installs
    # no-binary to build against linked hdf5
    python3 -m pip install --no-cache --no-binary=h5py h5py
fi

echo "Installing conda-forge docopt, matplotlib"
conda install "${CARGS[@]}" -c conda-forge docopt matplotlib

echo "Installing dedalus with pip"
# no-cache to avoid wheels from previous pip installs
python3 -m pip install --no-cache http://github.com/dedalusproject/dedalus/zipball/d3/

echo "Disabled threading by default in the environment"
conda env config vars set OMP_NUM_THREADS=1
conda env config vars set NUMEXPR_MAX_THREADS=1

echo "Installation complete in conda environment '${CONDA_ENV}'"
conda deactivate


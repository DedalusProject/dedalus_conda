#!/usr/bin/env bash

# Dedalus stack builder using conda, with options for custom MPI/FFTW/HDF5.
# Run this file after installing conda and activating the base environment.

#############
## Options ##
#############

# Conda environment name
CONDA_ENV="dedalus2"

# Skip conda prompts
CONDA_YES=1

# Quiet conda output
CONDA_QUIET=1

# Install OpenMPI from conda, otherwise MPI_PATH must be set to your custom MPI prefix
INSTALL_MPI=1
#export MPI_PATH=

# Install FFTW from conda, otherwise FFTW_PATH must be set to your custom FFTW prefix
# Note: FFTW from conda will likely only work with custom MPIs that are OpenMPI
INSTALL_FFTW=1
#export FFTW_PATH=

# Install HDF5 from conda, otherwise HDF5_DIR must be set to your custom HDF5 prefix
# Note: HDF5 from conda will only be built with parallel support if MPI is installed from conda
# Note: If your custom HDF5 is built with parallel support, HDF5_MPI must be set to "ON"
INSTALL_HDF5=1
#export HDF5_DIR=
#export HDF5_MPI="ON"

# BLAS options for numpy/scipy: "openblas" or "mkl"
BLAS="openblas"

# Python version
PYTHON_VERSION="3.10"

# Install native arm64 build on Apple Silicon
# Note: Only relevent on Apple Silicon machines, where native arm64 builds may exhibit errors
APPLE_SILICON_BUILD_ARM=0

############
## Script ##
############

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
        echo "HDF5_MPI set to '${HDF5_MPI}'"
    fi
fi

# Unset arm build flag unless on Apple Silicon
if [ $(uname -s) == "Darwin" ] && [ $(uname -m) == "arm64" ]
then
    ON_APPLE_SILICON=1
else
    ON_APPLE_SILICON=0
    APPLE_SILICON_BUILD_ARM=0
fi

# Set conda flags
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
    if [ ${ON_APPLE_SILICON} -eq 1 ] && [ ${APPLE_SILICON_BUILD_ARM} -eq 0 ]
    then
        CONDA_SUBDIR=osx-64 conda create "${CARGS[@]}"
        conda activate ${CONDA_ENV}
        conda config --env --set subdir osx-64
    else
        conda create "${CARGS[@]}"
        conda activate ${CONDA_ENV}
    fi
fi

echo "Setting conda-forge as strict priority channel"
conda config --add channels conda-forge
conda config --set channel_priority strict

echo "Installing conda-forge python, pip, wheel, setuptools, cython"
conda install "${CARGS[@]}" "python=${PYTHON_VERSION}" pip wheel setuptools cython

case "${BLAS}" in
"openblas")
    echo "Installing conda-forge openblas, numpy, scipy"
    # Pin openblas on apple silicon since 0.3.20 causes ggev errors
    if [ ${APPLE_SILICON_BUILD_ARM} -eq 1 ]
    then
        conda install "${CARGS[@]}" "libopenblas<0.3.20"
    fi
    conda install "${CARGS[@]}" "libblas=*=*openblas" numpy scipy
    # Dynamically link FFTW
    export FFTW_STATIC=0
    ;;
"mkl")
    echo "Installing conda-forge mkl, numpy, scipy"
    conda install "${CARGS[@]}" "libblas=*=*mkl" numpy scipy
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
    conda install "${CARGS[@]}" compilers openmpi openmpi-mpicc mpi4py
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
    conda install "${CARGS[@]}" --no-deps "fftw=*=*openmpi*"
else
    echo "Not installing fftw"
fi

if [ ${INSTALL_HDF5} -eq 1 ]
then
    if [ ${INSTALL_MPI} -eq 1 ]
    then
        echo "Installing parallel conda-forge hdf5, h5py"
        conda install "${CARGS[@]}" "hdf5=*=mpi*" "h5py=*=mpi*"
    else
        echo "Installing serial conda-forge hdf5, h5py"
        conda install "${CARGS[@]}" "hdf5=*=nompi*" "h5py=*=nompi*"
    fi
else
    echo "Not installing hdf5"
    if [ ${HDF5_MPI} == "ON" ]
    then
        echo "Installing parallel h5py with pip"
        # CC=mpicc to build with parallel support
        # no-cache to avoid wheels from previous pip installs
        # no-binary to build against linked hdf5
        CC=mpicc python3 -m pip install --no-cache --no-binary=h5py h5py
    else
        echo "Installing serial h5py with pip"
        # no-cache to avoid wheels from previous pip installs
        # no-binary to build against linked hdf5
        python3 -m pip install --no-cache --no-binary=h5py h5py
    fi
fi

echo "Installing conda-forge docopt, matplotlib"
conda install "${CARGS[@]}" docopt matplotlib

echo "Installing dedalus with pip"
# no-cache to avoid wheels from previous pip installs
python3 -m pip install --no-cache "dedalus==2.*"

echo "Disabled threading by default in the environment"
conda env config vars set OMP_NUM_THREADS=1
conda env config vars set NUMEXPR_MAX_THREADS=1

echo
echo "Installation complete in conda environment '${CONDA_ENV}'"
echo
conda deactivate


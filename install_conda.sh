# Dedalus stack builder using conda, with options for own MPI and FFTW.
# Run this file after installing conda and setting CONDA_PREFIX.

#############
## Options ##
#############

# Conda environment name
CONDA_ENV="dedalus"
# Skip conda prompts
CONDA_YES=1
# Quiet conda output
CONDA_QUIET=1
# Install openmpi from conda, otherwise MPI_PATH must be set
INSTALL_MPI=1
# Install fftw from conda, otherwise FFTW_PATH must be set
INSTALL_FFTW=1
# BLAS options for numpy/scipy: "openblas" or "mkl"
BLAS="openblas"

############
## Script ##
############

# Resolve options
CARGS=(-n ${CONDA_ENV})
if [ ${CONDA_YES} -eq 1 ]
then
    CARGS+=(-y)
fi
if [ ${CONDA_QUIET} -eq 1 ]
then
    CARGS+=(-q)
fi

if [ -z ${CONDA_PREFIX} ]
then
    echo "ERROR: CONDA_PREFIX must be set"
    exit 1
else
    echo "CONDA_PREFIX set to '${CONDA_PREFIX}'"
fi

echo "Setting up conda with 'source ${CONDA_PREFIX}/etc/profile.d/conda.sh'"
source ${CONDA_PREFIX}/etc/profile.d/conda.sh

echo "Preventing conda from looking in ~/.local with 'export PYTHONNOUSERSITE=1'"
export PYTHONNOUSERSITE=1

echo "Preventing conda from looking in PYTHONPATH with 'unset PYTHONPATH'"
unset PYTHONPATH

echo "Building conda environment '${CONDA_ENV}'"
conda create "${CARGS[@]}" -c conda-forge python=3.6
conda activate ${CONDA_ENV}

echo "Updating conda-forge pip, setuptools, cython"
conda install "${CARGS[@]}" -c conda-forge pip setuptools cython

case "${BLAS}" in
"openblas")
    echo "Installing conda-forge openblas, numpy, scipy"
    conda install "${CARGS[@]}" -c conda-forge numpy=*=*openblas* scipy=*=*openblas*
    ;;
"mkl")
    echo "Installing defaults numpy, scipy"
    conda install "${CARGS[@]}" -c defaults numpy scipy
    # Statically link FFTW to avoid MKL symbols
    export FFTW_STATIC=1
    ;;
*)
    echo "ERROR: BLAS must be 'openblas' or 'mkl'"
    exit 1
    ;;
esac

if [ ${INSTALL_MPI} -eq 1 ]
then
    echo "Installing conda-forge openmpi, mpi4py"
    conda install "${CARGS[@]}" -c conda-forge openmpi mpi4py
else
    echo "Not installing openmpi."
    if [ -z ${MPI_PATH} ]
    then
        echo "ERROR: MPI_PATH must be set"
        exit 1
    else
        echo "MPI_PATH set to '${MPI_PATH}'"
    fi
    echo "Installing mpi4py with pip"
    # Make sure mpicc will appear on path
    export PATH=${MPI_PATH}/bin:${PATH}
    # no-cache to avoid wheels from previous pip installs
    python3 -m pip install --no-cache mpi4py
fi

if [ ${INSTALL_FFTW} -eq 1 ]
then
    echo "Installing cryoem fftw-mpi"
    # no-deps to avoid pulling cryoem openmpi
    conda install "${CARGS[@]}" -c cryoem --no-deps fftw-mpi
else
    echo "Not installing fftw."
    if [ -z ${FFTW_PATH} ]
    then
        echo "ERROR: FFTW_PATH must be set"
        exit 1
    else
        echo "FFTW_PATH set to '${FFTW_PATH}'"
    fi
fi

echo "Installing conda-forge hdf5, h5py"
conda install "${CARGS[@]}" -c conda-forge hdf5 h5py

echo "Installing conda-forge docopt, matplotlib"
conda install "${CARGS[@]}" -c conda-forge docopt matplotlib

echo "Installing dedalus with pip"
# no-cache to get latest version
python3 -m pip install --no-cache --pre --extra-index-url https://testpypi.python.org/pypi dedalus

echo "Installation complete in conda environment '${CONDA_ENV}'"
conda deactivate


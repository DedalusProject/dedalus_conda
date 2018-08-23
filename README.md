# Dedalus conda build notes

## Preparing system to build

To build the recipe locally, first update conda and add the build tools on the base environment with `conda update conda` and `conda install conda-build`.

## Creating the Dedalus conda build

The conda build recipe is in the `dedalus` folder and consists of three files:

* The `meta.yaml` file specifies the basic metadata and requirements for the package.
* The `build.sh` file does the build, and has been modified to set the necessary environment variables for running our `setup.py`.
* The `bld.bat` file has not been modified from the conda examples.

It currently seems like specific channels are not easily specified in the `meta.yaml` file for the conda build.
Instead, at build-time we pass a list of channels, ordered by priority.
The build command is then `conda build -c conda-forge -c cryoem dedalus`

## Installing the Dedalus conda build

Just doing `conda install -c conda-forge -c cryoem --use-local dedalus` without preinstalling the requirements results in conda trying to get blas/numpy/scipy from the defaults channel using MKL.
This is apparently due to the package solver prioritizing recips with fewer "features", and ignoring the channel priorities when doing so.
Reference github issues:

* https://github.com/conda/conda/issues/7548
* https://github.com/conda/conda/issues/3279

Instead, we can create a conda environment using `conda env create -n dedalus -f dedalus_env.yaml`.
This will setup an environment with all the run-time requirements from conda-forge/cryoem.
We can then install Dedalus using `conda install -n dedalus --use-local dedalus`.

## Installing Dedalus from source using the conda environment

A simple installation path for now is to install Dedalus from source, but into a conda environment created from the environment file.
This requires the following:

1. Setup a conda environment from the environment file:\
   `conda env create -n dedalus -f dedalus_env.yaml`

2. Activate the environment and set the path variables required to build Dedalus:\
   `conda activate dedalus`\
   `export FFTW_PATH=$CONDA_PREFIX`\
   `export MPI_PATH=$CONDA_PREFIX`

3. Build and install Dedalus from source:\
   `cd /path/to/dedalus_repo`\
   `python3 setup.py install`

## Issues

* Importing dedalus results in a numpy warning, but things seem to run fine:
`RuntimeWarning: numpy.dtype size changed, may indicate binary incompatibility. Expected 96, got 88`.
It looks like this is a harmless warning that was unmasked in numpy 1.15.0 and will be remasked in 1.15.1 (https://github.com/numpy/numpy/issues/11628).

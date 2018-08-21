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
The build command is then `conda-build -c conda-forge -c cryoem dedalus`

## Installing the Dedalus conda build

Just doing `conda install -c conda-forge -c cryoem --use-local dedalus` without preinstalling the requirements results in conda trying to get blas/numpy/scipy from the defaults channel using MKL.
This is apparently due to the package solver prioritizing recips with fewer "features", and ignoring the channel priorities when doing so.
Reference github issues:

* https://github.com/conda/conda/issues/7548
* https://github.com/conda/conda/issues/3279

Instead, we can create a conda environment using `conda-env create -n dedalus -f dedalus_env.yaml`.
This will setup an environment with all the run-time requirements from conda-forge/cryoem.
We can then install dedalus using `conda install -n dedalus --no-deps --use-local dedalus`.

## Issues

* Building from the environment file does not seem to consistenly produce the same build.
In particular, openmpi sometimes comes from conda-forge (v3) and sometimes from cryoem (v2), in which case conda-forge installs mpi and mpi4py with mpich, and things are all messed up.
Things seem to get the right order when creating an environment with the file, but not updating an environment with the file.
A work-around when things go wrong is to remove fftw-mpi from the environment file and add it by hand later.

* Importing dedalus results in a numpy warning, but things seem to run fine:
`RuntimeWarning: numpy.dtype size changed, may indicate binary incompatibility. Expected 96, got 88`.
It looks like this is a harmless warning that was unmasked in numpy 1.15.0 and will be remasked in 1.15.1 (https://github.com/numpy/numpy/issues/11628).

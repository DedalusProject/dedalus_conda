# Dedalus conda builds

## Conda package

There is currently a [Dedalus feedstock on conda-forge](https://github.com/conda-forge/dedalus-feedstock), but it has not been updated recently and is not currently maintained by the Dedalus developers.
This package may work if you want to install your entire software stack from conda-forge, but we have not tested it ourselves and are not currently supporting its use.

## Build scripts

The scripts in this repository will build a new conda environment for Dedalus and will allow you to link to system-specific MPI/FFTW/HDF5 libraries, if desired.
These scripts are tested nightly via GitHub Actions on Ubuntu and MacOS on x86 architectures.

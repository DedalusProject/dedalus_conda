# Dedalus Conda builds

## Conda-forge feedstock

There is currently a [Dedalus feedstock on conda-forge](https://github.com/conda-forge/dedalus-feedstock) which we have recently updated to support the latest Dedalus v2 release.
This feedstock builds Dedalus for Linux and macOS (x86 only) with mpich and openmpi support.
This build is recommended for laptops, workstations, and clusters that do not require linking to custom C libraries.

## Build scripts

The scripts in this repository will build a new Conda environment for Dedalus and will allow you to link to system-specific MPI/FFTW/HDF5 libraries, if desired.
These scripts are tested nightly on Ubuntu and macOS (x86 only) via GitHub Actions.

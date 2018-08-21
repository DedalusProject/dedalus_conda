export FFTW_PATH="${PREFIX}"
export MPI_PATH="${PREFIX}"
export LD_LIBRARY_PATH="${PREFIX}/lib"
$PYTHON setup.py install --single-version-externally-managed --record=record.txt

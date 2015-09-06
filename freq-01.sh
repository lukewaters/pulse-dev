#PBS -N Freq_0-01
#PBS -l nodes=2:ppn=64
#PBS -l walltime=30:00:00
#PBS -q atlas-6
#PBS -k oe
#PBS -j oe
#PBS -m abe
##PBS -l mem=240gb

RSH=/usr/bin/rsh
MYMPI=/usr/local/mvapich2/1.9/intel-13.2.146
MYDIR=$HOME/data2/FluxHi_07172015/Freq_0-01
EXE=$MYDIR/plume.exe
PATH="$MYMPI/bin:$PATH"; export PATH

MYPROCS=128

cd $MYDIR

echo "Started on `/bin/hostname`"
echo
echo "PATH is [$PATH]"
echo
echo "Nodes chosen are:"
cat $PBS_NODEFILE
echo

##$EXE
##mpirun -np $MYPROCS $EXE
mpirun -rmk pbs $EXE

##echo "======================================================================="
##$MYMPI/bin/mpirun_rsh -rsh -np $MYPROCS -hostfile $PBS_NODEFILE $EXE
##echo "======================================================================="

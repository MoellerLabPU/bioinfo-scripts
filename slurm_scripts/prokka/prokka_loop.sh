#!/bin/bash
#SBATCH --time=1-00:00:00
#SBATCH -N 1 # Nodes
#SBATCH -n 1 # Tasks
#SBATCH --cpus-per-task=20
#SBATCH --mem=80GB
#SBATCH --error=prokka_loop.%J.err
#SBATCH --output=prokka_loop.%J.out

# Load necessary modules (adjust based on your system)
# module load prokka
# or activate conda environment if needed
# conda activate prokka_env
# or set a variable for the command
# export PROKKA_CMD="singularity run -C -B $PWD --pwd $PWD /programs/prokka-1.14.5-r9/prokka.sif"

dir="/path/to/your/genomes/directory"
outdir=$dir"/prokka"

cd $dir

for genome in *.fasta
do
        prokka --cpus $SLURM_CPUS_PER_TASK --gcode 11 \
        --compliant --centre UoN --outdir $outdir/${genome/.fasta/''} \
        --locustag ${genome/.fasta/''} --prefix ${genome/.fasta/''} --force ${genome}
done
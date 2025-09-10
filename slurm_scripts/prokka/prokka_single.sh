#!/bin/bash

#SBATCH --job-name=prokka_single
#SBATCH --output=prokka_single_%j.out
#SBATCH --error=prokka_single_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8GB
#SBATCH --time=02:00:00

# Load necessary modules (adjust based on your system)
# module load prokka
# or activate conda environment if needed
# conda activate prokka_env
# or set a variable for the command
# export PROKKA_CMD="singularity run -C -B $PWD --pwd $PWD /programs/prokka-1.14.5-r9/prokka.sif"


# Input variables (modify as needed)
INPUT_FASTA="path/to/your/genome.fasta"
OUTPUT_DIR="prokka_output"
PREFIX="genome"

# Create output directory if it doesn't exist
mkdir -p $OUTPUT_DIR

# Run Prokka
prokka --cpus $SLURM_CPUS_PER_TASK --gcode 11 \
    --compliant --centre UoN --outdir $OUTPUT_DIR \
    --locustag $PREFIX --prefix $PREFIX --force $INPUT_FASTA



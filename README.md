# Bioinfo Scripts

A collection of bioinformatics workflows analysis on local machines and HPC clusters.


## 🔧 Workflows

### inStrain Pairwise Comparison Pipeline

**Location**: `snakefiles/inStrain_compare/`

A flexible Snakemake pipeline for automated pairwise comparisons of inStrain microbial strain profiles. Supports three comparison modes:

- **Type Mode**: Compare samples by category (e.g., gut vs skin microbiomes)
- **Path Mode**: Compare all profiles within specified directories  
- **Profile Mode**: Direct comparison of specific profile pairs

**Key Features**:
- 🔄 Three flexible input modes for different use cases
- 🚀 Parallel execution on HPC clusters (SLURM)
- 📊 Automated resource management
- 🗂️ Organized output structure
- ⚙️ Configurable inStrain parameters

[View detailed documentation →](snakefiles/inStrain_compare/README.md)

## 🚀 Quick Start

### Prerequisites

- **Snakemake** (≥7.0)
- **Conda/Mamba** for environment management
- **Python** packages: pandas

### Local Execution

```bash
# Clone the repository
git clone https://github.com/Sidduppal/bioinfo-scripts.git
cd bioinfo-scripts

# Navigate to a workflow
cd snakefiles/inStrain_compare

# Configure your analysis
vim config.yaml

# Test the workflow
snakemake -n

# Run locally
snakemake --cores 8
```

### Cluster Execution

For SLURM clusters, use the provided Snakemake profile:

```bash
# Test cluster submission
snakemake -s <snakefile.smk> --profile ../profile -n

# Submit to cluster
snakemake -s <snakefile.smk> --profile ../profile
```

The profile automatically handles:
- Job submission and queuing
- Resource allocation (CPU, memory, time)
- Log file organization
- Job failure handling and retries

## 📁 Repository Structure

```
bioinfo-scripts/
├── README.md                          # This file
├── LICENSE                            # GPL-3.0 license
├── snakefiles/                        # Snakemake workflows
│   ├── profile/                       # SLURM cluster profile
│   │   └── config.yaml               # Cluster execution settings
│   └── inStrain_compare/             # inStrain comparison pipeline
│       ├── README.md                 # Pipeline documentation
│       ├── config.yaml               # Pipeline configuration
│       └── inStrain_compare_parallel.smk  # Main Snakefile
└── .gitignore                        # Git ignore patterns
```
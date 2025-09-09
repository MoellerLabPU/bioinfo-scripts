# inStrain Pairwise Comparison Snakemake Pipeline

This pipeline automates pairwise comparisons of inStrain profiles, offering three flexible modes for defining which samples to compare. It is designed for scalability and can be executed on a local machine or a cluster.

## 1. How It Works

The pipeline reads a configuration file (`config.yaml`) and a tab-separated file (`pairs_tsv`) to generate and execute `inStrain compare` jobs. The core logic is determined by the `comparison_mode` set in the config.

### Comparison Modes

You can choose one of three modes in `config.yaml`:

1.  **`type` Mode**:
    *   **Use Case**: Compare all samples belonging to certain "types" (e.g., all "gut" vs. all "skin" samples).
    *   **`profiles_root`**: You must specify a root directory containing subdirectories for each sample type (e.g., `.../profiles/gut/`, `.../profiles/skin/`).
    *   **`pairs_tsv` Format**: A two-column TSV file. The file should have a header row (which will be ignored), followed by rows containing two sample type names.
      ```tsv
      sample1   sample2
      gut       skin
      gut       gut
      ```

2.  **`path` Mode**:
    *   **Use Case**: Compare all profiles located in one directory against all profiles in another.
    *   **`pairs_tsv` Format**: A two-column TSV file. The file should have a header row (which will be ignored), followed by rows containing two paths to directories.
      ```tsv
      path1                     path2
      /path/to/profiles/groupA  /path/to/profiles/groupB
      /path/to/profiles/groupA  /path/to/profiles/groupA
      ```

3.  **`profile` Mode**:
    *   **Use Case**: Compare specific, individual inStrain profiles directly.
    *   **`pairs_tsv` Format**: A two-column TSV file. The file should have a header row (which will be ignored), followed by rows containing two direct paths to `.IS` profile directories.
      ```tsv
      profile1                                  profile2
      /path/to/profiles/groupA/sample01.IS      /path/to/profiles/groupB/sample02.IS
      ```

## 2. Setup and Configuration

1.  **Clone or download this pipeline.**

2.  **Configure `config.yaml`**:
    *   `comparison_mode`: Set to `type`, `path`, or `profile`.
    *   `profiles_root`: **Required for `type` mode.** Path to the directory containing sample type subdirectories.
    *   `pairs_tsv`: Path to your tab-separated file defining comparison pairs.
    *   `compare_dir`: Path where comparison outputs will be stored.
    *   `bam_dir`: (Optional) Path to a directory with `.sorted.bam` files. If provided, the pipeline will use them.
    *   `instrain_params`: Add any additional parameters for `inStrain compare`.
    *   `resources`: Adjust threads, memory, and time for your cluster environment.

3.  **Create `pairs_tsv`**:
    *   Create a tab-separated file with a header row and two columns, formatted for your chosen `comparison_mode`.

## 3. Running the Pipeline

### Local Execution

1.  **Activate Conda Environment**:
    Ensure you have an environment with Snakemake and pandas installed.
    ```bash
    conda activate your_snakemake_env
    ```

2.  **Perform a Dry Run**:
    It's always best to check the jobs that will be executed without actually running them.
    ```bash
    snakemake -n
    ```

3.  **Execute the Pipeline**:
    ```bash
    snakemake --cores <number_of_cores>
    ```

### Cluster Execution

For cluster execution, use the provided Snakemake profile in the `profile/` directory:

1.  **Perform a Dry Run**:
    ```bash
    snakemake --profile profile -n
    ```

2.  **Execute on Cluster**:
    ```bash
    snakemake --profile profile
    ```

The profile is pre-configured for SLURM clusters and will:
- Submit jobs using `sbatch`
- Automatically manage job resources (CPU, memory, time)
- Create organized log files in `logs/{run_name}/date/rule/`
- Handle job failures and retries appropriately

You can customize the profile settings by editing `profile/config.yaml` to match your cluster configuration.

## 4. Outputs

The pipeline generates a structured output directory inside the path specified by `compare_dir`:

```
<compare_dir>/
└── <group_name>/              # e.g., gut_vs_skin or groupA_vs_groupB
    ├── <profile1>_vs_<profile2>/
    │   ├── output/
    │   │   └── <profile1>_vs_<profile2>_comparisonsTable.tsv
    │   └── ... (other inStrain outputs)
    └── logs/
        └── <profile1>_vs_<profile2>.log
```

*   **`group_name`**: A directory created based on the comparison pair (e.g., `gut_vs_skin`).
*   **`comparisonsTable.tsv`**: The main output file from `inStrain compare`.
*   **`.log`**: A log file capturing the output of the `inStrain compare` command.

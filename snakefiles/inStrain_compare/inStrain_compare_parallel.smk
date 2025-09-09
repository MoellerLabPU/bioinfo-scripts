#
# Snakefile: Flexible inStrain Pairwise Comparison
#
# Description:
# This pipeline automates running `inStrain compare` with three flexible input modes
# controlled via the `config.yaml` file (`comparison_mode`).
#
# Modes:
#  - "type":    Compares all profiles between sample types (e.g., human vs. giraffe).
#  - "path":    Compares all profiles within specified parent directories.
#  - "profile": Compares specific pairs of .IS profile directories directly.
#

import os
from glob import glob
from itertools import combinations, product
import pandas as pd

# --- 1. CONFIGURATION ---
configfile: "config.yaml"

# Load configuration settings
COMPARISON_MODE = config["comparison_mode"]
PROFILES_ROOT = config.get("profiles_root")
COMPARE_DIR = config["compare_dir"]
PAIRS_TSV = config["pairs_tsv"]
BAM_DIR = config.get("bam_dir")
PARAMS = config.get("instrain_params", {})
RESOURCES = config.get("resources", {})
USE_MODULES = bool(config.get("use_modules", True))
CONDA_ENV_NAME = config.get("conda_env_name", "inStrainEnv")

# This dictionary is crucial. It will map each target output file
# to its specific input profiles. This is a robust pattern that avoids
# complex logic in the rule's `input` block.
TARGET_MAP = {}

# --- 2. HELPER FUNCTIONS ---

def is_profile_dir(path: str) -> bool:
    """A profile is a directory whose name ends with '.IS' (all caps)."""
    return os.path.isdir(path) and os.path.basename(path).endswith(".IS")

def list_profiles_from_path(parent_path: str) -> list:
    """Returns a sorted list of full paths to valid profile directories within a given parent path."""
    if not os.path.isdir(parent_path):
        raise FileNotFoundError(f"Sample directory not found: {parent_path}")
    return sorted([p for p in glob(os.path.join(parent_path, "*")) if is_profile_dir(p)])

def make_bam_args(wc) -> str:
    """Construct the -bams argument string for a given wildcard object.
    Returns an empty string when `BAM_DIR` is not set.
    """
    if not BAM_DIR:
        return ""
    sample_a = wc.pair_name.split('_vs_')[0]
    sample_b = wc.pair_name.split('_vs_')[1]
    bam_a = os.path.join(BAM_DIR, f"{sample_a}.sorted.bam")
    bam_b = os.path.join(BAM_DIR, f"{sample_b}.sorted.bam")
    return f"-bams {bam_a} {bam_b}"

def populate_target_map():
    """
    The main logic hub. Reads the pairs_tsv and, based on the comparison_mode,
    populates the global TARGET_MAP with output-to-input mappings.
    """
    df = pd.read_csv(PAIRS_TSV, sep='\t', comment='#', header=0, names=['sample1', 'sample2'])
    df.dropna(inplace=True)
    # print(df)

    if df.empty:
        raise ValueError(f"No valid pairs found in {PAIRS_TSV}")

    # --- Mode-Specific Logic ---
    for _, row in df.iterrows():
        pathA, pathB = row.sample1, row.sample2
        typeA, typeB = "", ""
        profile_pairs = []

        if COMPARISON_MODE == "type":
            typeA, typeB = pathA, pathB
            if not PROFILES_ROOT:
                raise ValueError("`profiles_root` must be set in config.yaml for 'type' mode.")
            profiles1 = list_profiles_from_path(os.path.join(PROFILES_ROOT, typeA))
            if typeA == typeB:
                profile_pairs = combinations(profiles1, 2)
            else:
                profiles2 = list_profiles_from_path(os.path.join(PROFILES_ROOT, typeB))
                profile_pairs = product(profiles1, profiles2)
        
        elif COMPARISON_MODE == "path":
            typeA, typeB = os.path.basename(pathA.rstrip('/')), os.path.basename(pathB.rstrip('/'))
            profiles1 = list_profiles_from_path(pathA)
            if pathA == pathB:
                profile_pairs = combinations(profiles1, 2)
            else:
                profiles2 = list_profiles_from_path(pathB)
                profile_pairs = product(profiles1, profiles2)

        elif COMPARISON_MODE == "profile":
            typeA = os.path.basename(os.path.dirname(pathA))
            typeB = os.path.basename(os.path.dirname(pathB))
            profile_pairs = [(pathA, pathB)]
        
        else:
            raise ValueError(f"Invalid `comparison_mode` in config: '{COMPARISON_MODE}'")

        # --- Process Pairs and Populate Map ---
        for pA, pB in profile_pairs:
            nameA = os.path.basename(pA).replace(".IS", "")
            nameB = os.path.basename(pB).replace(".IS", "")

            # Ensure canonical ordering to avoid duplicate jobs
            if pA == pB: continue # Skip self-comparisons
            if (COMPARISON_MODE != 'profile') and (typeA == typeB) and (nameA > nameB):
                 nameA, nameB = nameB, nameA
                 pA, pB = pB, pA # Swap paths to match names

            pair_name = f"{nameA}_vs_{nameB}"
            group_name = f"{typeA}_vs_{typeB}"
            
            # For "profile" mode, if types are the same, sort them for a canonical group name
            if (COMPARISON_MODE == 'profile') and (typeA == typeB) and (typeA > typeB):
                group_name = f"{typeB}_vs_{typeA}"
                pA, pB = pB, pA # Swap paths to match names

            target_file = os.path.join(COMPARE_DIR, group_name, pair_name, "output", f"{pair_name}_comparisonsTable.tsv")
            
            if target_file not in TARGET_MAP:
                TARGET_MAP[target_file] = {"profileA": pA, "profileB": pB}

# Run the logic function to populate the map when the Snakefile is parsed
populate_target_map()

# --- 3. SNAKEMAKE RULES ---

rule all:
    input:
        TARGET_MAP.keys()

rule compare_instrain:
    input:
        # Reconstruct the target path from wildcards to look up inputs
        profileA=lambda wc: TARGET_MAP[os.path.join(COMPARE_DIR, wc.group, wc.pair_name, "output", f"{wc.pair_name}_comparisonsTable.tsv")]["profileA"],
        profileB=lambda wc: TARGET_MAP[os.path.join(COMPARE_DIR, wc.group, wc.pair_name, "output", f"{wc.pair_name}_comparisonsTable.tsv")]["profileB"]
    output:
        # Snakemake infers wildcards from the output file path.
        # Note: {group} can match names like "human_vs_giraffe".
        comparisonsTable=os.path.join(COMPARE_DIR, "{group}", "{pair_name}", "output", "{pair_name}_comparisonsTable.tsv"),
        outDir=directory(os.path.join(COMPARE_DIR, "{group}", "{pair_name}"))
    params:
        group_length=PARAMS.get("group_length", "100000"),
        breadth=PARAMS.get("breadth", "0.05"),
        cov=PARAMS.get("cov", "0.0025"),
        ani=PARAMS.get("ani", "0.99"),
        database_mode_flag=("--database_mode" if PARAMS.get("database_mode", False) else ""),
        args_stb=f"--stb {PARAMS['stbPath']}" if PARAMS.get("stbPath") else "",
        # Conditionally construct the -bams argument string using helper
        bam_args=lambda wc: make_bam_args(wc)
    # log:
    #     "logs/{group}/{pair_name}.log"
    threads:
        RESOURCES.get("threads", 8)
    resources:
        mem_mb=RESOURCES.get("mem_mb", 10000),
        time=RESOURCES.get("time", "8:00:00")
    shell:
        """
        # Optional environment setup for clusters using modules
        if [[ "{USE_MODULES}" == "True" ]]; then
          module purge
          module load anaconda3/2024.10
          conda activate {CONDA_ENV_NAME}
        fi

        inStrain compare \
            -i {input.profileA} {input.profileB} \
            -o {output.outDir} \
            -p {threads} \
            {params.database_mode_flag} \
            --store_mismatch_locations \
            --group_length {params.group_length} \
            --breadth {params.breadth} \
            -cov {params.cov} \
            -ani {params.ani} \
            {params.bam_args} \
            {params.args_stb}
        """

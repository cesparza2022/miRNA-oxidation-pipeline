# ⚡ Quick Start Guide

**Get the pipeline running in 5 minutes!**

## Step 1: Install Conda/Mamba

```bash
# Download Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

# Or install Mamba (faster)
conda install mamba -n base -c conda-forge
```

## Step 2: Clone and Setup

```bash
# Clone repository
git clone https://github.com/cesparza2022/miRNA-oxidation-pipeline.git
cd miRNA-oxidation-pipeline

# Run automated setup
bash setup.sh --mamba

# Activate environment
conda activate mirna_oxidation_pipeline
```

## Step 3: Configure

```bash
# Copy example config
cp config/config.yaml.example config/config.yaml

# Edit config file
nano config/config.yaml
```

**Update these paths:**
```yaml
paths:
  data:
    raw: "/path/to/your/data.csv"
    processed_clean: "/path/to/your/processed_data.csv"
    step1_original: "/path/to/your/original_data.csv"
```

## Step 4: Run Pipeline

```bash
# Run everything
snakemake -j 4

# Or run specific steps
snakemake -j 4 all_step1      # Step 1 only
snakemake -j 4 all_step2      # Step 2 only
```

## Step 5: Check Results

```bash
# Results are in:
ls results/

# Key outputs:
# - results/step2/final/figures/step2_position_specific_distribution.png
# - results/step2/final/tables/statistical_results/S2_statistical_comparisons.csv
```

## Need Help?

- **Full documentation:** [README.md](README.md)
- **User guide:** [docs/USER_GUIDE.md](docs/USER_GUIDE.md)
- **Pipeline overview:** [docs/PIPELINE_OVERVIEW.md](docs/PIPELINE_OVERVIEW.md)

---

**That's it!** Your pipeline should now be running. Check the logs in `results/*/logs/` if you encounter any issues.

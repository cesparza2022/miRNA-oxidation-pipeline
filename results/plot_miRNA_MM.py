#!/usr/bin/env python3
import os
import argparse
import sys
import pandas as pd
import matplotlib
matplotlib.use('Agg')  # Use a non-interactive backend
import matplotlib.pyplot as plt
import seaborn as sns

def load_fasta(fasta_file):
    """
    Loads a FASTA file and returns a dictionary:
    {
       "mmu-let-7g-5p": "TGAGGTAGTAGTTTGTACAGTT",
       "mmu-let-7g-3p": "ACTGTACAGGCCACTGCCTTGC",
       ...
    }
    """
    miRNA_ref = {}
    current_name = None
    current_seq = []

    with open(fasta_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            if line.startswith(">"):
                # Save the previous miRNA if available
                if current_name and current_seq:
                    miRNA_ref[current_name] = "".join(current_seq)
                
                # Extract the main identifier; e.g.:
                # ">mmu-let-7g-5p MIMAT0000121 Mus musculus let-7g-5p"
                header = line[1:].split()  # remove ">" and split
                current_name = header[0]
                current_seq = []
            else:
                current_seq.append(line)
        
        if current_name and current_seq:
            miRNA_ref[current_name] = "".join(current_seq)
    
    return miRNA_ref


def parse_miRNA_counts(counts_file):
    """
    Parses the miRNA_count.Q38.txt file and returns:
    {
      "mmu-let-7a-2-3p": [
         # Each line: (positions_mut, count, total)
         # where positions_mut is the string "3:GA,7:AG" or "PM", etc.
         ("PM", 5, 9),
         ("3:GA,7:AG", 2, 9),
         ("8:GA,12:CT", 2, 9),
         ...
      ],
      ...
    }
    """
    data = {}

    with open(counts_file, 'r') as f:
        header = next(f).strip()  # Skip header
        for line in f:
            line = line.strip()
            if not line:
                continue
            cols = line.split()
            miRNA_name = cols[0]
            pos_mut    = cols[1]  # e.g. "PM" or "3:GA,7:AG"
            count      = int(cols[2])  # second-to-last column
            total      = int(cols[3])  # last column

            if miRNA_name not in data:
                data[miRNA_name] = []
            
            data[miRNA_name].append((pos_mut, count, total))
    
    return data


def build_mismatch_table(miRNA_ref, counts_data):
    """
    Builds a structure that, for each miRNA, contains a dict with:
       mismatch_counts[miRNA][pos][observed_base] = sum of reads (count)
    and also:
       mismatch_counts[miRNA]["total_reads"] = total mapped reads for that miRNA
    (as given by the last column).
    
    NOTE: We assume that the 'total' value is the same for every record of a given miRNA.
    """
    mismatch_counts = {}

    for miRNA_name, records in counts_data.items():
        ref_seq = miRNA_ref.get(miRNA_name, None)

        mismatch_counts[miRNA_name] = {}
        mismatch_counts[miRNA_name]["total_reads"] = 0

        if not records:
            continue
        
        representative_total = records[0][2]
        mismatch_counts[miRNA_name]["total_reads"] = representative_total

        for (pos_mut, count, total) in records:
            if total != representative_total:
                # Optionally, print a warning if totals differ
                pass

            # Skip perfect matches ("PM")
            if pos_mut == "PM":
                continue
            
            # pos_mut may be "3:GA,7:AG" -> split by commas
            events = pos_mut.split(",")

            for ev in events:
                # ev = "3:GA" => pos = 3, mut = "GA"
                pos_str, mut = ev.split(":")
                pos = int(pos_str)
                # Assume mut[0] = canonical, mut[1] = observed
                obs_base = mut[1]

                if pos not in mismatch_counts[miRNA_name]:
                    mismatch_counts[miRNA_name][pos] = {}
                
                if obs_base not in mismatch_counts[miRNA_name][pos]:
                    mismatch_counts[miRNA_name][pos][obs_base] = 0

                mismatch_counts[miRNA_name][pos][obs_base] += count
    
    return mismatch_counts

def main():
    parser = argparse.ArgumentParser(
        description="Generate mismatch distribution data by position for a specified miRNA."
    )
    parser.add_argument("--fasta", required=True,
                        help="Path to the FASTA file with reference miRNA sequences.")
    parser.add_argument("--counts", required=True,
                        help="Path to the miRNA_count.Q38.txt file with mismatch counts.")
    parser.add_argument("--mirna", required=True,
                        help="Name of the miRNA to process (e.g., mmu-let-7a-5p).")
    parser.add_argument('-o', '--output', type=str, default='.', help='Output directory for the plot')
    args = parser.parse_args()

    # 1) Load canonical miRNA sequences
    miRNA_ref = load_fasta(args.fasta)

    # 2) Parse the counts file
    counts_data = parse_miRNA_counts(args.counts)

    # 3) Build the mismatch table
    mismatch_table = build_mismatch_table(miRNA_ref, counts_data)

    if args.mirna not in mismatch_table:
        print(f"Error: miRNA '{args.mirna}' not found in the data.", file=sys.stderr)
        sys.exit(1)

    info = mismatch_table[args.mirna]
    total_reads = info["total_reads"]
    print(f"{args.mirna}\tTotal reads: {total_reads}")
    for pos in sorted([key for key in info.keys() if isinstance(key, int)]):
        mismatches = info[pos]
        for obs_base, c in mismatches.items():
            print(f"  Pos {pos} {obs_base}: {c} reads")

    # Build data for plotting
    rows = []
    for pos in sorted([key for key in info.keys() if isinstance(key, int)]):
        for obs_base, count in info[pos].items():
            freq_pct = (count / total_reads) * 100
            rows.append({
                "position": pos,
                "observed_base": obs_base,
                "count": count,
                "freq_pct": freq_pct
            })

    df = pd.DataFrame(rows)

    # Retrieve the canonical sequence for the specified miRNA
    canonical_seq = miRNA_ref[args.mirna]

    # Define a custom palette: only color 'T' in red; others in gray.
    custom_palette = {"T": "red", "A": "gray", "C": "gray", "G": "gray"}

    plt.figure(figsize=(10, 5))
    # Plot using the numeric position as x for separation
    sns.barplot(
        data=df,
        x="position",
        y="freq_pct",
        hue="observed_base",
        palette=custom_palette
    )
    plt.title(f"Mismatch Distribution for {args.mirna}")
    plt.ylabel("Mismatch Percentage (%)")
    plt.xlabel("Canonical Base")
    plt.legend(title="Observed Base")

    # Replace x-axis ticks: for each numeric position, label with its canonical base.
    unique_positions = sorted(df["position"].unique())
    tick_labels = [canonical_seq[pos] for pos in unique_positions]
    plt.xticks(unique_positions, tick_labels)

    plt.tight_layout()
    # Save the figure with the miRNA name in the filename.
    output_path = os.path.join(args.output, f"{args.mirna}_mismatch_distribution.png")
    os.makedirs(args.output, exist_ok=True)
    plt.savefig(output_path)
    plt.close()

if __name__ == "__main__":
    main()

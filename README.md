# 🧬 OmicVerse: A Cross-Platform Interactive Bioinformatics Research Suite

[![Deploy to GitHub Pages](https://github.com/rafi28-png/omicverse/actions/workflows/deploy.yml/badge.svg)](https://github.com/rafi28-png/omicverse/actions/workflows/deploy.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-teal.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Platform-Flutter%20%7C%20Web%20%7C%20Desktop%20%7C%20Mobile-blue.svg)](https://flutter.dev)

OmicVerse is a free, open-source, and cross-platform interactive bioinformatics desktop, web, and mobile application designed to streamline multi-omics research. By integrating data across 17 specialized research modules—ranging from genomics and epigenomics to drug interactions and real-time collaboration—OmicVerse enables researchers to analyze, visualize, and share complex molecular data without command-line bottlenecks.

Developed with Flutter and Dart, the application offers a hardware-accelerated, responsive dark-mode user interface designed for both low-latency performance and high-contrast accessibility (WCAG AA compliant).

---

## 🌟 Key Features & Modules

OmicVerse bridges the gap between raw genomic data files and interactive cloud visualizations across **17 integrated research areas**:

1. **Genome Browser**: Search and inspect gene structures, transcript biotypes, and locations via live Ensembl lookup.
2. **Variant Analysis**: Parse raw VCF files directly in the browser using multi-threaded web isolates, and automatically annotate mutations using **gnomAD** (allele frequencies) and **Ensembl VEP** (consequences).
3. **Expression Analysis**: Analyze RNA-seq differential expression data and render high-performance interactive **Volcano Plots** via `fl_chart`.
4. **Pathway Enrichment**: Map genes to biological pathways using **KEGG** pathways and **STRING** protein-protein interaction networks.
5. **Protein Explorer**: Query UniProt IDs and view 3D molecular structures predicted by **AlphaFold** with clickable links to interactive model viewers.
6. **Regulatory Elements**: Inspect cis-Regulatory Elements (cCREs), enhancers, and transcription factor (TF) binding sites from ENCODE.
7. **Population Genetics**: Evaluate global and sub-population allele frequencies (AF) to understand variant distributions.
8. **Polygenic Risk Scores (PRS)**: Explore polygenic trait scores, coverage percentages, and percentile rankings across human phenotypes.
9. **Epigenetics (Methylation)**: Calculate biological ages using the Horvath epigenetic clock, utilizing local matrix math libraries.
10. **CRISPR gRNA Design**: Compute GC-content, target efficiency, and off-target risks to design optimal guide RNA sequences.
11. **Cancer Genomics**: Plot mutation hotspots, somatic frequencies, and cancer type distributions using live **cBioPortal / TCGA** datasets.
12. **Evolutionary Conservation**: Evaluate phyloP/phastCons conservation scores across mammalian species.
13. **Alternative Splicing**: Profile alternative splicing events (ASEs) and Percent Spliced In (PSI) indices.
14. **Pharmacogenomics (Drug)**: Search drug-gene interactions and actionable clinical guidelines.
15. **3D Genomes (Chromatin)**: Explore topologically associating domains (TADs) and chromatin loops (Hi-C).
16. **Multi-Omics Integration**: Aggregate multi-layered datasets to compile a unified, multi-omics gene profile.
17. **Real-time Collaboration**: Start live, synchronized collaborative sessions with other researchers to draw, point, and write notes on shared genomic workspaces.

---

## 🚀 Getting Started

### Online Demo
You can access the live web application immediately without installation:
👉 **[https://rafi28-png.github.io/omicverse/](https://rafi28-png.github.io/omicverse/)**

* **Demo Mode**: The application defaults to Demo Mode, allowing you to click around and explore features using pre-loaded mock datasets immediately.
* **Live API Mode**: Open **Settings** (⚙️ top right) and toggle **Demo Mode to OFF** to connect the application directly to live public bioinformatics servers.
* **Sample Loaders**: In the **Variant** and **Expression** modules, click **"Load Sample"** to parse and analyze real-world genomic datasets instantly.

---

## 🛠️ Local Development & Installation

### Prerequisites
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (stable channel, version 3.22.x or higher)
* [Dart SDK](https://dart.dev/get-dart) (bundled with Flutter)
* Chrome or another modern web browser (for web testing)

### Step 1: Clone the Repository
```bash
git clone https://github.com/rafi28-png/omicverse.git
cd omicverse/app
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Run the Application Locally
```bash
flutter run -d chrome
```

---

## 🗄️ Setting Up Your Supabase Cloud Database

To enable user sign-ins, project saving, and real-time collaboration, you can connect your own Supabase instance:

1. **Create a Project**: Set up a free project on **[Supabase](https://supabase.com)**.
2. **Execute Schema Migrations**:
   * Open the **SQL Editor** in your Supabase dashboard.
   * Click **New Query**, copy the entire contents of [combined_setup.sql](file:///E:/omicverse/app/supabase/combined_setup.sql), and click **Run**.
3. **Configure Environment Variables**:
   * Local development: Create an `app/.env` file with `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
   * Production Web (GitHub Actions): Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` under your GitHub Repository's **Settings -> Secrets and variables -> Actions**.
4. **Enable Realtime**:
   * In your Supabase dashboard, navigate to **Database -> Replication**.
   * Edit the replication source for `supabase_realtime` and toggle **ON** `collaboration_sessions`, `session_participants`, and `session_annotations`.

---

## 🧪 Testing

OmicVerse features a robust, self-contained test suite consisting of **189 unit and widget tests** covering contrast ratio metrics, VCF/CSV parsers, genetics algorithms, and UI transitions.

Run the test suite locally with:
```bash
flutter test
```

To run the static analyzer and check for formatting/lint warnings:
```bash
flutter analyze
```

---

## 📝 Attributions & Citations

OmicVerse accesses public research infrastructure. We express our gratitude to the maintainers of:
* **Ensembl**: [rest.ensembl.org](https://rest.ensembl.org)
* **AlphaFold**: [alphafold.ebi.ac.uk](https://alphafold.ebi.ac.uk)
* **STRING**: [string-db.org](https://string-db.org)
* **KEGG**: [kegg.jp](https://www.kegg.jp) (Kanehisa Laboratories; non-commercial academic use)
* **gnomAD**: [gnomad.broadinstitute.org](https://gnomad.broadinstitute.org)
* **NCBI dbSNP & ClinVar**: [ncbi.nlm.nih.gov](https://www.ncbi.nlm.nih.gov)

---

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

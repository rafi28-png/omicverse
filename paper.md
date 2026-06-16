---
title: 'OmicVerse: A Browser-Based Multi-Omics Research Platform for Accessible Bioinformatics'
tags:
  - bioinformatics
  - multi-omics
  - genomics
  - proteomics
  - web application
  - Flutter
  - variant analysis
  - gene expression
  - pathway analysis
authors:
  - name: Md Rafiur Rahman
    orcid: 0000-0000-0000-0000
    affiliation: 1
affiliations:
  - name: Department of Biochemistry and Biotechnology, North South University, Dhaka, Bangladesh
    index: 1
date: 16 June 2025
bibliography: paper.bib
---

# Summary

OmicVerse is a free, open-source, browser-based multi-omics research platform
that unifies access to 16 bioinformatics analysis modules through a single
web interface. It integrates data from major public databases — including
Ensembl, UniProt, KEGG, gnomAD, ChEMBL, STRING-DB, AlphaFold, and others —
enabling researchers to explore genes, variants, proteins, pathways, drug
interactions, and more without installing any software or writing code.

Built with Flutter for cross-platform web deployment, OmicVerse provides
real-time queries to public REST APIs with automatic fallback to bundled
demonstration data when network access is unavailable. The platform features
client-side file parsing for differential expression (CSV/TSV) and variant
call format (VCF) files, ensuring that sensitive genomic data never leaves
the user's browser.

# Statement of Need

Modern biological research increasingly relies on integrating data across
multiple omics layers — genomics, transcriptomics, proteomics, and
metabolomics. However, accessing and interpreting this data typically requires
navigating dozens of separate web databases, each with different interfaces,
query formats, and output structures. This fragmented landscape creates
significant barriers for:

- **Undergraduate and early-career researchers** who lack bioinformatics
  training but need to explore multi-omics data for coursework and projects
- **Wet-lab biologists** who want quick lookups of gene function, variant
  pathogenicity, or drug interactions without learning command-line tools
- **Resource-limited institutions** where installing and maintaining
  bioinformatics software is impractical

Existing solutions fall into two categories: (1) comprehensive but complex
platforms like Galaxy [@afgan2018galaxy] that require server infrastructure
and bioinformatics expertise, and (2) single-purpose web tools like the
Ensembl Genome Browser [@cunningham2022ensembl] or UniProt [@uniprot2023]
that each cover one data type. OmicVerse fills the gap between these by
providing a unified, zero-installation interface that queries multiple
databases from a single search.

# Architecture and Features

## Modules

OmicVerse provides 16 analysis modules organized by omics layer:

| Module | Data Source | Functionality |
|--------|-----------|---------------|
| Gene Expression | Client-side CSV/TSV parsing | Differential expression analysis with volcano plots |
| Variant Analysis | gnomAD, Ensembl VEP | VCF parsing, variant annotation, allele frequencies |
| Protein Explorer | UniProt, AlphaFold | Protein search, function, domains, structure confidence |
| Pathway Analysis | KEGG, STRING-DB | Pathway lookup, gene-pathway mapping, interactions |
| Drug Interactions | ChEMBL | Drug-gene interaction search by target or compound |
| Regulatory Elements | ENCODE, JASPAR | cis-regulatory elements, transcription factor binding |
| Population Genetics | gnomAD | Population-specific allele frequencies |
| Polygenic Risk Scores | PGS Catalog | Polygenic score lookup and interpretation |
| DNA Methylation | Horvath clock model | CpG site analysis, biological age estimation |
| CRISPR Guide Design | In-browser algorithm | Guide RNA design with GC content and off-target scoring |
| Cancer Genomics | GDC, cBioPortal | Somatic mutation lookup, cancer study exploration |
| Evolutionary Conservation | UCSC, Ensembl | Ortholog comparison, conservation scoring |
| Alternative Splicing | SpliceAI | Splicing event analysis, isoform exploration |
| 3D Genome | 4D Nucleome | TAD boundaries, chromatin loop visualization |
| Multi-Omics Integration | All sources | Unified gene profile across all omics layers |
| Collaboration | Supabase | Team project sharing (authenticated mode) |

## Technical Design

OmicVerse is built with the following design principles:

1. **Zero installation**: Runs entirely in the browser via Flutter Web with
   CanvasKit rendering. No plugins, extensions, or downloads required.

2. **Privacy-first**: File parsing (VCF, CSV/TSV) occurs entirely client-side
   using Dart. Genomic data never leaves the user's machine.

3. **Graceful degradation**: Each API call includes retry logic with
   exponential backoff, rate limiting, and automatic fallback to bundled
   demonstration data when external services are unavailable.

4. **Responsive design**: The interface adapts to desktop, tablet, and mobile
   screen sizes using a custom dark-themed design system.

## API Integration

OmicVerse queries 15+ public bioinformatics REST APIs in real-time:

- **Ensembl REST** and **VEP** for gene lookup and variant effect prediction
- **UniProt** for protein function and domain annotation
- **AlphaFold** for predicted structure confidence (pLDDT scores)
- **KEGG** for metabolic and signaling pathway data
- **STRING-DB** for protein-protein interaction networks
- **gnomAD** (GraphQL) for population allele frequencies
- **ChEMBL** for bioactive compound and drug data
- **GDC** and **cBioPortal** for cancer genomics
- **JASPAR** and **ENCODE** for regulatory element data

All APIs are public and require no authentication keys.

# Testing

OmicVerse includes 196 automated unit tests covering all data models,
service classes, and parsing logic. Tests are executed on every commit via
GitHub Actions continuous integration. The test suite verifies:

- Data model validity and serialization
- File parsing accuracy (VCF, CSV/TSV)
- Service method correctness
- Demo data consistency

# Availability

OmicVerse is freely available at
[https://rafi28-png.github.io/omicverse/](https://rafi28-png.github.io/omicverse/)
and the source code is hosted on GitHub under the MIT license at
[https://github.com/rafi28-png/omicverse](https://github.com/rafi28-png/omicverse).

# References

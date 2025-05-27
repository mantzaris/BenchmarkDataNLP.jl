# BenchmarkDataNLP.jl

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE) 
[![DOI](https://joss.theoj.org/papers/10.21105/joss.07844/status.svg)](https://doi.org/10.21105/joss.07844)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://mantzaris.github.io/BenchmarkDataNLP.jl/) 
[![Build Status](https://github.com/mantzaris/BenchmarkDataNLP.jl/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/mantzaris/BenchmarkDataNLP.jl/actions)

## Overview

BenchmarkDataNLP.jl is a Julia project (can be easily used from other languages by calling Julia) that generates synthetic text datasets for natural language processing (NLP) experimentation (characters selected from the Korean Language Unicode block, Hangul). The primary goal is to allow researchers and developers to produce language-like corpora of varying sizes and complexities, without immediately investing in large-scale real-world data collection or computationally expensive training runs.
This toolbox provides multiple generation algorithms—Context-Free Grammars (CFG), RDF/Triple-store-based corpora, Finite State Machine (FSM) expansions, and Template-based text generation—each supporting a complexity parameter. You can quickly obtain controlled, structured text for model prototyping, or debugging.

## Some Features

- Tunable Complexity: A complexity parameter (often 1–100 or up to 1000) influences: Vocabulary size, Grammar roles/expansions, Probability of terminal tokens, Number of subjects/predicates/objects (in RDF) and more.
- Deterministic or Random Generation: Some methods (e.g., deterministic CFG expansions, round-robin adjacency walks) produce fully reproducible text where 100% accuracy is achievable, other modes (e.g., random adjacency in FSM, polysemy in CFG) inject randomness for more varied outputs.
- Multiple approaches:
    - CFG: Creates random context-free grammars, expansions, and sentences
    - RDF: Builds a triple-store from subject/predicate/object sets and turns them into text lines or paragraphs
    - FSM: Generates text by stepping a finite state machine adjacency state set
    - Template-based (TPS): Fills placeholders in skeleton templates with a partitioned vocabulary

JSON Lines Output by default, each module writes .jsonl files, split into train, test, and validation sets (80% / 10% / 10%).

## Quick Start Example

### Installation

1. open the Julia REPL, get into package mode pressing `]` and put: `add https://github.com/mantzaris/BenchmarkDataNLP.jl`, and after installation get out of package mode (backspace) and type `using BenchmarkDataNLP`
2. for development, clone the repo `git clone https://github.com/mantzaris/BenchmarkDataNLP.jl`, move into the repo directory `cd BenchmarkDataNLP.jl`, open the Julia REPL press `]`, `dev .`, exit the package mode and `using BenchmarkDataNLP.jl`

```julia
using BenchmarkDataNLP

# generate a dataset using Context Free Grammar, at complexity 20, 1000 sentences (800 lines in training, 100 testing, 100 validation) at the path you choose the files to be generated, eg. "/home/user/Documents"
generate_corpus_CFG(complexity = 20, num_sentences = 1_000, enable_polysemy = false, output_dir = "/home/user/Documents", base_filename = "MyDataset")

#generate using a Finite State Machine based approach
generate_fsm_corpus(20, 1_000; output_dir="/home/user/Documents", base_name="MyFSM", use_context=true, random_adjacency=true, max_length=12)

#generate using an RDF based approach
generate_rdf_corpus( 20, 1_000; output_dir = "/home/user/Documents", base_name = "MyRDF", filler_ratio = 0.2, max_filler = 2, use_context = true)

#generate using a Template Strings approach
generate_tps_corpus( 20, 1_000; output_dir = "/home/user/Documents", base_name = "TemplatedTest", n_templates = 5, max_placeholders_in_template = 4, deterministic = false)
```

Entries in the .jsonl files produced will look like:

```
{"text":"갃갇갊 갆 갇 갆 갃가갇."}
```

Where the characters are in the Hangul region of unicode.

# Referencing

Citing this work:

```
@article{Mantzaris2025, doi = {10.21105/joss.07844}, url = {https://doi.org/10.21105/joss.07844}, year = {2025}, publisher = {The Open Journal}, volume = {10}, number = {109}, pages = {7844}, author = {Alexander V. Mantzaris}, title = {BenchmarkDataNLP.jl: Synthetic Data Generation for NLP Benchmarking}, journal = {Journal of Open Source Software} } 
```
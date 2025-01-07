# BenchmarkDataNLP.jl

```@contents

```

## Introduction

`BenchmarkDataNLP.jl` is designed to assist users in generating text corpus datasets with parameterized complexity. By utilizing methods such as context-free grammars and Chomsky trees, this package enables the creation of datasets tailored for training natural language processing (NLP) models, including large language models (LLMs). The primary objective is to offer a controlled environment where the complexity of the datasets can be adjusted, facilitating efficient training and evaluation of NLP methods within manageable timeframes and computational resources. Output is .jsonl format producing a training, testing and validation.

The vocabulary is synthetic and sampled as is are the grammar rules and word roles/subroles.

## Complexity 100 Configuration

At **complexity = 100**, `BenchmarkDataNLP.jl` uses the following default parameters:

- **Vocabulary**: 10,000 words
- **Grammar Rules**: 200 total
- **Character Set**: 50 letters (characters)
- **Punctuation**: 10 characters
- **Maximum Word Length**: 20 characters
- **Major Roles**: 10
- **Polysemy**:
  - Controlled by a boolean flag `enable_polysemy`
  - If true, a certain percentage of the vocabulary is allowed to appear in multiple roles.
- **Linear Complexity Scaling**:
  - From `complexity = 1` up to `complexity = 100` (and beyond if desired), the above values scale proportionally allowed up to `complexity = 1000` scaling linearly
  - For instance, at lower complexity, you have fewer total words, fewer grammar rules, and shorter maximum word lengths.
  - As complexity increases, the vocabulary, grammar rules, and role/subrole definitions expand, offering progressively more intricate linguistic structures.
  - Up to complexity 100 the grammar expansions are more close to resembling normal language (human) constructs producing text that is mostly linguistic. From 101 onward, the expansions are more random to capture arbitrary symbolic or code-like patterns.

This linear scaling ensures that users can move from extremely simple, minimal text corpora up to rich, varied corpora without modifying multiple parameters manually. For example, you might begin at `complexity = 1` with very few words and minimal grammatical structures, then gradually progress toward `complexity = 100` (and higher) to produce more challenging datasets that test the limits of NLP architectures (up to `complexity = 200` is supported and although not clamped larger values may produce saturated data but a hard limit is only put at 1,000).

usage:

```
generate_corpus_CFG(
    complexity       = 100,           # Controls grammar, vocab size, etc.
    num_sentences    = 100_000,       # Number of text samples (lines) to generate for each file of training/testing/validation
    enable_polysemy  = false,         # Toggle overlap of words among multiple roles
    base_filename    = "MyDataset",   # Base name for output files of .jsonl format
    )
```

## Functions

```@autodocs
Modules = [BenchmarkDataNLP]
Private = false
Order = [:function]
```

# BenchmarkNLP.jl

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Build Status](https://github.com/mantzaris/BenchmarkNLP.jl/workflows/CI/badge.svg)](https://github.com/mantzaris/BenchmarkNLP.jl/actions)

## Overview

**BenchmarkNLP.jl** is an open-source Julia package designed to generate synthetic language corpora with controllable complexity. It provides tools for creating datasets that can be used to benchmark large language models (LLMs) on tasks with known expected outcomes. By offering a suite of generators based on different grammatical frameworks, BenchmarkNLP.jl enables researchers to evaluate and compare the capabilities of LLMs against datasets where 100% accuracy is achievable. The ability to regulate the complexity of the language associations can help in rapid prototyping so that new ideas can be experimented on and tested in fast development cycles with lower cost from failures. 

## Some Features

- **Context-Free Grammar (CFG) Generator**: Create syntactically valid sentences using customizable CFGs.
- **Dependency Grammar Generator**: Generate sentences based on dependency relations between words.
- **Probabilistic Context-Free Grammar (PCFG) Generator**: Introduce statistical variation by assigning probabilities to grammar rules.
- **Adjustable Complexity**: Control the syntactic and statistical complexity of generated text through parameters.
- **Dataset Partitioning**: Automatically split generated data into training, testing, and validation sets.
- **Extensible Architecture**: Modular design allows for easy addition of new grammatical frameworks and generators.

## Installation

BenchmarkNLP.jl is compatible with Julia 1.6 and above. 

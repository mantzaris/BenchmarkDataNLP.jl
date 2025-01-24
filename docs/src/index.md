# BenchmarkDataNLP.jl

```@contents

```

# Introduction

BenchmarkDataNLP.jl is a Julia package designed to generate synthetic text corpora with adjustable complexity, facilitating the benchmarking and evaluation of Natural Language Processing (NLP) models, including Large Language Models (LLMs). By providing a controlled environment, researchers can systematically assess model performance across varying linguistic structures and complexities.

## Purpose and Approach

The primary goal of BenchmarkDataNLP.jl is to offer a suite of methods for creating synthetic datasets that mimic various linguistic patterns. These datasets are instrumental in:

  - Model Evaluation: Assessing how NLP models handle different levels of language complexity.
  - Controlled Testing: Providing datasets with known properties to isolate and test specific model behaviors.
  - Resource Efficiency: Generating datasets that allow for efficient training and evaluation within manageable timeframes and computational resources.

The package employs several methods to generate text, each offering a unique approach to dataset creation:

  - Context-Free Grammars (CFGs): Utilizes CFGs to produce sentences based on predefined grammatical rules, allowing for the generation of structured and hierarchical language constructs.
  - Resource Description Framework (RDF) Templates: Incorporates RDF templates to structure data, facilitating the generation of text that aligns with specific semantic frameworks. This approach ensures that the generated text adheres to predefined data schemas, enhancing consistency and relevance.
  - Templates: Employs predefined templates to guide text generation, ensuring that the output follows specific structural patterns. This method allows for the creation of text with consistent formatting and organization, which is particularly useful for generating repetitive or formulaic content.
  - Finite State Machines (FSMs): Implements FSMs to model the generation process as a series of states and transitions, enabling the production of text sequences that follow specific state-dependent rules. This approach is effective in capturing sequential dependencies and ensuring that the generated text adheres to desired patterns.

Adjustable Complexity

A key feature of BenchmarkDataNLP.jl is its ability to parameterize the complexity of the generated text. Users can control various parameters, including:

  - Vocabulary Size: The number of unique words in the dataset.
  - Grammar Rules: The number and complexity of rules used to generate sentences.
  - Sentence Length: The maximum length of generated sentences.
  - Polysemy: The degree to which words have multiple meanings or roles.

By adjusting these parameters, users can create datasets ranging from simple, predictable structures to complex, more complex language patterns with elements of randomness or no randomness.

## Output Format and File Structure

The generated datasets are output in the .jsonl (JSON Lines) format, which is efficient for storing large collections of JSON objects. Each line in the file represents a single data point, facilitating easy parsing and processing.
Upon generation, the package produces three separate files corresponding to standard machine learning dataset partitions:

  - Training Set: Comprising 80% of the data, used for model training.
  - Validation Set: Comprising 10% of the data, used for tuning model parameters.
  - Test Set: Comprising 10% of the data, used for evaluating model performance.

These files are named based on the user-defined base filename and are saved in the specified output directory.

### Usage Example

To generate a dataset with a complexity level of 100, consisting of 100,000 sentences for each of the training, validation, and test sets, you can use the following function call:

generate_corpus_CFG(
    complexity       = 100,           # Controls grammar, vocab size, etc.
    num_sentences    = 100_000,       # Number of text samples (lines) to generate for each file
    enable_polysemy  = false,         # Toggle overlap of words among multiple roles
    output_dir       = "/home/user/Documents", # Output path for the files
    base_filename    = "MyDataset",   # Base name for output files
)

This function will create three files in the specified directory: MyDataset_train.jsonl, MyDataset_valid.jsonl, and MyDataset_test.jsonl, containing the generated text samples partitioned accordingly.

By leveraging BenchmarkDataNLP.jl, researchers and practitioners can efficiently create tailored datasets to rigorously evaluate and benchmark NLP models across a spectrum of linguistic complexities.

## Functions

```@autodocs
Modules = [BenchmarkDataNLP]
Private = false
Order = [:function]
```

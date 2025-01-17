var documenterSearchIndex = {"docs":
[{"location":"#BenchmarkDataNLP.jl","page":"Home","title":"BenchmarkDataNLP.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"#Introduction","page":"Home","title":"Introduction","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"BenchmarkDataNLP.jl is designed to assist users in generating text corpus datasets with parameterized complexity. By utilizing methods such as context-free grammars and Chomsky trees, this package enables the creation of datasets tailored for training natural language processing (NLP) models, including large language models (LLMs). The primary objective is to offer a controlled environment where the complexity of the datasets can be adjusted, facilitating efficient training and evaluation of NLP methods within manageable timeframes and computational resources. Output is .jsonl format producing a training, testing and validation.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The vocabulary is synthetic and sampled as is are the grammar rules and word roles/subroles.","category":"page"},{"location":"#Complexity-100-Configuration","page":"Home","title":"Complexity 100 Configuration","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"At complexity = 100, BenchmarkDataNLP.jl uses the following default parameters:","category":"page"},{"location":"","page":"Home","title":"Home","text":"Vocabulary: 10,000 words\nGrammar Rules: 200 total\nCharacter Set: 50 letters (characters)\nPunctuation: 10 characters\nMaximum Word Length: 20 characters\nMajor Roles: 50\nPolysemy:\nControlled by a boolean flag enable_polysemy\nIf true, a certain percentage of the vocabulary is allowed to appear in multiple roles.\nLinear Complexity Scaling:\nFrom complexity = 1 up to complexity = 100 (and beyond if desired), the above values scale proportionally allowed up to complexity = 1000 scaling linearly\nFor instance, at lower complexity, you have fewer total words, fewer grammar rules, and shorter maximum word lengths.\nAs complexity increases, the vocabulary, grammar rules, and role/subrole definitions expand, offering progressively more intricate linguistic structures.\nUp to complexity 100 the grammar expansions are more close to resembling normal language (human) constructs producing text that is mostly linguistic. From 101 onward, the expansions are more random to capture arbitrary symbolic or code-like patterns.","category":"page"},{"location":"","page":"Home","title":"Home","text":"This linear scaling ensures that users can move from extremely simple, minimal text corpora up to rich, varied corpora without modifying multiple parameters manually. For example, you might begin at complexity = 1 with very few words and minimal grammatical structures, then gradually progress toward complexity = 100 (and higher) to produce more challenging datasets that test the limits of NLP architectures (up to complexity = 200 is supported and although not clamped larger values may produce saturated data but a hard limit is only put at 1,000).","category":"page"},{"location":"","page":"Home","title":"Home","text":"usage:","category":"page"},{"location":"","page":"Home","title":"Home","text":"generate_corpus_CFG(\n    complexity       = 100,           # Controls grammar, vocab size, etc.\n    num_sentences    = 100_000,       # Number of text samples (lines) to generate for each file of training/testing/validation\n    enable_polysemy  = false,         # Toggle overlap of words among multiple roles\n    base_filename    = \"MyDataset\",   # Base name for output files of .jsonl format (training/testing/validation files of 80%/10%/10% are produced)\n    )","category":"page"},{"location":"#Functions","page":"Home","title":"Functions","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Modules = [BenchmarkDataNLP]\nPrivate = false\nOrder = [:function]","category":"page"},{"location":"#BenchmarkDataNLP.generate_corpus_CFG-Tuple{}","page":"Home","title":"BenchmarkDataNLP.generate_corpus_CFG","text":"generatecorpusCFG(;      complexity::Int = 100,      numsentences::Int = 100000,      enablepolysemy::Bool = false,      basefilename::AbstractString = \"MyDataset\" )\n\nGenerate a synthetic corpus of context-free grammar–based text data.\n\nArguments\n\ncomplexity: Controls the grammar complexity, vocabulary size, and other parameters \n\n(e.g., at complexity=100 you might have a 10K-word vocabulary, 200 grammar rules, etc.). After 100 the grammar expansions are less typical of human languages.\n\nnum_sentences: The total number of text samples (e.g., lines or sentences) to generate.\nenable_polysemy: If true, allows words to overlap multiple roles or subroles, introducing \n\nlexical ambiguity in the generated corpus.\n\nbase_filename: Base name for the output files; the function will typically create files \n\nlike base_filename_training.jsonl, base_filename_validation.jsonl, and  base_filename_test.jsonl depending on how you implement data splitting.\n\nUsage\n\n```julia\n\nExample usage:\n\ngeneratecorpusCFG(     complexity       = 100,     numsentences    = 100000,     enablepolysemy  = false,     basefilename    = \"MyDataset\" )\n\n\n\n\n\n","category":"method"},{"location":"#BenchmarkDataNLP.greet-Tuple{}","page":"Home","title":"BenchmarkDataNLP.greet","text":"greet()\n\nPrints a friendly greeting message to the console.\n\nReturns nothing\n\n\n\n\n\n","category":"method"}]
}

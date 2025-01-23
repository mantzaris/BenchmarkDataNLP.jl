var documenterSearchIndex = {"docs":
[{"location":"#BenchmarkDataNLP.jl","page":"Home","title":"BenchmarkDataNLP.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"#Introduction","page":"Home","title":"Introduction","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"BenchmarkDataNLP.jl is designed to assist users in generating text corpus datasets with parameterized complexity. By utilizing methods such as context-free grammars and Chomsky trees, this package enables the creation of datasets tailored for training natural language processing (NLP) models, including large language models (LLMs). The primary objective is to offer a controlled environment where the complexity of the datasets can be adjusted, facilitating efficient training and evaluation of NLP methods within manageable timeframes and computational resources. Output is .jsonl format producing a training, testing and validation.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The vocabulary is synthetic and sampled as is are the grammar rules and word roles/subroles.","category":"page"},{"location":"#Complexity-100-Configuration","page":"Home","title":"Complexity 100 Configuration","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"At complexity = 100, BenchmarkDataNLP.jl uses the following default parameters:","category":"page"},{"location":"","page":"Home","title":"Home","text":"Vocabulary: 10,000 words\nGrammar Rules: 200 total\nCharacter Set: 50 letters (characters)\nPunctuation: 10 characters\nMaximum Word Length: 20 characters\nMajor Roles: 50\nPolysemy:\nControlled by a boolean flag enable_polysemy\nIf true, a certain percentage of the vocabulary is allowed to appear in multiple roles.\nLinear Complexity Scaling:\nFrom complexity = 1 up to complexity = 100 (and beyond if desired), the above values scale proportionally allowed up to complexity = 1000 scaling linearly\nFor instance, at lower complexity, you have fewer total words, fewer grammar rules, and shorter maximum word lengths.\nAs complexity increases, the vocabulary, grammar rules, and role/subrole definitions expand, offering progressively more intricate linguistic structures.\nUp to complexity 100 the grammar expansions are more close to resembling normal language (human) constructs producing text that is mostly linguistic. From 101 onward, the expansions are more random to capture arbitrary symbolic or code-like patterns.","category":"page"},{"location":"","page":"Home","title":"Home","text":"This linear scaling ensures that users can move from extremely simple, minimal text corpora up to rich, varied corpora without modifying multiple parameters manually. For example, you might begin at complexity = 1 with very few words and minimal grammatical structures, then gradually progress toward complexity = 100 (and higher) to produce more challenging datasets that test the limits of NLP architectures (up to complexity = 200 is supported and although not clamped larger values may produce saturated data but a hard limit is only put at 1,000).","category":"page"},{"location":"","page":"Home","title":"Home","text":"usage:","category":"page"},{"location":"","page":"Home","title":"Home","text":"generate_corpus_CFG(\n    complexity       = 100,           # Controls grammar, vocab size, etc.\n    num_sentences    = 100_000,       # Number of text samples (lines) to generate for each file of training/testing/validation\n    enable_polysemy  = false,         # Toggle overlap of words among multiple roles\n    output_dir       = \"/home/user/Documents\" # Output path for the files to be saved to\n    base_filename    = \"MyDataset\",   # Base name for output files of .jsonl format (training/testing/validation files of 80%/10%/10% are produced)\n    )","category":"page"},{"location":"#Functions","page":"Home","title":"Functions","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Modules = [BenchmarkDataNLP]\nPrivate = false\nOrder = [:function]","category":"page"},{"location":"#BenchmarkDataNLP.generate_corpus_CFG-Tuple{}","page":"Home","title":"BenchmarkDataNLP.generate_corpus_CFG","text":"generate_corpus_CFG(\n    ; \n    complexity::Int = 100, \n    num_sentences::Int = 100_000, \n    enable_polysemy::Bool = false, \n    output_dir::AbstractString = \".\", \n    base_filename::AbstractString = \"CFG_Corpus\"\n) -> Nothing\n\nGenerate a synthetic corpus of text using a randomly constructed Context-Free Grammar (CFG).  This function creates a vocabulary (including punctuation), assigns words to various grammar  roles, builds random expansions for each role, and then recursively expands a start role  to produce individual text lines. The corpus is randomly shuffled and split into 80%  training, 10% testing, and 10% validation .jsonl files. It also saves a metadata file  describing the generated grammar.\n\nArguments\n\ncomplexity::Int (default = 100): Controls the overall size and complexity of the grammar  and vocabulary. Higher values lead to more roles, more words, and larger expansions  (potentially producing lengthier or more varied sentences). \nRange: 1 ≤ complexity ≤ 1000.\nBehavior: \nAt lower values (≈1–10), the grammar is quite small.\nAt or beyond 100, expansions can become extensive and less “natural.”\nnum_sentences::Int (default = 100_000): Total number of text lines (sentences) to generate.\nenable_polysemy::Bool (default = false): If true, words may appear in multiple roles,  introducing lexical ambiguity. If false, each word is assigned to exactly one role.\noutput_dir::AbstractString (default = \".\"): Directory path to which all output files  (the corpus .jsonl files and metadata .json) are written.\nbase_filename::AbstractString (default = \"CFG_Corpus\"): Base name for output files.  The function writes:\n\"<base_filename>_metadata.json\": A JSON file describing the generated grammar, roles, etc.\n\"<base_filename>_training.jsonl\", \"<base_filename>_testing.jsonl\", and  \"<base_filename>_validation.jsonl\": The text corpus in JSON Lines format.\n\nDescription\n\nVocabulary & Punctuation   A base alphabet is sampled given the complexity. Then, punctuation tokens are added.  Words are formed by combining characters from the alphabet (the size of the vocabulary  also scales with complexity).\nRole Creation   A set of grammar roles (e.g., Role1, Role2, ...) is generated. The number of roles  grows with complexity. \nRole Assignment & Polysemy  \nIf enable_polysemy=false, each word is placed into exactly one role’s vocabulary.  \nIf enable_polysemy=true, words may appear in multiple roles (e.g., “bat” might be  assigned to both Noun and Verb roles).\nGrammar Construction  \nFor each role, a number of random expansions is created (scaling with complexity).\nAn expansion is a sequence of items, each of which may be another role (non-terminal)  or a terminal word. \nRecursion depth is limited (sentence_recursion_max_depth) to prevent infinite loops  if the expansions reference one another excessively.\nSentence Generation  \nEach of the num_sentences lines is produced by randomly choosing a start role, then  recursively expanding it until only terminal words remain or the maximum recursion depth  is reached. \nThe resulting tokens are joined into a single line of text.\nOutput  \nThe generated lines are shuffled and split into train (80%), test (10%), and validation  (10%) sets. \nThree .jsonl files are written: \"[base_filename]_training.jsonl\",  \"[base_filename]_testing.jsonl\", and \"[base_filename]_validation.jsonl\". \nA metadata file, \"[base_filename]_metadata.json\", captures the grammar, roles, and  vocabulary used.\n\nReturns\n\nNothing. The corpus (train/test/validation) and a metadata file describing the grammar are  saved to disk as JSON files.\n\nExample\n\n```julia generatecorpusCFG(     complexity      = 100,      numsentences   = 100000,      enablepolysemy = true,      outputdir      = \"/path/to/output\",      base_filename   = \"MyCFGCorpus\" )\n\n\n\n\n\n","category":"method"},{"location":"#BenchmarkDataNLP.generate_fsm_corpus-Tuple{Int64, Int64}","page":"Home","title":"BenchmarkDataNLP.generate_fsm_corpus","text":"generate_fsm_corpus(\n    complexity::Int, \n    num_lines::Int;\n    output_dir::String=\".\",\n    base_name::String=\"MyFSM\",\n    use_context::Bool=false,\n    random_adjacency::Bool=false,\n    max_length::Int=10\n) -> Nothing\n\nGenerates a synthetic text corpus by constructing a Finite State Machine (FSM) adjacency structure and \"walking\" it to produce lines of text. The resulting lines are automatically split into training, testing, and validation sets (80%, 10%, 10%) and saved as JSON lines (.jsonl files).\n\nArguments\n\ncomplexity::Int: Governs the overall size of the vocabulary and the probability of generating terminal (ending) transitions. Higher complexity results in:\nA larger vocabulary.\nA lower proportion of transitions that lead immediately to a terminal symbol.\nnum_lines::Int: Number of total lines (FSM walks) to generate in the corpus.\n\nKeyword Arguments\n\noutput_dir::String: Directory where the JSONL output files are written (default: \".\").\nbase_name::String: Base filename for the output files. The function creates three JSONL files named \"<base_name>_train.jsonl\", \"<base_name>_test.jsonl\", and \"<base_name>_val.jsonl\".\nuse_context::Bool: If true, the vocabulary is split into “context words” and  “normal words,” and context words may appear in expansions more frequently to simulate shared or thematic context. If false, all words are treated uniformly.\nrandom_adjacency::Bool: Controls whether the FSM adjacency (i.e., expansions from each word) is created randomly or deterministically:\ntrue: Each word randomly links to 1–3 possible expansions, some of which might be terminal. \nfalse: Each word deterministically expands (e.g., in sorted order), thus producing consistent, repeatable chains.\nmax_length::Int: The maximum number of expansions (steps) for each walk (default: 10). The walk ends if a terminal is reached or max_length expansions are exceeded.\n\nDescription\n\nVocabulary Construction:\nA base alphabet is generated according to the complexity.\nA vocabulary is created from this alphabet, again sized according to complexity.\nIf use_context=true, part of this vocabulary is designated as “context words,” while the remaining words serve as “normal words.”\nFSM Adjacency Building:\nIf random_adjacency=true, each word’s expansions are chosen randomly. A certain fraction of these expansions lead to a terminal symbol (the fraction decreases as  complexity increases).\nOtherwise (for random_adjacency=false), expansions follow a deterministic pattern (e.g., next words in sorted order).\nLine Generation:\nFor each of the num_lines, a starting word is randomly selected.\nThe function performs a round-robin deterministic walk from that starting word up  to max_length expansions or until a terminal expansion is reached. The sequence of tokens visited during this walk is concatenated into a single line of text.\nOutput:\nAll generated lines are randomly shuffled and then split into three sets:\nTraining: 80%\nTesting: 10%\nValidation: 10%\nThese lines are written in .jsonl format as <base_name>_train.jsonl,  <base_name>_test.jsonl, and <base_name>_val.jsonl.\n\nReturns\n\nNothing. The generated text corpus is written to disk in JSONL format.\n\nExample\n\n```julia generatefsmcorpus(     50,                # complexity -> larger vocabulary, fewer terminal expansions     100;               # produce 100 lines     outputdir=\".\",      basename=\"MyFSM\",     usecontext=true,      randomadjacency=true,     max_length=12 )\n\n\n\n\n\n","category":"method"},{"location":"#BenchmarkDataNLP.generate_rdf_corpus-Tuple{Int64, Int64}","page":"Home","title":"BenchmarkDataNLP.generate_rdf_corpus","text":"generate_rdf_corpus(\n    complexity::Int,\n    num_paragraphs::Int;\n    output_dir::String=\".\",\n    base_name::String=\"MyRDF\",\n    filler_ratio::Float64=0.0,\n    max_filler::Int=0,\n    use_context::Bool=false\n) -> Nothing\n\nGenerate a synthetic RDF-based text corpus and automatically split it into  training, testing, and validation sets. The corpus is saved as .jsonl files.\n\nArguments\n\ncomplexity::Int: Controls the scale of the generated vocabulary and triple store. Higher complexity leads \n\nto a larger vocabulary, more subjects/predicates/objects, and potentially a higher number of triples.\n\nnum_paragraphs::Int: The total number of lines (or “paragraphs” if use_context=true) to \n\nproduce in the final corpus.\n\noutput_dir::String: Directory where output files will be saved (\".\" by default).\nbase_name::String: Base name for the output files. The function will produce three files named \n\n<base_name>_train.jsonl, <base_name>_test.jsonl, and <base_name>_val.jsonl.\n\nfiller_ratio::Float64: Fraction of the vocabulary leftover (after allocating subjects, predicates, \n\nand objects) that is used for filler tokens. For example, a value of 0.3 means 30% of the leftover words      become filler tokens. A higher ratio produces more distinct filler words you can insert in generated sentences.      If this is 0.0, no extra tokens are dedicated to filler.\n\nmax_filler::Int: The maximum number of filler tokens inserted around each subject, \n\npredicate, or object in a generated sentence. For example, if max_filler=2, then up to  two randomly chosen filler tokens might appear before the subject, between subject and  predicate, or between predicate and object.\n\nuse_context::Bool: If true, generates multi-sentence paragraphs reusing previously \n\nmentioned entities (subject/object) within each paragraph, introducing some “context.”  Otherwise, each line is just a single triple-based sentence with no continuity.\n\nDescription\n\nVocabulary & Triple Store: Based on complexity, the function creates a master vocabulary \n\nand partitions it into subjects, predicates, objects, and (optionally) filler. A random subset  of (subject, predicate, object) combinations is then chosen to form a finite triple store.\n\nText Generation:\n\nIf use_context=false, each line is a single sentence referencing a randomly picked triple, \n\noptionally inserting up to max_filler filler tokens around the subject/predicate/object.\n\nIf use_context=true, the function produces multi-sentence paragraphs, where each paragraph \n\nattempts to reuse entities mentioned in prior sentences for added context.\n\nOutput:\n\nThe resulting lines or paragraphs are shuffled and split into training (80%), testing (10%), \n\nand validation (10%) sets.\n\nSaved as JSON lines in files named <base_name>_train.jsonl, <base_name>_test.jsonl, \n\nand <base_name>_val.jsonl within output_dir.\n\nReturns\n\nNothing. The synthetic corpus is written to disk in JSONL format.\n\nExample\n\n```julia generaterdfcorpus(     50,     1000;     outputdir = \".\",     basename = \"MyRDF\",     fillerratio = 0.2,     maxfiller = 2,     usecontext = true )\n\n\n\n\n\n","category":"method"},{"location":"#BenchmarkDataNLP.generate_tps_corpus-Tuple{Int64, Int64}","page":"Home","title":"BenchmarkDataNLP.generate_tps_corpus","text":"generate_tps_corpus(\n    complexity::Int,\n    num_lines::Int;\n    output_dir::String = \".\",\n    base_name::String = \"MyTPS\",\n    n_templates::Int = 10,\n    max_placeholders_in_template::Int = 4,\n    deterministic::Bool = false\n) -> Nothing\n\nGenerates a synthetic text corpus by filling randomly constructed templates with vocabulary  tokens. The corpus is split into training, testing, and validation sets (80/10/10) and saved  as .jsonl files.\n\nArguments\n\ncomplexity::Int: Governs the size of the vocabulary and the number of available “bridging words.” Higher values increase the overall variety of tokens.\nnum_lines::Int: Total number of lines (sentences) to generate. These lines are then split  into train (80%), test (10%), and validation (10%) sets.\noutput_dir::String: Directory path to which the .jsonl files are written (default: \".\").\nbase_name::String: Base prefix for output files, e.g., <base_name>_train.jsonl,  <base_name>_test.jsonl, and <base_name>_val.jsonl (default: \"MyTPS\").\nn_templates::Int: Number of randomly generated templates to build (default: 10).  Each template specifies a textual skeleton with placeholder slots.\nmax_placeholders_in_template::Int: Maximum number of placeholder tokens each template  can contain (default: 4). These placeholders are drawn from a set of roles (e.g., SUBJECT,  VERB, ADJECTIVE, OBJECT).\ndeterministic::Bool: If true, placeholders in each template are filled using a  systematic (round-robin) approach. If false, placeholders are chosen randomly from  the available dictionary.\n\nDescription\n\nVocabulary & Bridging Words  \nA base vocabulary is built according to complexity. \nA subset of the vocabulary is designated as “bridging words,” which act as connecting tokens  (e.g., \"the\", \"some\") for the templates.\nThe remainder of the vocabulary is partitioned into roles for placeholders  (e.g., :SUBJECT, :VERB, :ADJECTIVE, :OBJECT).\nTemplate Construction  \nn_templates are generated, each containing up to max_placeholders_in_template placeholders. \nBetween placeholders, random bridging words (or other connectors) are inserted to form a  base template string (e.g., \"the {SUBJECT} a {VERB} some {OBJECT}.\").\nFilling Templates  \nFor each of the num_lines text samples, one template is selected (either in a round-robin  fashion if deterministic=true, or randomly otherwise).\nThe placeholders in that template are then filled with actual words from the assigned  placeholder dictionaries. \nA round-robin strategy ensures systematic coverage of each placeholder’s vocabulary, while  random selection injects more variation.\nOutput Splitting & JSONL Writing  \nAll generated lines are shuffled, then split into 80% training, 10% testing, and 10% validation sets.\nThree .jsonl files are created with filenames based on base_name:  \"<base_name>_train.jsonl\", \"<base_name>_test.jsonl\", and \"<base_name>_val.jsonl\".\nEach line in these files is a single JSON object containing the text (e.g., {\"text\": \"the cat ate some fish.\"}).\n\nReturns\n\nNothing. The final corpus is written to disk in JSON Lines format.\n\nExample\n\n```julia generatetpscorpus(     50,             # complexity     100;            # numlines     basename      = \"TemplatedTest\",     n_templates    = 5,     deterministic  = false )\n\n\n\n\n\n","category":"method"},{"location":"#BenchmarkDataNLP.greet-Tuple{}","page":"Home","title":"BenchmarkDataNLP.greet","text":"greet()\n\nPrints a friendly greeting message to the console.\n\nReturns nothing\n\n\n\n\n\n","category":"method"}]
}

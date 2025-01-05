
const alphabet_unicode_start_ind = 44032 #0xAC00 HANGUL_START = 0xAC00
const alphabet_increment_step_size = 2

const punctuation_unicode_start_ind = 256 #Latin Extended-A block, 0x0100 256 in decimal
const punctuation_increment_step_size = 10

function complexity_to_alphabet(complexity::Int)
    char_number = div( complexity, alphabet_increment_step_size )
    return Char.( alphabet_unicode_start_ind:alphabet_unicode_start_ind+char_number-1 )
end

function complexity_to_punctuation(complexity::Int)
    char_number = div( complexity, punctuation_increment_step_size )
    return Char.( punctuation_unicode_start_ind:punctuation_unicode_start_ind+char_number-1 )
end
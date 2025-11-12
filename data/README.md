# Dictionary Files

This directory contains word dictionaries for the Wordle game, organized by word length (2-10 letters).

The dictionary module provides **a list of words of variable length with supporting functions** for loading, filtering, validating, and selecting words from these dictionaries.

## File Structure

For each word length (2-10), there are two files:
- `words.txt` - Contains all valid words that players can guess
- `answers.txt` - Contains a curated subset of common/fair words that can be used as answers

## Important Notes

**answers.txt is the subset of words.txt**
- All words in `answers.txt` are also present in `words.txt`
- Players can guess any word from `words.txt`, but answers are only selected from `answers.txt`

**answers.txt include common/fair words**
- `answers.txt` contains only common/fair words to ensure a fair and enjoyable game experience
- `words.txt` can include more obscure words that players can use for strategic guessing
- This design ensures that while players can use uncommon words to test letters, the actual answer will always be a familiar word

## File Organization

```
data/
├── 2letter/
│   ├── words.txt    (all valid 2-letter guesses)
│   └── answers.txt  (common 2-letter words for answers)
├── 3letter/
│   ├── words.txt    (all valid 3-letter guesses)
│   └── answers.txt  (common 3-letter words for answers)
...
└── 10letter/
    ├── words.txt    (all valid 10-letter guesses)
    └── answers.txt  (common 10-letter words for answers)
```

## Statistics

| Length | words.txt | answers.txt | Coverage |
|--------|-----------|-------------|-----------|
| 2 letters | 23 | 23 | 100% |
| 3 letters | 90 | 90 | 100% |
| 4 letters | 347 | 347 | 100% |
| 5 letters | 611 | 389 | 64% |
| 6 letters | 330 | 172 | 52% |
| 7 letters | 256 | 138 | 54% |
| 8 letters | 260 | 133 | 51% |
| 9 letters | 237 | 108 | 46% |
| 10 letters | 122 | 54 | 44% |

## Usage

The dictionary module (`Dict`) loads these files:
- `Dict.load_dictionary_by_length(n)` returns both `words.txt` and `answers.txt` for length `n`
- `Dict.is_valid_word(word, words)` checks if a guess is valid (uses words.txt)
- `Dict.get_random_word(answers)` selects a random answer (uses answers.txt)


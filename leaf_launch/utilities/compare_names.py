# compare two columns of names in a csv or tsv file
import argparse
import csv
import string

trans_dict = str.maketrans(string.punctuation, ' ' * len(string.punctuation))
stop_words = set(['a', 'an', 'and', 'at', 'by', 'eg', 'for', 'in', 'into', 'of', 'on', 'or',
                  's', 'than', 'the', 'to', 'using', 'w', 'with'])

def name_to_words(name):
    ''' Map a multi-word name into significant, comparable words
    '''
    # convert text to a common case & remove punctuation
    std_name = name.lower().translate(trans_dict)

    # parse into words
    # remove stop words
    return set(std_name.split()) - stop_words

def naked_words(words):
    return ', '.join(sorted(words))

def compare_names(name_1, name_2):
    ''' Compare two names, returning a score = # matching words / # all words
    '''
    words_1 = name_to_words(name_1)
    words_2 = name_to_words(name_2)

    # matching words (size of intersection set)
    matching_words = words_1 & words_2
    all_words = words_1 | words_2
    unmatched_words = all_words - matching_words

    # score = (# matching words)/(# all words)
    score = len(matching_words) / len(all_words)

    # max score = (min # words) / (# words in union)
    max_score = min(len(words_1), len(words_2)) / len(all_words)

    # return score, max possible score, their ratio, words that match, words that don't match
    return score, max_score, score/max_score, naked_words(matching_words), naked_words(unmatched_words)

rv = name_to_words("now, the SHIT's gonna hit the fan!")
# print(rv)
e = set(['now', 'shit', 'gonna', 'hit', 'fan'])
assert rv == e

a = 'well, EAT 1 raw Apple'
b = 'Eat one: well-done pair APPLE'
rv = compare_names(a, b)
# print(rv)
e = (0.375, 0.625, 0.6, set(['well', 'eat', 'apple']), set(['1', 'raw', 'one', 'done', 'pair']))
# assert rv == e

parser = argparse.ArgumentParser(description="Annotate concept mapping table which has two names columns with the similiarity of the names")
parser.add_argument("csv_file", help="csv filename")
parser.add_argument("names_column_1", help="1st names column")
parser.add_argument("names_column_2", help="2nd names column")
args = parser.parse_args()

outfile = args.csv_file.removesuffix('.csv') + '_scored.csv'

with open(args.csv_file, newline='') as csvfile:
    reader = csv.DictReader(csvfile)

    with open(outfile, 'w', newline='') as csv_outfile:
        fieldnames = reader.fieldnames + ['Comp. score', 'Max score', 'Ratio', "Matching words", "Unmatched words"]
        writer = csv.DictWriter(csv_outfile, fieldnames=fieldnames)
        writer.writeheader()

        for row in reader:
            name_1 = row[args.names_column_1]
            name_2 = row[args.names_column_2]
            row[fieldnames[-5]], row[fieldnames[-4]], row[fieldnames[-3]], row[fieldnames[-2]], row[fieldnames[-1]] = compare_names(name_1, name_2)
            writer.writerow(row)

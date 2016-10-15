## howto
to compile any of tasks _(haha, who in their sane mind is gonna need this very repository anyway)_:
* install [dub](https://code.dlang.org/download)
* `cd` to a, say, `ir01` and run `dub build`
  * You may also try executing `dub build :ir01` and suchs from the root directory, but that doesn't always work (screw me if I know why)

## summary
| no.  | task | additional info |
|---|---|---|
| ir01 | inverted index | |
| ir02 | boolean search | and/or/not support; queries are parsed using shunting yard algorithm |
| ir03 | external stemmer | oleander stemming library (porter stemmer, basically) |
| ir04 | index w/ skip pointers | |
| ir05 | bigram index | |
| ir06 | coordinate index | enables one to search citations |
| ir07 | metasymbol search | trie |
| ir08 | indexation using mapreduce | hadoop streaming |
| ir09 | index compression | variable byte encoding |
| lp01 | zipf's law coefficients | |
| lp02 | mandelbrot's law coefficients | |
| lp03 | collocations | |
| lp04 | language model w/ smoothing | lidstone smoothing |
| lp05 | spellchecking | viterbi algorithm + lidstone smoothing |

## resources
* texts used for IR tasks (may require preprocessing due to invalid html markdown):
	* [Анна Каренина][1]
	* [Воскресение][2]
	* [Исследование догматического богословия][3]
* [oleander stemming library][6]
* stop words list obtained using [nltk][4]
* text corpus for lp03~05 obtained from [leipzig corpora collection][5]

[1]: http://az.lib.ru/t/tolstoj_lew_nikolaewich/text_0080.shtml
[2]: http://az.lib.ru/t/tolstoj_lew_nikolaewich/text_0090.shtml
[3]: http://az.lib.ru/t/tolstoj_lew_nikolaewich/text_0150.shtml
[4]: http://www.nltk.org/data.html
[5]: http://corpora2.informatik.uni-leipzig.de/download.html
[6]: https://github.com/OleanderSoftware/OleanderStemmingLibrary

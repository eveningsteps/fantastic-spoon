module spellchecker;

import std.string;
import std.utf;
import std.conv;
import std.algorithm;
import std.math;
import std.array : array;
import std.range;
import smoothing;


/* The spellchecker, apart from the Viterbi part, is the courtesy of
   Leonardo Maffi: http://leonardo-m.livejournal.com/112262.html

   On the bright side, I implemented Viterbi algorithm myself. Yay!
 */


auto set(R)(R r)
{
	return r.zip(0.repeat).assocArray;
}


int[dstring] wc;
dstring alphabet = "абвгдежзийклмнопрстуфхцчшщъыьэюя"d;


auto edits(in dstring w)
{
	int n = w.length.to!int;
	auto deletions = n.iota.map!(i => w[0 .. i] ~ w[i + 1 .. $]);
	auto transpositions = iota(n-1).map!(i => w[0 .. i] ~ w[i + 1] ~ w[i] ~ w[i + 2 .. $]);
	auto alterations = n.iota.cartesianProduct(alphabet).map!(p => w[0 .. p[0]] ~ cast(dchar)p[1] ~ w[p[0] + 1 .. $]);
	auto insertions = iota(n+1).cartesianProduct(alphabet).map!(p => w[0 .. p[0]] ~ cast(dchar)p[1] ~ w[p[0] .. $]);

	return chain(deletions, transpositions, alterations, insertions).set;
}

auto known(R)(R words)
{
	return words.filter!(w => w in wc).set.keys;
}

enum knownEdits = (dstring word) => word.edits.byKey.map!(e => e.edits.byKey).joiner.known;

T or(T)(T x, lazy T y)
{
	return x.length? x : y;
}

auto candidates(in dstring word)
{
	auto candidates = [word].known ~ word.edits.byKey.known ~ word.knownEdits ~ [word];
	return candidates.set.keys;
}

void find_arg_max(R)(R r, ref double val, ref int idx)
{
	foreach(i, e; r.enumerate)
		if(e > val)
			val = e, idx = i.to!int;
}

auto viterbi(in dstring[][] cands, in LidstoneSmoother ls, double lambda)
{
	int t = cands.length.to!int;
	double[][] prob = new double[][t];
	int[][] prev = new int[][t];

	t.iota.each!(i => prev[i].length = prob[i].length = cands[i].length);
	foreach(i; 0 .. cands[0].length)
	{
		prob[0][i] = log(ls.estimate(cands[0][i], lambda));
		prev[0][i] = -1;
	}

	foreach(i; 1 .. t)
		foreach(j; 0 .. cands[i].length)
		{
			auto probs = iota(cands[i-1].length).map!
				(a => prob[i-1][a] + log(ls.estimate(cands[i-1][a], cands[i][j], lambda)));

			double best_prob = -1e20;
			int best_prev = -1;
			find_arg_max(probs, best_prob, best_prev);
			
			prev[i][j] = best_prev;
			prob[i][j] = best_prob;
		}
	
	int[] indices;
	double best_prob = -1e20;
	int best_idx = -1;
	find_arg_max(prob[t-1], best_prob, best_idx);
	foreach(i; iota(t-1, -1, -1))
	{
		indices ~= best_idx;
		best_idx = prev[i][best_idx];
	}
	
	return t.iota.map!(i => cands[i][indices[t - 1 - i]]);
}

auto correct(in dstring query, in LidstoneSmoother ls, double lambda)
{
	return viterbi(query.strip().split().map!(w => w.tokenize.candidates).array, ls, lambda);
}


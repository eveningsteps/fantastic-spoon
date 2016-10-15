module smoothing;

import std.string;
import std.utf;
import std.conv;
import std.algorithm;
import std.typecons;
import std.math;
import std.array : array;
import std.range;
import std.stdio;


dstring tokenize(in dstring token)
{
    static string punctuation = ".,!?\";-:\'()";
    return toLower(token.translate(null, punctuation));
}

dstring[][] preprocess_text(in dstring text)
{
    dstring[][] lines = [];
    foreach(line; text.split("\n"))
    {
        auto l = line.split("\t");
        if(l.length < 2)
            continue;

        dstring[] tok = l[1].split(' ');
        auto tokens = tok.map!(a => tokenize(a))()
                         .filter!(a => !a.empty)().array;
        lines ~= tokens;
    }

    return lines;
}

class LidstoneSmoother
{
	int[dstring] wc;
	int[dstring][dstring] bc;
	int wt;

	void train(in dstring[][] lines)
	{
		foreach(l; lines)
			for(int i = 0; i < l.length; ++i)
			{
				++wc[l[i]];
				if(i)
					++bc[l[i-1]][l[i]];
			}

		wt = sum(wc.values);
	}

	double estimate(in dstring b0, in dstring b1, double lambda) const
	{
		double num = bc.get(b0, (int[dstring]).init).get(b1, 0) + lambda;
		double denom = wc.get(b0, 0) + wt * (1 + lambda);

		return num / denom;
	}

	double estimate(in dstring b, double lambda) const
	{
		return (wc.get(b, 0) + lambda) / (wt * (1 + lambda));
	}
}


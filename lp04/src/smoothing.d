import std.string;
import std.stdio;
import std.utf;
import std.getopt;
import std.file;
import std.conv;
import std.algorithm;
import std.typecons;
import std.math;
import std.array : array;
import std.range;

alias Bigram = Tuple!(dstring, dstring);

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
	int[Bigram] bc;

	void train(in dstring[][] lines)
	{
		foreach(l; lines)
		{
			for(int i = 0; i < l.length; ++i)
			{
				++wc[l[i]];
				if(i)
					++bc[Bigram(l[i-1], l[i])];
			}
		}
	}

	double estimate(in Bigram b, double lambda)
	{
		double num = bc.get(b, 0) + lambda;
		double denom = wc.get(b[0], 0) + wc.length * lambda;

		return num / denom;
	}
}

void main(string[] args)
{
    string text_path;
    getopt(args, "t", &text_path);
    if(text_path.empty)
    {
        writeln("USAGE: -t <text file>");
        return;
    }

    dstring[][] lines = preprocess_text(toUTF32(to!string(read(text_path))));
	auto ls = new LidstoneSmoother;

    double percentage = 0.2;
    double best_perplexity = 1e10, best_lambda;

	writeln("L\tperplexity");
    foreach(lambda; iota(0, 8, 1).map!(a => 1e-6 * 10 ^^ a).array)
    {
		double total_perplexity = 0;
        for(float f = 0.; f < 1; f += percentage)
        {
            int start = to!int(lines.length * f), end = to!int(lines.length * min(1., (f + percentage)));
            auto test_data = lines[start .. end];
            auto training_data = lines[0 .. start] ~ lines[end .. $];
            
			ls.train(training_data);
			foreach(sentence; test_data)
			{
				double log_prob_sum = 0;
				for(int i = 1; i < sentence.length; ++i)
				{
					double prob = ls.estimate(Bigram(sentence[i-1], sentence[i]), lambda);
					log_prob_sum = log(1 / prob);
				}

				total_perplexity += log_prob_sum ^^ (1. / sentence.length);
			}
        }
		
		writefln("%s\t%s", lambda, total_perplexity);
		if(total_perplexity < best_perplexity)
			best_perplexity = total_perplexity, best_lambda = lambda;
    }

    writefln("Best lambda: %s", best_lambda);    
}

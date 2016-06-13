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

alias Bigram = Tuple!(dstring, dstring);
alias BigramPair = Tuple!(double, Bigram);


dstring tokenize(in dstring token)
{
    static string punctuation = ".,!?\";-:\'";
    return toLower(token.translate(null, punctuation));
}


double t_test(double p, double mu, long N)
{
    double sigm2 = p * (1 - p);
    double t = (p - mu) / sqrt(sigm2 / N);
    return t;
}


void main(string[] args)
{
    string text_path, stop_path;
    getopt(args, "t", &text_path, "s", &stop_path);
    if(text_path.empty || stop_path.empty)
    {
        writeln("USAGE: -t <text file> -s <stop words file>");
        return;
    }

    dstring text = toUTF32(to!string(read(text_path)));
    dstring[] sw_list = toUTF32(to!string(read(stop_path))).split();
    bool[dstring] stop_words;
    foreach(word; sw_list)
        stop_words[word] = true;

    long text_length = 0;
    int[dstring] word_freq;
    int[Bigram] bigram_freq;

    foreach(line; text.split("\n"))
    {
        auto l = line.split("\t");
        if(l.length < 2)
            continue;

        dstring[] tok = l[1].split(' ');
        text_length += tok.length;

        auto tokens = tok.map!(a => tokenize(a))()
                         .filter!(a => !a.empty)().array;
        foreach(i; 0 .. tokens.length)
        {
            ++word_freq[tokens[i]];
            if(i && tokens[i] !in stop_words && tokens[i-1] !in stop_words)
                ++bigram_freq[Bigram(tokens[i-1], tokens[i])];
        }
    }
    
    long bigrams_cnt = bigram_freq.length;
    double significance = 2.576;
    BigramPair[] true_bigrams = [];
    foreach(bigram; bigram_freq.byKey())
    {
        double mu = word_freq[bigram[0]] * word_freq[bigram[1]] / double(text_length * text_length);
        double p = bigram_freq[bigram] / double(bigrams_cnt);
        double t = t_test(p, mu, bigram_freq.length);
        if(t > significance)
            true_bigrams ~= BigramPair(t, bigram);
    }
    
    int first_n = 50;
    sort!("a[0] > b[0]")(true_bigrams);
    foreach(tbg; true_bigrams[0 .. min(first_n, true_bigrams.length)])
        writefln("%s\t%s %s", tbg[0], tbg[1][0], tbg[1][1]);
}

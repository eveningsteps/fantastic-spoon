import std.file;
import std.getopt;
import std.utf;
import std.string;
import std.stdio;
import std.conv;
import smoothing;
import spellchecker;

void main(string[] args)
{
	string text_path;
	getopt(args, "t", &text_path);
	if(text_path.empty)
	{
		writeln("USAGE: -t <training sentences set>");
		return;
	}

	dstring[][] lines = preprocess_text(toUTF32(to!string(read(text_path))));
	auto ls = new LidstoneSmoother;
	ls.train(lines);
	wc = ls.wc;
	
	double lambda = 1e-5; // obtained in lp04
	foreach(dstring line; stdin.lines)
	{
		line = line.strip();
		if(line.empty)
			continue;
		auto fix = correct(line, ls, lambda);
		writefln("%s -> %s", line.strip(), fix.join(' '));
	}
}


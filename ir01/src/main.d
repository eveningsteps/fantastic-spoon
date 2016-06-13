import std.conv;
import std.stdio;
import std.file;
import std.datetime;
import std.string;
import std.getopt;
import std.utf;

import indexer;

struct DummyStemmer
{
	dstring stem(in dstring word)
	{
		return word;
	}
}

void main(string[] args)
{	
	string index_path, text_path;
	getopt(args,
		"i|index", &index_path,
		"t|text", &text_path);
	
	if(index_path.empty || text_path.empty)
	{
		writefln("USAGE: %s -i <index path> -t <text file>", args[0]);
		return;
	}
	
	auto starttime = MonoTime.currTime();
	auto indexer = new Indexer!DummyStemmer;
	
	string raw_text = to!string(read(text_path));
	indexer.build_index(toUTF32(raw_text));
	indexer.save_index(index_path);

	auto endttime = MonoTime.currTime();
	auto delta = endttime - starttime;
	
	writefln("Execution time: %s ms", delta.total!"msecs");
	writefln("Tokens: %s (average length: %s)", indexer.stats["tokens"], indexer.stats["tokens_length"] / indexer.stats["tokens"]);
	writefln("Terms: %s (average length: %s)", indexer.stats["terms"], indexer.stats["terms_length"] / indexer.stats["terms"]);
	writefln("Read %s documents", indexer.stats["docs"]);
}


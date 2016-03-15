import std.conv;
import std.stdio;
import std.file;
import std.datetime;
import std.string;
import std.getopt;
import std.utf;

import indexer;
import wrapper;

void main(string[] args)
{	
	string index_path, text_path;
	getopt(args,
		"i|index", &index_path,
		"t|text", &text_path);
	
	if(!index_path.length || !text_path.length)
	{
		writefln("USAGE: %s -i <index path> -t <text file>", args[0]);
		return;
	}
	
	auto starttime = MonoTime.currTime();
	auto indexer = new Indexer!StemmerWrapper;
	
	string raw_text = to!string(read(text_path));
	indexer.build_index(toUTF32(raw_text));
	indexer.save_index(index_path);

	auto endttime = MonoTime.currTime();
	auto delta = endttime - starttime;
	
	writefln("Execution time: %s ms", delta.total!"msecs");
	writefln("Tokens: %s (average length: %s)", indexer.stats["tokens"], indexer.stats["avg_token_length"]);
	writefln("Terms: %s (average length: %s)", indexer.stats["terms"], indexer.stats["avg_term_length"]);
	writefln("Read %s paragraphs of text", indexer.stats["docs"]);
}


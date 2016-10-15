import std.conv;
import std.stdio;
import std.file;
import std.datetime;
import std.string;
import std.getopt;
import std.utf;
import std.typecons;
import std.algorithm;

import indexer;
import searcher;
import trie;

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
	bool notext;
	getopt(args,
		"i|index", &index_path,
		"t|text", &text_path,
		"notext", &notext);

	if(!index_path.length || !text_path.length)
	{
		writefln("USAGE: %s -i <index path> -t <text file>", args[0]);
		return;
	}

	auto starttime = MonoTime.currTime();
	auto indexer = new Indexer!DummyStemmer;

	string raw_text = to!string(read(text_path));
	indexer.build_index(toUTF32(raw_text));
	indexer.save_index(index_path);

	auto endtime = MonoTime.currTime();
	auto delta = endtime - starttime;
	writefln("Index built in %s ms", delta.total!"msecs");


	File index = File(index_path ~ "/index", "rb");
	File dictionary = File(index_path ~ "/dictionary", "r");

	int[][dstring] dict;
	int[int] start_of;

	starttime = MonoTime.currTime();

	dstring text = toUTF32(to!string(read(text_path)));
	int wc;

	dictionary.readf(" %s", &wc);
	foreach(u; 0 .. wc)
	{
		string w;
		int pos, freq;
		dictionary.readf(" %s %s %s", &w, &freq, &pos);
		
		dstring word = toUTF32(w);
		int dc;
		index.rawRead((&dc)[0 .. 1]);
		Doc[] d = new Doc[dc];

		index.rawRead(d);
		foreach(doc; d)
		{
			start_of[doc.id] = doc.pos;
			dict[word] ~= doc.id;
		}
	}

	auto trie = new Trie(), rev_trie = new Trie();
	foreach(w; dict.byKey())
	{
		trie.add(w ~ "$");
		auto ww = w.dup;
		reverse(ww);
		rev_trie.add(to!dstring(ww ~ "$"));
	}

	endtime = MonoTime.currTime();
	delta = endtime - starttime;
	writefln("Index read in %s ms", delta.total!"msecs");

	QueryParser qp;
	foreach(dstring line; lines(stdin))
	{
		auto st = MonoTime.currTime();
		auto result = qp.process(line, dict, to!int(start_of.length), [trie, rev_trie]);
		auto dq = MonoTime.currTime() - st;

		if(result.docs.empty)
			writeln("Nothing found!");
		else
		{
			writefln("Found %s docs", result.docs.length);
			writefln("Found %s terms: %s", result.terms.length, result.terms);
		}

		writefln("Query processed in %s ms", dq.total!"usecs" / float(1000));
	}

}


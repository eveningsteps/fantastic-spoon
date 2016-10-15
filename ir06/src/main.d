import std.conv;
import std.stdio;
import std.file;
import std.datetime;
import std.string;
import std.getopt;
import std.utf;
import std.typecons;

import indexer;
import searcher;

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

	alias Entry = Tuple!(int, "id", int[], "occ");
	Entry[][dstring] dict;
	int[int] start_of;

	dstring text = toUTF32(to!string(read(text_path)));
	int wc;

	dictionary.readf(" %s", &wc);
	foreach(u; 0 .. wc)
	{
		string w;
		int pos, freq;
		dictionary.readf(" %s %s %s", &w, &freq, &pos);

		dstring word = toUTF32(w);
		int d;
		index.rawRead((&d)[0 .. 1]);
		foreach(i; 0 .. d)
		{
			int[2] id_pos;
			index.rawRead(id_pos);

			int occ_len;
			index.rawRead((&occ_len)[0 .. 1]);

			int[] occ = new int[occ_len];
			index.rawRead(occ);

			start_of[id_pos[0]] = id_pos[1];
			dict[word] ~= Entry(id_pos[0], occ);
		}
	}

	endtime = MonoTime.currTime();
	delta = endtime - starttime;
	writefln("Index read in %s ms", delta.total!"msecs");

	QueryParser qp;
	foreach(dstring line; lines(stdin))
	{
		auto st = MonoTime.currTime();
		int[] result = qp.process(line, dict);
		auto dq = MonoTime.currTime() - st;

		int fake_res = 0;
		if(!result.length)
			writeln("Nothing found!");
		else if(notext)
			writeln(result);
		else foreach(doc; result)
		{
			if(!(doc in start_of))
			{
				++fake_res;
				continue;
			}

			int cap = start_of.get(doc + 1, to!int(text.length) - 1);
			writefln("Document %s: %s", doc, text[start_of[doc] .. cap]);
			writeln("-----------------");
		}

		writefln("Query processed in %s ms with %s results", dq.total!"usecs" / float(1000), result.length - fake_res);
	}

}


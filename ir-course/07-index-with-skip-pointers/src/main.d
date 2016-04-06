import std.conv;
import std.stdio;
import std.file;
import std.datetime;
import std.string;
import std.getopt;
import std.utf;

import searcher;

void main(string[] args)
{
	string index_path, text_path;
	int skip;
	enum Details
	{
		none,
		docs,
		all
	};
	
	Details details = Details.none;

	getopt(args,
		"i|index", &index_path,
		"t|text", &text_path,
		"s|skips", &skip,
		"d|detals", &details);
	
	if(!index_path.length || !text_path.length)
	{
		writefln("USAGE: %s -i <index path> -t <text file> -s <skip pointer step> -d <none|docs|all>", args[0]);
		return;
	}


	if(!exists(index_path))
		mkdirRecurse(index_path);

	File index = File(index_path ~ "/index", "rb");
	File dictionary = File(index_path ~ "/dictionary", "r");

	int[][dstring] dict;
	int[int][dstring] skips;
	int[int] start_of;

	auto starttime = MonoTime.currTime();

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
		foreach(i, doc; d)
		{
			start_of[doc.id] = doc.pos;
			dict[word] ~= doc.id;

			// create skip pointers
			if(skip > 0 && i % skip == 0 && i + skip < d.length)
				skips[word][to!int(i)] = d[i + skip].id;
		}
	}

	auto endtime = MonoTime.currTime();
	auto delta = endtime - starttime;
	writefln("Index read in %s ms", delta.total!"msecs");
	
	QueryParser qp;
	qp.skip = skip;

	foreach(dstring line; lines(stdin))
	{
		auto st = MonoTime.currTime();
		int[] result = qp.process(line, dict, skips, to!int(start_of.length));
		auto dq = MonoTime.currTime() - st;
		
		int fake_res = 0;
		if(!result.length)
			writeln("Nothing found!");
		
		else final switch(details)
		{
			case Details.none:
				break;

			case Details.docs:
				writeln(result);
				break;

			case Details.all:
				foreach(doc; result)
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
				break;
		}

		writefln("Query processed in %s ms with %s results (%s comparsions)", dq.total!"usecs" / float(1000), result.length - fake_res, qp.stats["last_cmp"]);
	}
}


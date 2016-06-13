import std.stdio;
import std.file;
import std.datetime;
import std.getopt;
import std.utf;
import std.conv;
import std.algorithm;
import std.string;
import std.range;

import html.dom;

import searcher;

void main(string[] args)
{
	string index_path, text_path;
	bool notext;
	getopt(args,
		"i|index", &index_path,
		"t|text", &text_path,
		"notext", &notext);
	
	if(index_path.empty || text_path.empty)
	{
		writefln("USAGE: %s -i <index path> -t <text file>", args[0]);
		return;
	}

	dstring text = toUTF32(to!string(read(text_path)));
	dstring[] docs = createDocument(to!string(text))
		             .querySelectorAll("dd")
					 .map!(a => a.text.toUTF32())().array;

	auto starttime = MonoTime.currTime();
	auto searcher = new Searcher;
	searcher.read_index(index_path);
	auto endtime = MonoTime.currTime();
	auto delta = endtime - starttime;
	writefln("Index read in %s ms", delta.total!"msecs");
	
	foreach(dstring line; lines(stdin))
	{
		auto st = MonoTime.currTime();
		int[] result = searcher.process(line, to!int(docs.length));
		auto dq = MonoTime.currTime() - st;
		
		if(!result.length)
			writeln("Nothing found!");
		else if(notext)
			writeln(result);
		else foreach(doc; result)
		{
			writefln("Document %s: %s", doc, docs[doc]);
			writeln("-----------------");
		}

		writefln("Query processed in %s ms with %s results", dq.total!"usecs" / float(1000), result.length);
	}
}


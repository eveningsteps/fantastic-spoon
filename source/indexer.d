module indexer;


import std.file;
import std.container;
import std.string;
import std.utf;
import std.conv;
import std.stdio;
import std.algorithm;
import std.array;
import std.range;

import html.dom;


struct Posting
{
	int doc_id, pos;
}


class Indexer(S)
{
	static S stemmer;
	static dstring punct = ".,?!;:\"\'()-";

	Posting[][dstring] index;
	double[string] stats;


	dstring normalize(in dstring text)
	{
		return stemmer.stem(text.strip()).translate(null, punct).toLower();
	}

	void build_index(dstring text)
	{
		auto document = createDocument(to!string(text));
		auto docs = document.querySelectorAll("dd");
		
		foreach(i, doc; docs.enumerate())
		{
			parse_doc(to!int(i), toUTF32(doc.text));
			++stats["docs"];
		}
		stats["terms"] = index.length;
	}

	void parse_doc(int doc_id, in dstring doc)
	{
		auto words = doc.split(" ");
		foreach(pos, word; words)
		{
			word = normalize(word);
			if(!word.empty)
			{
				if(word in index)
				{
					++stats["tokens"];
					stats["tokens_length"] += word.length;
				
				} else
				{
					++stats["terms"];
					stats["terms_length"] += word.length;
				}

				index[word] ~= Posting(doc_id, to!int(pos));
			}
		}
	}

	void save_index(string path)
	{
		if(!exists(path))
			mkdirRecurse(path);

		File index_file = File(path ~ "/index", "w");
		foreach(term; index.byKey())
			index_file.writefln("%s\t%s", term, index[term].map!(a => format("%s %s", a.doc_id, a.pos)).join(" "));
	}
}


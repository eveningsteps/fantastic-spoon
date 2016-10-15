import std.file;
import std.container;
import std.string;
import std.utf;
import std.conv;
import std.stdio;

struct IndexerDoc
{
	int id, pos;
}

class Indexer(S)
{
	IndexerDoc[][dstring] index;
	void build_index(dstring text)
	{
		S stemmer;

		int token_id, doc_id;
		auto delimiters = redBlackTree!dchar([' ', '.', ',', '"', '\'', '(', ')', '!', '?', ':', ';', '\n', '-']);
		
		dstring word, prev_word;
		int cur_token_start, cur_doc_start, prev_word_start;
		bool in_token = false;
		
		for(int j = 0; j < text.length; ++j)
		{
			dchar c = text[j];

			// skip all tags, increment doc_id on </dd
			if(c == '<')
			{
				dstring tag;
				while(text[j] != '>')
					tag ~= text[j++];
				if(tag == "</dd")
				{
					++doc_id;
					cur_doc_start = j + 1;
				}

				continue;
			}

			// convert token to term and add to dictionary
			if(c == ' ' && !(word is null))
			{
				word = toLower(stemmer.stem(word));
				
				bool first_occ = !(word in index);
				bool next_occ = !first_occ && (index[word][$ - 1].id != doc_id);
				
				if(first_occ || next_occ)
				    index[word] ~= IndexerDoc(doc_id, cur_doc_start);

				++token_id;
				
				if(!(prev_word is null))
				{
				    dstring bigram = prev_word ~ "_" ~ word;
				    first_occ = !(bigram in index);
				    next_occ = !first_occ && (index[bigram][$ - 1].id != doc_id);

				    if(first_occ || next_occ)
					index[bigram] ~= IndexerDoc(doc_id, cur_doc_start);

				    ++token_id;
				}

				prev_word = word.dup;
				prev_word_start = cur_token_start;
				word = null;
				in_token = false;

				continue;
			}

			// extend current token
			if(!(c in delimiters))
			{
				if(!in_token)
				{
					cur_token_start = j;
					in_token = true;
				}
				word ~= c;
			}
		}
	}


	void save_index(string path)
	{
		if(!exists(path))
			mkdirRecurse(path);

		File index_file = File(path ~ "/index", "wb");
		File dict_file = File(path ~ "/dictionary", "w");

		int pos = 0;
		dict_file.writeln(to!int(index.length));
		foreach(term; index.byKey())
		{
			dict_file.writefln("%s %s %s", term, to!int(index[term].length), pos);
			
			int d = to!int(index[term].length);
			index_file.rawWrite((&d)[0 .. 1]);
			index_file.rawWrite(index[term]);

			pos += int.sizeof + index[term].length * IndexerDoc.sizeof;
		}
	}
}


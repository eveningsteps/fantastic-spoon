import std.algorithm;
import std.conv;
import std.stdio;
import std.file;
import std.container;
import std.datetime;
import std.string;
import std.getopt;

struct Doc
{
	int id, pos;
}

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

	if(!exists(index_path))
		mkdirRecurse(index_path);

	File index = File(index_path ~ "/index", "wb");
	File dictionary = File(index_path ~ "/dictionary", "w");

	int token_id, term_id, doc_id;
	long token_len, term_len;
	auto delimiters = redBlackTree!dchar([' ', '.', ',', '"', '\'', '(', ')', '!', '?', ':', ';', '\n', '-']);
	
	Doc[][string] dict;

	/*
	
	dictionary structure:
		word -> position in index

	index structure:
		number of documents, then
			for each document, its ID and position

	*/

	auto starttime = MonoTime.currTime();

	string text = to!string(read(text_path));
	string word = null;
	int cur_token_start = 0, cur_doc_start = 0;
	bool in_token = false;
	
	for(int j = 0; j < text.length; ++j)
	{
		char c = text[j];

		// skip all tags, increment doc_id on </dd
		if(c == '<')
		{
			string tag;
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
			word = toLower(word);
			
			if(!(word in dict) || word in dict && dict[word][$ - 1].id != doc_id)
				dict[word] ~= Doc(doc_id, cur_doc_start);

			++token_id;
			token_len += word.length;

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

	term_id = to!int(dict.length);

	int pos = 0;
	dictionary.writeln(term_id);
	foreach(term; dict.byKey())
	{
		term_len += term.length;
		dictionary.writefln("%s %s %s", term, to!int(dict[term].length), pos);
		
		int d = to!int(dict[term].length);
		index.rawWrite((&d)[0 .. 1]);
		index.rawWrite(dict[term]);

		pos += int.sizeof + dict[term].length * Doc.sizeof;
	}

	auto endttime = MonoTime.currTime();
	auto delta = endttime - starttime;
	writefln("Execution time: %s ms", delta.total!"msecs");
	writefln("Tokens: %s (average length: %s)", token_id, token_len / to!double(token_id));
	writefln("Terms: %s (average length: %s)", term_id, term_len / to!double(term_id));
	writefln("Read %s paragraphs of text", doc_id);
}


import std.conv;
import std.stdio;
import std.file;
import std.datetime;
import std.string;
import std.getopt;
import std.utf;
import std.typecons;
import std.utf;

import arsd.dom;

void main(string[] args)
{
	string input_path, output_path;
	bool notext;
	getopt(args,
	    "i|input",  &input_path,
	    "o|output", &output_path
        );

	if(!input_path.length || !output_path.length)
	{
		writefln("USAGE: %s -i <input file> -o <output file>", args[0]);
		return;
	}

	string raw_text = to!string(read(input_path));
        auto document = new Document(raw_text);
        auto docs = document.querySelectorAll("dd");
        
        dchar[dchar]dummy;

	File output = File(output_path, "w");
        foreach(i; 0 .. docs.length)
        {
            dstring doc = toUTF32(htmlEntitiesDecode(docs[i].innerText.strip()));
            doc = translate(doc, dummy, "\n\r");
            if(doc.length == 0)
                continue;
            output.writefln("%s\t%s", i, doc);
        }
}


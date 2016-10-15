import std.stdio;
import std.file;
import std.datetime;
import std.array;
import std.algorithm;
import std.utf;
import std.conv;
import std.string;

void main(string[] args)
{
    string punct = "-,.?!;:\"\'";
    dchar[dchar] dummy;
    
    auto log = File("./log", "w");
    foreach(dstring line; lines(stdin))
    {
        line = line.strip();
        if(line.length == 0)
            continue;

        log.writeln(line);
        auto l = line.split("\t");
        int doc_id = to!int(l[0].strip());
        dstring doc = l[1];
        foreach(token; doc.split())
        {
            dstring term = toLower(translate(token, dummy, punct));
            if(!(term.length == 0))
            {
                writefln("%s\t%s", term, doc_id);
            }
        }
    }
}


import std.stdio;
import std.array;
import std.string;
import std.conv;
import std.algorithm;

void main(string[] args)
{
    int[][dstring] dict;
    foreach(dstring line; lines(stdin))
    {
        auto l = line.split("\t");
        dstring term = l[0];
        int doc_id = to!int(l[1].strip());

        dict[term] ~= doc_id;
    }

    foreach(token; dict.byKey())
    {
        int[] arr = dict[token];
        sort(arr);
        writefln("%s\t%(%s %)", token, uniq(arr));
    }
}


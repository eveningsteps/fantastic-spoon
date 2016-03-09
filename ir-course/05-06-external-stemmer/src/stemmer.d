import std.stdio;
import std.string;

import wrapper;

void main()
{
	StemmerWrapper swr;
	foreach(dstring line; lines(stdin))
	{
		writeln(swr.stem(strip(line)));
	}
}


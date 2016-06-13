import std.string;
import std.utf;

extern (C++)
{
	dchar *stem_cpp(dchar *word);
}

extern (C)
{
	size_t wcslen(dchar *word);
}

struct StemmerWrapper
{
	dstring stem(in dstring word)
	{
		auto res = stem_cpp(toUTFz!(dchar *)(word));
		return res[0 .. wcslen(res)].idup;
	}
}


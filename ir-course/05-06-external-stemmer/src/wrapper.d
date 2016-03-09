import std.string;
import std.utf;

extern (C++)
{
	dchar *stem_cpp(dchar *word);
}

struct StemmerWrapper
{
	size_t strlen(in dchar *s)
	{
		size_t pos = 0;
		dchar zero = '\0';
		while(s[pos++] != zero){}
		return pos;
	}
	
	dstring stem(in dstring word)
	{
		auto res = stem_cpp(toUTFz!(dchar *)(word));
		return res[0 .. strlen(res)].idup;
	}
}


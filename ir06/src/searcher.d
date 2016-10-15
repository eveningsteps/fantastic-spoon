import std.algorithm;
import std.conv;
import std.container;
import std.string;
import std.stdio;
import std.typecons;

alias Entry = Tuple!(int, "id", int[], "occ");

struct QueryParser
{
	dstring[] parse_query(in dstring q)
	{
		return q.split();
	}

	int[] evaluate_query(dstring[] tokens, Entry[][dstring] dict)
	{
		if(!tokens.length)
			return [];

		Entry[] r;

		for(int i = 0; i < tokens.length; ++i)
		{
			dstring t = tokens[i];
			bool skip = (t[0] == '/');

			int d = skip? to!int(t[1 .. $]) : 1;
			int j = skip? i + 1 : i;

			if(j < tokens.length)
			{
				Entry[] a = dict.get(tokens[j], []);
				r = apply_and(r, a, d);
			}
			i += to!int(skip);
		}

		int[] res;
		foreach(e; r)
			res ~= e.id;
		return res;
	}


	Entry[] apply_and(Entry[] a, Entry[] b, int dist)
	{
		if(a.length == 0)
			return b;

		Entry[] ra, rb;

		Entry[] res;
		foreach(e1; a)
		{
			foreach(e2; b)
			{
				if(e1.id == e2.id)
				{
					foreach(e1_occ; e1.occ)
					{
						foreach(e2_occ; e2.occ)
						{
							if (e2_occ - e1_occ <= dist)
							{
								if(res.length == 0 || res[$ - 1].id != e1.id)
									res ~= Entry(e1.id, []);
								res[$ - 1].occ ~= e1_occ;
							}
						}
					}
				}
			}
		}

		return res;
	}


	int[] process(dstring line, Entry[][dstring] dict)
	{
		return evaluate_query(parse_query(line), dict);
	}
}


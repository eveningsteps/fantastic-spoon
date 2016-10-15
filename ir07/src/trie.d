import std.string;
import std.algorithm;
import std.conv;
import std.stdio;

/* The trie implementation is the courtesy of
   Dmitry Ilvokhin: https://github.com/r3t/master-term2-information-retrieval (make_trie.py)
 */

class Trie
{
    int[dchar][] nodes;

public:

    this()
    {
        nodes.length = 1;
    }

    void add(in dstring key)
    {
        int cur = 0;
        foreach(ch; key)
        {
            if(ch !in nodes[cur])
            {
                nodes[cur][ch] = to!int(nodes.length);
                ++nodes.length;
            }
            cur = nodes[cur][ch];
        }
    }

    dstring[] find_all_suffixes(int pos, in dstring prefix)
    {
        auto to = nodes[pos];
        if(to.keys.empty)
            return [prefix[0 .. $-1].idup];

        dstring[] res = [];
        foreach(ch; to.byKey())
        {
            dstring[] cur = find_all_suffixes(to[ch], prefix ~ ch);
            res ~= cur;
        }

        return res;
    }

    dstring[] find(in dstring key)
    {
        int cur = 0;
        foreach(ch; key)
        {
            auto node = nodes[cur];
            if(!(ch in node))
                return [];
            cur = node[ch];
        }

        return find_all_suffixes(cur, key);
    }
}


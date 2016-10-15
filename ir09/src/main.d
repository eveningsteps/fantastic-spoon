import std.conv;
import std.stdio;
import std.file;
import std.datetime;
import std.string;
import std.getopt;
import std.utf;
import std.typecons;

/* The compression algorithm implementation is the courtesy of
   Dmitry Ilvokhin: https://github.com/r3t/master-term2-information-retrieval (index_compression/main.c)

   Attempting to meet the deadline, I took the aforementioned piece of code and simply ported it to D.
   I very much regret this, as I hadn't learned a single thing from it.
 */

struct SimplePosting
{
    int doc_id, freq;
}

struct Posting
{
    int id;
    int[] docs;
}

struct CompressedPosting
{
    int id;
    char[] docs;
}


void rewrite_index(in string src_path, in string dst_path)
{
    File src_i = File(src_path ~ "/index", "rb"),
         src_d = File(src_path ~ "/dictionary", "r"),
         dst   = File(dst_path, "wb");

    int n;
    src_d.readf(" %s", &n);
    foreach(id; 0 .. n)
    {
        string w;
        int pos, freq;
        src_d.readf(" %s %s %s", &w, &freq, &pos);
        dstring word = toUTF32(w);

        int doc_cnt;
        src_i.rawRead((&doc_cnt)[0 .. 1]);
        SimplePosting[] sp = new SimplePosting[doc_cnt];
        src_i.rawRead(sp);

        Posting p = Posting(to!int(id), []);
        foreach(s; sp)
            p.docs ~= s.doc_id;

        // write posting
        dst.rawWrite([p.id, to!int(p.docs.length)]);
        dst.rawWrite(p.docs);
    }
}


void compress(in int[] idocs, out char[] odocs)
{
    int recs = 0;
    int[] ds = new int[idocs.length];
    ds[0] = idocs[0];
    foreach(i; 1 .. idocs.length)
        ds[i] = idocs[i] - idocs[i-1];

    foreach(delta; ds)
    {
        if(delta == 0)
        {
            odocs ~= 0;
            ++recs;
            continue;
        }

        while(delta)
        {
            char last_bits = (((1U << 8) - 1) & delta) | (1U << 7);
            odocs ~= last_bits;
            delta >>= 7;
            ++recs;
        }
        odocs[recs - 1] &= ~(1U << 7);
    }
}


void compress_index(in string src_path, in string dst_path)
{
    File src_i = File(src_path ~ "/index", "rb"),
         src_d = File(src_path ~ "/dictionary", "r"),
         dst   = File(dst_path, "wb");

    int n;
    src_d.readf(" %s", &n);
    foreach(id; 0 .. n)
    {
        string w;
        int pos, freq;
        src_d.readf(" %s %s %s", &w, &freq, &pos);
        dstring word = toUTF32(w);

        int doc_cnt;
        src_i.rawRead((&doc_cnt)[0 .. 1]);
        SimplePosting[] sp = new SimplePosting[doc_cnt];
        src_i.rawRead(sp);

        Posting p = Posting(to!int(id), []);
        foreach(s; sp)
            p.docs ~= s.doc_id;
        
        CompressedPosting cp = CompressedPosting(to!int(id), []);
        compress(p.docs, cp.docs);

        // write posting
        dst.rawWrite([cp.id, to!int(cp.docs.length)]);
        dst.rawWrite(cp.docs);
    }
}


void decompress_index(in string src_path, in string dst_path)
{
    File src = File(src_path, "rb"),
         dst = File(dst_path, "wb");

    CompressedPosting cp;
    while(src.rawRead((&(cp.id))[0 .. 1]).length > 0)
    {
        int prev_id, doc_cnt;
        int sz;
        src.rawRead((&sz)[0 .. 1]);
        cp.docs.length = sz;
        src.rawRead(cp.docs);

        int[] docs = new int[sz];
        for(int i = 0; i < cp.docs.length; )
        {
            int delta, shift = 1;
            uint last_bits = ((1U << 8) - 1) & cp.docs[i];

            int cont = last_bits & (1U << 7);
            last_bits &= ~(1U << 7);
            while(cont)
            {
                delta |= last_bits;
                last_bits = ((1U << 8) - 1) & cp.docs[++i];
                cont = last_bits & (1U << 7);
                last_bits = ((last_bits & ~ (1U << 7)) << 7 * shift);
                ++shift;
            }

            delta |= last_bits;
            prev_id += delta;
            docs[doc_cnt++] = prev_id;
            ++i;
        }

        dst.writef("%s %s", cp.id, cp.docs.length);
        dst.writefln(" %(%s %)", docs[0 .. doc_cnt]);
    }
}

void main(string[] args)
{
	string from, to, action;
        void handler(in string option)
        {
            final switch(option)
            {
                case "simple":
                    rewrite_index(from, to);
                    break;
                case "compress":
                    compress_index(from, to);
                    break;
                case "decompress":
                    decompress_index(from, to);
                    break;
            }
        }
        getopt(args,
            "f",            &from,
            "t",            &to,
            "simple",       &handler,
            "compress",     &handler,
            "decompress",   &handler);

	if(!from.length || !to.length)
	{
		writefln("USAGE: %s --simple|compress|decompress -f <path to index> -t <path to compressed index>", args[0]);
		return;
	}
}


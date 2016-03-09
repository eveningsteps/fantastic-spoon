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


struct QueryParser
{
	struct Token
	{
		string t;
		
		bool is_op;
		int arity;
		int priority() const @property
		{
			switch(t)
			{
				case "or":
					return 1;
				case "and":
					return 2;
				case "not":
					return 3;
				default:
					return 0;
			}
		}	
	}


	Token[] parse_query(in string q)
	{
		Token[] output, stack;
		string[] words = q.split();
		
		foreach(word; words)
		{
			switch(word)
			{
				case "and":
				case "or":
				case "not":
					Token op = { t: word, is_op: true, arity: (word == "not"? 1 : 2)};
					while(stack.length && stack[$ - 1].is_op && (op.priority <= stack[$ - 1].priority))
					{
						if(op.t != stack[$ - 1].t)
							output ~= stack[$ - 1];
						else
							op.arity += (stack[$ - 1].arity - 1);
						--stack.length;
					}

					stack ~= op;
					break;

				case "(":
					Token op = {t: word, is_op: false };
					stack ~= op;
					break;

				case ")":
					bool found_lp = false;
					while(stack.length && !found_lp)
					{
						found_lp = (stack[$ - 1].t == "(");
						if(!found_lp)
							output ~= stack[$ - 1];
						--stack.length;
					}

					if(!found_lp)
						throw new Exception("Mismatched parenthesis detected");
					break;

				default:
					Token t = { t: word, is_op: false };
					output ~= t;
					break;
			}
		}

		foreach(i; 0 .. stack.length)
			output ~= stack[$ - 1 - i];
		
		if(output.length > 1 && !output[$ - 1].is_op)
		{
			Token fin = {t: "and", is_op: true, arity: to!int(output.length)};
			output ~= fin;
		}
		return output;
	}

	
	int[] evaluate_query(Token[] tokens, int[][string] dict, int doc_count)
	{
		if(!tokens.length)
			return [];
		
		int[][] stack;

		foreach(token; tokens)
		{
			if(!token.is_op)
				stack ~= dict.get(token.t, []);
			else
			{
				if(token.arity > stack.length)
					throw new Exception("Not enough arguments for operator " ~ token.t);

				auto res = evaluate(stack[$ - token.arity .. $], token, doc_count);
				stack.length -= token.arity;
				stack ~= res;
			}
		}
		
		return stack[0];
	}


	int[] evaluate(int[][] slice, Token op, int doc_count)
	{
		final switch(op.t)
		{
			case "and":
				return apply_and(slice);
				break;

			case "or":
				return apply_or(slice);
				break;

			case "not":
				return apply_not(slice, doc_count);
				break;
		}
		return [];
	}


	int[] apply_and(int[][] slice)
	{
		sort!((a, b) => a.length < b.length) (slice);
		return reduce!((a, b) => std.array.array(setIntersection(a, b))) (slice);
	}

	
	int[] apply_or(int[][] slice)
	{
		return std.array.array(uniq(reduce!((a, b) => std.array.array(setUnion(a, b))) (slice)));
	}

	
	int[] apply_not(int[][] slice, int doc_count)
	{
		int[] rr = [];
		int cur_idx = 0;
		
		foreach(i; 0 .. doc_count)
		{
			if(cur_idx < slice[0].length && i == slice[0][cur_idx])
				++cur_idx;
			else
				rr ~= i;
		}

		return rr;
	}

	
	int[] process(string line, int[][string] dict, int doc_count)
	{
		return evaluate_query(parse_query(line), dict, doc_count);
	}
}


void main(string[] args)
{
	string index_path, text_path;
	bool notext;
	getopt(args,
		"i|index", &index_path,
		"t|text", &text_path,
		"notext", &notext);
	
	if(!index_path.length || !text_path.length)
	{
		writefln("USAGE: %s -i <index path> -t <text file>", args[0]);
		return;
	}


	if(!exists(index_path))
		mkdirRecurse(index_path);

	File index = File(index_path ~ "/index", "rb");
	File dictionary = File(index_path ~ "/dictionary", "r");

	int[][string] dict;
	int[int] start_of;

	auto starttime = MonoTime.currTime();

	string text = to!string(read(text_path));
	int wc;

	dictionary.readf(" %s", &wc);
	foreach(u; 0 .. wc)
	{
		string word;
		int pos, freq;
		dictionary.readf(" %s %s %s", &word, &freq, &pos);

		int dc;
		index.rawRead((&dc)[0 .. 1]);
		Doc[] d = new Doc[dc];

		index.rawRead(d);
		foreach(doc; d)
		{
			start_of[doc.id] = doc.pos;
			dict[word] ~= doc.id;
		}
	}

	auto endtime = MonoTime.currTime();
	auto delta = endtime - starttime;
	writefln("Index read in %s ms", delta.total!"msecs");
	
	QueryParser qp;
	foreach(string line; lines(stdin))
	{
		auto st = MonoTime.currTime();
		int[] result = qp.process(line, dict, to!int(start_of.length));
		auto dq = MonoTime.currTime() - st;
		
		int fake_res = 0;
		if(!result.length)
			writeln("Nothing found!");
		else if(notext)
			writeln(result);
		else foreach(doc; result)
		{
			if(!(doc in start_of))
			{
				++fake_res;
				continue;
			}
			
			int cap = start_of.get(doc + 1, to!int(text.length) - 1);
			writefln("Document %s: %s", doc, text[start_of[doc] .. cap]);
			writeln("-----------------");
		}

		writefln("Query processed in %s ms with %s results", dq.total!"usecs" / float(1000), result.length - fake_res);
	}
}


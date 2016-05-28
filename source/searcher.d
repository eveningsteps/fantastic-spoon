module searcher;

import std.conv;
import std.container;
import std.string;
import std.array;
import std.range;
import std.algorithm;
import std.file;
import std.stdio;


struct Posting
{
	int doc_id, pos;
}


struct Searcher
{
	struct Token
	{
		dstring t;

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
	
	Posting[][dstring] index;


	void read_index(in string path)
	{
		File index_file = File(path ~ "/index", "r");
		foreach(dstring line; lines(index_file))
		{
			auto l = line.split("\t");
			auto p = l[1].split().map!(a => to!int(a))().array;
			foreach(x; zip(stride(p[0 .. $], 2), stride(p[1 .. $], 2)))
				index[l[0]] ~= searcher.Posting(x[0], x[1]);
		}
	}


	Token[] parse_query(in dstring q)
	{
		Token[] output, stack;
		dstring[] words = q.split();
		
		foreach(word; words)
		{
			switch(word)
			{
				case "and":
				case "or":
				case "not":
					Token op = { t: word, is_op: true, arity: (word == "not"? 1 : 2)};
					while(!stack.empty && stack[$ - 1].is_op && (op.priority <= stack[$ - 1].priority))
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
					while(!stack.empty && !found_lp)
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

	
	int[] evaluate_query(Token[] tokens, int doc_count)
	{
		if(!tokens.length)
			return [];
		
		int[][] stack;
		foreach(token; tokens)
		{
			if(!token.is_op)
			{
				auto postings = index.get(token.t, null);
				if(postings)
				{
					auto tmp = postings.map!(a => a.doc_id)().array;
					stack ~= tmp;
				} else
					stack ~= (int[]).init;

			} else
			{
				if(token.arity > stack.length)
					throw new Exception("Not enough arguments for operator " ~ to!string(token.t));

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

			case "or":
				return apply_or(slice);

			case "not":
				return apply_not(slice, doc_count);
		}
	}


	int[] apply_and(int[][] slice)
	{
		sort!((a, b) => a.length < b.length) (slice);
		return reduce!((a, b) => setIntersection(a, b).array) (slice);
	}

	
	int[] apply_or(int[][] slice)
	{
		return uniq(reduce!((a, b) => setUnion(a, b).array) (slice)).array;
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

	
	int[] process(dstring line, int doc_count)
	{
		return evaluate_query(parse_query(line), doc_count);
	}
}


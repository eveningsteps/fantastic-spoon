import std.algorithm;
import std.conv;
import std.stdio;
import std.file;
import std.container;
import std.datetime;
import std.string;
import std.getopt;
import std.utf;
import std.math;
import std.array;

struct Doc
{
	int id, pos;
}


struct QueryParser
{
	double[string] stats;
	int skip;

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

	
	int[] evaluate_query(Token[] tokens, int[][dstring] dict, int[int][dstring] skips, int doc_count)
	{
		if(!tokens.length)
			return [];
		
		int[][] stack;
		int[int][] sk;

		foreach(token; tokens)
		{
			if(!token.is_op)
			{
				stack ~= dict.get(token.t, []);
				sk ~= skips.get(token.t, (int[int]).init);
				
			} else
			{
				if(token.arity > stack.length)
					throw new Exception("Not enough arguments for operator " ~ to!string(token.t));

				auto res = evaluate(stack[$ - token.arity .. $], token, sk[$ - token.arity .. $], doc_count);
				stack.length -= token.arity;
				sk.length -= token.arity;

				stack ~= res;
				sk ~= [];
			}
		}
		
		return stack[0];
	}


	int[] evaluate(int[][] slice, Token op, int[int][] skips, int doc_count)
	{
		final switch(op.t)
		{
			case "and":
				//return apply_and(slice);
				return apply_and_with_skips(slice, skips);

			case "or":
				return apply_or(slice);

			case "not":
				return apply_not(slice, doc_count);
		}
	}


	int[] apply_and(int[][] slice)
	{
		sort!((a, b) => a.length < b.length) (slice);
		return reduce!((a, b) => std.array.array(setIntersection(a, b))) (slice);
	}
	
	
	int[] apply_and_naive(int[][] slice)
	{
		int[] res = slice[0].dup;
		for(int i = 1; i < slice.length; ++i)
		{
			int[] tmp = [], p2 = slice[i];
			int j = 0, k = 0;

			while(j < res.length && k < p2.length)
			{
				if(res[j] < 0)
					++j;
				
				else if(p2[k] < 0)
					++k;

				else if(res[j] < p2[k])
				{
					++j;
					++stats["last_cmp"];
				
				} else if(p2[k] < res[j])
				{
					++k;
					++stats["last_cmp"];
				
				} else
				{
					tmp ~= res[j];
					++j, ++k;
					++stats["last_cmp"];
				}

			}

			res = tmp.dup;
		}

		return res;
	}


	int[] apply_and_with_skips(int[][] slice, int[int][] skips)
	{
		int[] p1 = slice[0].dup;
		int[int] skips_p1 = skips[0].dup;

		for(int i = 1; i < slice.length; ++i)
		{
			int[] tmp = [], p2 = slice[i];
			int[int] skips_p2 = skips[i];

			int j = 0, k = 0;

			while(j < p1.length && k < p2.length)
			{
				if(p1[j] == p2[k])
				{
					tmp ~= p1[j];
					++j, ++k, ++stats["last_cmp"];
					continue;

				}
				
				bool p1_less = (j in skips_p1 && skips_p1[j] <= p2[k]),
				     p2_less = (k in skips_p2 && skips_p2[k] <= p1[j]);
				
				++stats["last_cmp"];
				if(p1[j] < p2[k])
				{
					if(p1_less)
					{
						while(p1_less)
						{
							j += skip;
							p1_less = (j in skips_p1 && skips_p1[j] <= p2[k]);
							++stats["last_cmp"];
						}
					} else
						++j;
				
				} else
				{
					if(p2_less)
					{
						while(p2_less)
						{
							k += skip;
					     	p2_less = (k in skips_p2 && skips_p2[k] <= p1[j]);
							++stats["last_cmp"];
						}
					} else
						++k;
				}
			}

			p1 = tmp.dup;
			skips_p1 = (int[int]).init;
		}

		return p1;
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

	
	int[] process(dstring line, int[][dstring] dict, int[int][dstring] skips, int doc_count)
	{
		stats["last_cmp"] = 0;
		return evaluate_query(parse_query(line), dict, skips, doc_count);
	}
}


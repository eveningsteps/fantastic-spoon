import std.algorithm;
import std.conv;
import std.container;
import std.string;
import std.stdio;
import std.array;

import trie;

struct SearcherDoc
{
	int id, pos;
}

struct Result
{
	int[] docs;
	dstring[] terms;
}

struct QueryParser
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


	Token[] parse_query(in dstring q, out dstring[] matches, Trie[] tries)
	{
		Token[] output, stack;
		dstring[] words = q.split();

		auto trie = tries[0], rev_trie = tries[1];
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
					int idx = to!int(word.indexOf("*"));
					if(idx != -1)
					{
						dstring[] cur_matches = [];
						if(idx == 0)
						{
							auto tail = word[1 .. $].dup;
							reverse(tail);
							cur_matches = rev_trie.find(to!dstring(tail));
							foreach(ref m; cur_matches)
							{
								auto mm = m.dup;
								reverse(mm);
								m = to!dstring(mm);
							}

						} else if(idx == word.length - 1)
						{
							cur_matches = trie.find(word[0 .. $-1]);

						} else
						{
							dstring[] sp = word.split("*");
							auto head = sp[0];
							auto tail = sp[1].dup;
							reverse(tail);

							dstring[] matches_f = trie.find(head);
							dstring[] matches_b = rev_trie.find(to!dstring(tail));
							foreach(ref m; matches_b)
							{
								auto mm = m.dup;
								reverse(mm);
								m = to!dstring(mm);
							}

							sort(matches_f), sort(matches_b);
							cur_matches = std.array.array(setIntersection(matches_f, matches_b));
						}

						matches ~= cur_matches;
						if(!cur_matches.empty)
						{
							foreach(m; matches)
							{
								Token t = { t: m, is_op: false };
								output ~= t;
							}

							Token fin_or = { t: "or", is_op: true, arity: to!int(matches.length) };
							output ~= fin_or;
						}

					} else
					{
						Token t = { t: word, is_op: false };
						output ~= t;
					}
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


	int[] evaluate_query(Token[] tokens, int[][dstring] dict, int doc_count, Trie[] tries)
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


	Result process(dstring line, int[][dstring] dict, int doc_count, Trie[] tries)
	{
		Result r;
		r.docs = evaluate_query(parse_query(line, r.terms, tries), dict, doc_count, tries);
		return r;
	}
}


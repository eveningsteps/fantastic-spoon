import std.algorithm;
import std.conv;
import std.container;
import std.string;


struct Doc
{
	int id, pos;
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

	
	int[] evaluate_query(Token[] tokens, int[][dstring] dict, int doc_count)
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

	
	int[] process(dstring line, int[][dstring] dict, int doc_count)
	{
		return evaluate_query(parse_query(line), dict, doc_count);
	}
}


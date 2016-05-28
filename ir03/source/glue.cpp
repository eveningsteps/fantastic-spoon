#include "OleanderStemmingLibrary/stemming/russian_stem.h"
#include <cstring>
#include <string>

wchar_t *stem_cpp(wchar_t *c)
{
	std::wstring word = c;
	stemming::russian_stem<> st;
	st(word);
	
	int n = word.size();
	wchar_t *res = new wchar_t[n + 1];
	wmemset(res, 0, n + 1);
	wmemcpy(res, word.c_str(), n);
	
	return res;
}


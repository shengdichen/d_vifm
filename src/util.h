#ifndef UTIL_H
#define UTIL_H

#include <stddef.h>

int match_suffix(char const *str, char const *suffix);
int match_suffixes(char const *str, char const *const *suffixes);

#endif // !UTIL_H

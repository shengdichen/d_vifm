#ifndef UTIL_H
#define UTIL_H

#include <stddef.h>

int const match_suffix(char const *const str, char const *const suffix);
int const match_suffixes(char const *const str, char const *const *suffixes,
                         size_t const n_suffixes);

#endif // !UTIL_H

#ifndef UTIL_H
#define UTIL_H

#include <linux/limits.h>
#include <stddef.h>

extern char HOME[PATH_MAX];
extern char PATH_SCRIPT_VIFM[PATH_MAX];
void _init_util(void);

void *_malloc(char const *msg, size_t len, size_t size_one);

#define LEN_SUFFIX_MAX 16
int match_suffix(char const *str, char const *suffix);
int match_suffixes(char const *str, char const *const *suffixes);

#endif // !UTIL_H

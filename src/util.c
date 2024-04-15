#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "util.h"

char HOME[PATH_MAX];
char PATH_SCRIPT_VIFM[PATH_MAX];
void _init_util(void) {
  snprintf(HOME, PATH_MAX - 1, "%s", getenv("HOME"));
  snprintf(PATH_SCRIPT_VIFM, PATH_MAX - 1, "%s%s", HOME,
           "/.config/vifm/scripts/");
}

void *_malloc(char const *const msg, size_t const len, size_t const size_one) {
  void *p = malloc(len * size_one);
  if (!p) {
    fprintf(stderr, "%s> failed malloc [length %lu]; exiting\n", msg, len);
    exit(EXIT_FAILURE);
  }
  return p;
}

int match_suffix(char const *const str, char const *const suffix) {
  if (!str || !suffix)
    return 0;

  char suffix_pad[LEN_SUFFIX_MAX + 1];
  snprintf(suffix_pad, LEN_SUFFIX_MAX, ".%s", suffix);

  size_t const len_str = strlen(str);
  size_t const len_suffix = strlen(suffix_pad);
  if (len_suffix > len_str)
    return 0;

  return !strncmp(str + len_str - len_suffix, suffix_pad, len_suffix);
}

int match_suffixes(char const *const str, char const *const *const suffixes) {
  for (char const *const *p = suffixes; *p; ++p) {
    if (match_suffix(str, *p))
      return 1;
  }
  return 0;
}

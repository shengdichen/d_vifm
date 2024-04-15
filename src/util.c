#include <stddef.h>
#include <stdio.h>
#include <string.h>

static int const LEN_SUFFIX_MAX = 16;

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

int match_suffixes(char const *const str,
                         char const *const *const suffixes) {
  for (char const *const *p = suffixes; *p; ++p) {
    if (match_suffix(str, *p))
      return 1;
  }
  return 0;
}

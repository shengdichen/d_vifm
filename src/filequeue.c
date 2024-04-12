#include "filequeue.h"
#include "util.h"

#include <linux/limits.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

FileQueue init_filequeue(int argc, char const **argv) {
  // pop first arg
  --argc;
  ++argv;

  if (!strcmp(argv[0], "--")) {
    --argc;
    ++argv;
  }

  FileQueue fq = {
      .paths = argv,
      .count = argc,
  };
  return fq;
}

FileQueue init_filequeue_length(size_t const len) {
  FileQueue fq = {
      .paths = malloc(len * sizeof(const char **)),
      .count = 0,
  };
  if (!fq.paths) {
    fprintf(stderr, "filequeue/run> failed malloc [length %lu]; exiting\n",
            len);
    exit(EXIT_FAILURE);
  }
  return fq;
}

char *const calc_paths_flat(FileQueue const *const fq) {
  size_t len = 1; // reservation for terminating zero
  for (int i = 0; i < fq->count; ++i) {
    len += 3; // 1 (leading) space & 2 surrounding (single-)quotes
    for (int j = 0; fq->paths[i][j]; ++j) {
      ++len;
      if (fq->paths[i][j] == '\'')
        len += 3; // 3 extra characters per single-quote (see below)
    }
  }
  char *paths = malloc(len);
  if (!paths) {
    fprintf(stderr,
            "filequeue/paths-flat> failed malloc [length %lu; files %d]; "
            "exiting\n",
            len, fq->count);
    exit(EXIT_FAILURE);
  }

  char *p = paths;
  char const *fpath = NULL;
  for (int i = 0; i < fq->count; ++i) {
    *p++ = ' ';
    *p++ = '\'';

    fpath = fq->paths[i];
    for (int j = 0; fpath[j]; ++j) {
      if (fpath[j] == '\'') {
        // convert |'| to |'\''|
        *p++ = '\'';
        *p++ = '\\';
        *p++ = '\'';
        *p++ = '\'';
      } else {
        *p++ = fpath[j];
      }
    }

    *p++ = '\'';
  }

  *p = '\0';
  return paths;
}

void run_exec_paths(char const *const exec, FileQueue const *const fq) {
  char *const paths = calc_paths_flat(fq);
  size_t const len = strlen(exec) + strlen(paths) + 1;
  char *const cmd = malloc(len);
  if (!cmd) {
    fprintf(stderr, "filequeue/run> failed malloc [length %lu]; exiting\n",
            len);
    exit(EXIT_FAILURE);
  }
  snprintf(cmd, len, "%s%s", exec, paths);

  // printf("exec> %s [cmd-length: %lu]\n", cmd, strlen(cmd));
  system(cmd);
  free(cmd);
  free(paths);
}

void run_script_paths(char const *const script, FileQueue const *const fq) {
  static char script_path[PATH_MAX] = "";
  snprintf(script_path, PATH_MAX - 1, "%s%s%s", getenv("HOME"),
           "/.config/vifm/scripts/", script);

  run_exec_paths(script_path, fq);
}

void run_script(char const *const script, char const *const arg) {
  static char script_path[PATH_MAX] = "";
  snprintf(script_path, PATH_MAX - 1, "%s%s%s", getenv("HOME"),
           "/.config/vifm/scripts/", script);

  size_t const len = strlen(script_path) + strlen(arg) + 2; // extra <space>
  char *const cmd = malloc(len);
  if (!cmd) {
    fprintf(stderr, "filequeue/run> failed malloc [length %lu]; exiting\n",
            len);
    exit(EXIT_FAILURE);
  }
  snprintf(cmd, len, "%s %s", script_path, arg); // behold extra <space>

  system(cmd);
  free(cmd);
}

int const match_suffixes_filequeue(FileQueue const *const fq,
                                   char const *const *suffixes,
                                   size_t const n_suffixes) {
  for (int i = 0; i < fq->count; ++i) {
    if (!match_suffixes(fq->paths[i], suffixes, n_suffixes))
      return 0;
  }
  return 1;
}

void print_filequeue(FileQueue const *const fq) {
  for (int i = 0; i < fq->count; ++i)
    printf("handler/raw> %s\n", fq->paths[i]);
}

void nvim_filequeue(FileQueue const *const fq) {
  if (fq->count)
    run_exec_paths("nvim -O --", fq);
}

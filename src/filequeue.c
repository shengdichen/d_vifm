#define _GNU_SOURCE // execvpe

#include <linux/limits.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#include "filequeue.h"
#include "util.h"

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

int FLAG_RUN_DEFAULT = 0;
int FLAG_RUN_ASYNC = 1;
int FLAG_RUN_NOWAYLAND = 2;

int FLAG_RUN_PATH_VIFM = 4;
char PATH_SCRIPT_VIFM[PATH_MAX];

void _init_path_script_vifm() {
  snprintf(PATH_SCRIPT_VIFM, PATH_MAX - 1, "%s%s", getenv("HOME"),
           "/.config/vifm/scripts/");
}

static void _execute(char const *const exec, char const *const *const args,
                     int const flags_run) {
  int wstatus;
  pid_t const pid = fork();
  if (pid < 0) {
    fprintf(stderr, "filequeue/run> failed fork; exiting\n");
  }

  if (pid == 0) {
    if (flags_run & FLAG_RUN_NOWAYLAND) {
      char const *const envs[] = {"WAYLAND_DISPLAY=", NULL};
      execvpe(exec, (char *const *)args, (char *const *)envs);
    } else {
      execvp(exec, (char *const *)args);
    }
  } else {
    int const flag_waitpid = (flags_run & FLAG_RUN_ASYNC) ? WNOHANG : 0;
    waitpid(pid, &wstatus, flag_waitpid);
  }
}

void execute_paths(char const *const target, FileQueue const *const fq,
                   int const argc, char const *const *argv,
                   int const flags_run) {
  int const len = argc + fq->count + 2;
  char const **args = malloc(len * sizeof(const char **));
  if (!args) {
    fprintf(stderr, "filequeue/run> failed malloc [length %d]; exiting\n", len);
    exit(EXIT_FAILURE);
  }

  char const **p = args;
  if (flags_run & FLAG_RUN_PATH_VIFM) {
    char cmd[PATH_MAX];
    snprintf(cmd, PATH_MAX - 1, "%s%s", PATH_SCRIPT_VIFM, target);
    *p++ = cmd;
  } else {
    *p++ = target;
  }

  for (int i = 0; i < argc; ++i) {
    *p++ = argv[i];
  }
  for (int i = 0; i < fq->count; ++i) {
    *p++ = fq->paths[i];
  }
  *p = NULL;

  _execute(target, args, flags_run);
  free(args);
}

void execute(char const *const target, int const argc, char const *const *argv,
             int const flags_run) {
  int const len = argc + 2;
  char const **args = malloc(len * sizeof(const char **));
  if (!args) {
    fprintf(stderr, "filequeue/run> failed malloc [length %d]; exiting\n", len);
    exit(EXIT_FAILURE);
  }

  char const **p = args;
  if (flags_run & FLAG_RUN_PATH_VIFM) {
    char cmd[PATH_MAX];
    snprintf(cmd, PATH_MAX - 1, "%s%s", PATH_SCRIPT_VIFM, target);
    *p++ = cmd;
  } else {
    *p++ = target;
  }
  for (int i = 0; i < argc; ++i) {
    *p++ = argv[i];
  }
  *p = NULL;

  _execute(target, args, flags_run);
  free(args);
}

int const match_suffixes_filequeue(FileQueue const *const fq,
                                   char const *const *const suffixes) {
  for (int i = 0; i < fq->count; ++i) {
    if (!match_suffixes(fq->paths[i], suffixes))
      return 0;
  }
  return 1;
}

void print_filequeue(FileQueue const *const fq) {
  for (int i = 0; i < fq->count; ++i)
    printf("handler/raw> %s\n", fq->paths[i]);
}

void nvim_filequeue(FileQueue const *const fq) {
  if (fq->count) {
    char const *const argv[] = {"-O", "--"};
    execute_paths("nvim", fq, sizeof argv / sizeof argv[0], argv,
                  FLAG_RUN_DEFAULT);
  }
}

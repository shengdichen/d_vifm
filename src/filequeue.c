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

static void *_malloc(char const *const msg, size_t const len,
                     size_t const size_one) {
  void *p = malloc(len * size_one);
  if (!p) {
    fprintf(stderr, "%s> failed malloc [length %lu]; exiting\n", msg, len);
    exit(EXIT_FAILURE);
  }
  return p;
}

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
      .paths = _malloc("filequeue/init", len, sizeof(const char **)),
      .count = 0,
  };
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

  char *paths = _malloc("filequeue/paths-flat", len, sizeof(char));
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
                     int const options) {
  int wstatus;
  pid_t const pid = fork();
  if (pid < 0) {
    fprintf(stderr, "filequeue/run> failed fork; exiting\n");
  }

  if (pid == 0) {
    if (options & FLAG_RUN_NOWAYLAND) {
      char const *const envs[] = {"WAYLAND_DISPLAY=", NULL};
      execvpe(exec, (char *const *)args, (char *const *)envs);
    } else {
      execvp(exec, (char *const *)args);
    }
  } else {
    int const flag_waitpid = (options & FLAG_RUN_ASYNC) ? WNOHANG : 0;
    waitpid(pid, &wstatus, flag_waitpid);
  }
}

static char const **_append_target(char const **p, char const *const target,
                                   int const options) {
  if (options & FLAG_RUN_PATH_VIFM) {
    char cmd[PATH_MAX];
    snprintf(cmd, PATH_MAX - 1, "%s%s", PATH_SCRIPT_VIFM, target);
    *p++ = cmd;
  } else {
    *p++ = target;
  }
  return p;
}

void execute_paths(char const *const target, FileQueue const *const fq,
                   size_t const argc, char const *const *argv,
                   int const options) {
  size_t const len = argc + fq->count + 2;
  char const **args = _malloc("filequeue/execute", len, sizeof(const char **));

  char const **p = args;
  p = _append_target(p, target, options);
  for (int i = 0; i < argc; ++i) {
    *p++ = argv[i];
  }
  for (int i = 0; i < fq->count; ++i) {
    *p++ = fq->paths[i];
  }
  *p = NULL;

  _execute(target, args, options);
  free(args);
}

void execute_paths_shell(char const *const exec, FileQueue const *const fq) {
  char *const paths = calc_paths_flat(fq);
  size_t const len = strlen(exec) + strlen(paths) + 1;
  char *const cmd = _malloc("filequeue/execute", len, sizeof(const char *));
  snprintf(cmd, len, "%s%s", exec, paths);

  system(cmd);
  free(cmd);
  free(paths);
}

void execute(char const *const target, size_t const argc,
             char const *const *argv, int const options) {
  int const len = argc + 2;
  char const **args = _malloc("filequeue/execute", len, sizeof(const char **));

  char const **p = args;
  p = _append_target(p, target, options);
  for (int i = 0; i < argc; ++i) {
    *p++ = argv[i];
  }
  *p = NULL;

  _execute(target, args, options);
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

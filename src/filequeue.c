#define _GNU_SOURCE // execvpe

#include <fcntl.h>
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
      .paths = _malloc("filequeue/init", len, sizeof(const char *)),
      .count = 0,
  };
  return fq;
}

char *calc_paths_flat(FileQueue const *const fq) {
  size_t len = 1; // reservation for terminating zero
  for (int i = 0; i < fq->count; ++i) {
    len += 3; // 1 (leading) space & 2 surrounding (single-)quotes
    for (int j = 0; fq->paths[i][j]; ++j) {
      ++len;
      if (fq->paths[i][j] == '\'')
        len += 3; // 3 extra characters per single-quote (see below)
    }
  }

  char *const paths = _malloc("filequeue/paths-flat", len, sizeof(char));
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

static void _ignore_output(void) {
  int fd = open("/dev/null", O_WRONLY);
  dup2(fd, STDOUT_FILENO);
  dup2(fd, STDERR_FILENO);
  close(fd);
}

static void _log_output(void) {
  FILE *f_stdout = fopen(PATH_EXEC_STDOUT, "a");
  FILE *f_stderr = fopen(PATH_EXEC_STDERR, "a");

  dup2(fileno(f_stdout), STDOUT_FILENO);
  dup2(fileno(f_stderr), STDERR_FILENO);

  fclose(f_stdout);
  fclose(f_stderr);
}

static void _execute(char const *const exec, char const *const *const args,
                     int const options) {
  int wstatus;
  pid_t const pid = fork();
  if (pid < 0) {
    fprintf(stderr, "filequeue/run> failed fork; exiting\n");
  }

  if (pid == 0) {
    if (options & FLAG_RUN_ASYNC) {
      if (options & FLAG_RUN_LOG_OUTPUT)
        _log_output();
      else
        _ignore_output();
    }

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

size_t _argc(char const *const *argv) {
  if (!argv)
    return 0;

  size_t argc = 0;
  while (*argv++)
    argc++;
  return argc;
}

static char const **_append_argv(char const **p,
                                 char const *const *const argv) {
  if (argv) {
    for (int i = 0; argv[i]; ++i) {
      *p++ = argv[i];
    }
  }
  return p;
}

void execute_paths(char const *const target, FileQueue const *const fq,
                   char const *const *const argv, int const options) {
  size_t const len = ARGC_MAX + fq->count + 2;
  char const **args = _malloc("filequeue/execute", len, sizeof(const char *));

  char const **p = args;
  p = _append_target(p, target, options);
  p = _append_argv(p, argv);
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
  char *const cmd = _malloc("filequeue/execute", len, sizeof(const char));
  snprintf(cmd, len, "%s%s", exec, paths);

  system(cmd);
  free(cmd);
  free(paths);
}

void execute(char const *const target, char const *const *const argv,
             int const options) {
  size_t const len = ARGC_MAX + 2;
  char const **args = _malloc("filequeue/execute", len, sizeof(const char *));

  char const **p = args;
  p = _append_target(p, target, options);
  p = _append_argv(p, argv);
  *p = NULL;

  _execute(target, args, options);
  free(args);
}

int match_suffixes_filequeue(FileQueue const *const fq,
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
    char const *const argv[] = {"-O", "--", NULL};
    execute_paths("nvim", fq, argv, FLAG_RUN_DEFAULT);
  }
}

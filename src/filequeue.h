#ifndef FILEQUEUE_H
#define FILEQUEUE_H

#include <linux/limits.h>
#include <stddef.h>

typedef struct {
  char const **paths;
  int count;
} FileQueue;

extern int FLAG_RUN_DEFAULT;
extern int FLAG_RUN_ASYNC;
extern int FLAG_RUN_NOWAYLAND;

extern int FLAG_RUN_PATH_VIFM;
extern char PATH_SCRIPT_VIFM[PATH_MAX];
void _init_path_script_vifm();

FileQueue init_filequeue(int argc, char const **argv);
FileQueue init_filequeue_length(size_t const len);

char *const calc_paths_flat(FileQueue const *const fq);
int const match_suffixes_filequeue(FileQueue const *const fq,
                                   char const *const *suffixes);

void execute_paths(char const *const target, FileQueue const *const fq,
                   int const argc, char const *const *argv, int const FLAG_RUN);
void execute(char const *const target, int const argc, char const *const *argv,
             int const flags_run);

void print_filequeue(FileQueue const *const fq);
void nvim_filequeue(FileQueue const *const fq);

#endif // !FILEQUEUE_H

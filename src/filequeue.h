#ifndef FILEQUEUE_H
#define FILEQUEUE_H

#include <stddef.h>

typedef struct {
  char const **paths;
  int count;
} FileQueue;

FileQueue init_filequeue(int argc, char const **argv);
FileQueue init_filequeue_length(size_t const len);

char *const calc_paths_flat(FileQueue const *const fq);
int const match_suffixes_filequeue(FileQueue const *const fq,
                                   char const *const *suffixes,
                                   size_t const n_suffixes);

void run_exec_paths(char const *const exec, FileQueue const *const fq);
void run_exec_paths_nohup(char const *const exec, FileQueue const *const fq,
                          int const argc, char const *const *argv);
void run_script_paths(char const *const script, FileQueue const *const fq);
void run_script(char const *const script, char const *const arg);

void print_filequeue(FileQueue const *const fq);
void nvim_filequeue(FileQueue const *const fq);

#endif // !FILEQUEUE_H

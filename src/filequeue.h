#ifndef FILEQUEUE_H
#define FILEQUEUE_H

#include <linux/limits.h>
#include <stddef.h>

typedef struct {
  char const **paths;
  size_t count;
} FileQueue;

#define ARGC_MAX 256

#define EXEC_DEFAULT 0
#define EXEC_ASYNC 1
#define EXEC_NOWAYLAND 2

#define EXEC_PATH_VIFM 4
#define EXEC_LOG_OUTPUT 8

FileQueue init_filequeue(int argc, char const **argv);
FileQueue init_filequeue_length(size_t const len);

char *calc_paths_flat(FileQueue const *fq);
int match_suffixes_filequeue(FileQueue const *fq, char const *const *suffixes);

size_t _argc(char const *const *argv);
void execute_paths(char const *target, FileQueue const *fq,
                   char const *const *argv, int options);
void execute_paths_shell(char const *exec, FileQueue const *fq);
void execute(char const *target, char const *const *argv, int options);

void print_filequeue(FileQueue const *fq);
void nvim_filequeue(FileQueue const *fq);

#endif // !FILEQUEUE_H

#include <linux/limits.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "filequeue.h"
#include "handler.h"
#include "util.h"

static int const handle_media(FileQueue const *const fq) {
  char const *const suffixes[] = {
      "flac", "wav",  "ape", "mp3",  "m4a", "m4b",

      "wma",  "ac3",  "oga", "ogg",  "ogx", "spx", "opus",

      "mkv",  "avi",  "mp4", "webm", "ts",  "m4v", "mov",

      "mpg",  "mpeg", "vob", "fli",  "flc", "flv",

      "wmv",  "dat",  "3gp", "ogv",  "m2v", "mts",

      "ra",   "rm",   "qt",  "divx", "asf", "asx",

      NULL,
  };
  if (match_suffixes_filequeue(fq, suffixes)) {
    execute_paths("mpv", fq, NULL, EXEC_ASYNC);
    return 1;
  }
  return 0;
}

static int const handle_image(FileQueue const *const fq) {
  char const *const suffixes[] = {
      "png",  "svg",   "jpg",  "jpeg",  "bmp",  "webp", "gif",  "xpm",
      "heif", "heifs", "heic", "heics", "avci", "avcs", "avif",

      NULL,
  };
  if (match_suffixes_filequeue(fq, suffixes)) {
    execute_paths("imv", fq, NULL, EXEC_ASYNC);
    return 1;
  }
  return 0;
}

static int const handle_pdf(FileQueue const *const fq) {
  char const *const suffixes[] = {"pdf", NULL};
  if (match_suffixes_filequeue(fq, suffixes)) {
    execute_paths("zathura", fq, NULL, EXEC_ASYNC);
    return 1;
  }
  return 0;
}

static int const handle_archive(FileQueue const *const fq) {
  char const *const suffixes[] = {
      "tar",

      "tbz",     "tbz2",   "tar.bz", "tar.bz2", "bz",  "bz2",

      "tar.gz",  "tgz",    "taz",    "tar.Z",   "z",   "gz",

      "tar.xz",  "tar.lz", "txz",    "tlz",     "xz",  "lz",  "lzma",

      "tar.zst", "zst",

      "7z",      "iso",

      "zip",     "apk",    "apkg",   "ear",     "jar", "war",

      "rar",

      NULL,
  };
  if (match_suffixes_filequeue(fq, suffixes)) {
    execute_paths("archive.sh", fq, NULL, EXEC_PATH_VIFM);
    return 1;
  }
  return 0;
}

static int const handle_pass(FileQueue const *const fq) {
  char path_abs[PATH_MAX];
  realpath(fq->paths[0], path_abs);
  if (strstr(path_abs, "/.password-store/")) {
    if (match_suffix(path_abs, "gpg")) {
      char const *const argv[] = {"--", path_abs, NULL};
      execute("pass.sh", argv, EXEC_PATH_VIFM);
      return 1;
    }
  }
  return 0;
}

static int const handle_misc(FileQueue const *const fq) {
  char const *const suffixes[] = {
      "xopp", "lyx",

      "odt",  "odp",  "doc",     "docx",    "xls", "xlsx", "ppt", "pptx",

      "db",   "db3",  "sqlite",  "sqlite3",

      "htm",  "html", "torrent",

      "o",    "out",

      NULL,
  };
  if (match_suffixes_filequeue(fq, suffixes)) {
    execute_paths("misc.sh", fq, NULL, EXEC_PATH_VIFM);
    return 1;
  }
  return 0;
}

static int const handle_all(FileQueue *const fq) {
  return handle_media(fq) || handle_image(fq);
}

static void handle_each(FileQueue *const fq) {
  FileQueue fq_nvim = init_filequeue_length(fq->count);

  FileQueue fq_curr = {.paths = NULL, .count = 1};
  for (int i = 0; i < fq->count; ++i) {
    fq_curr.paths = &fq->paths[i];
    if (!(handle_media(&fq_curr) || handle_image(&fq_curr) ||
          handle_pdf(&fq_curr) || handle_archive(&fq_curr) ||
          handle_pass(&fq_curr) || handle_misc(&fq_curr))) {
      fq_nvim.paths[fq_nvim.count++] = fq->paths[i];
    }
  }

  nvim_filequeue(&fq_nvim);
  free(fq_nvim.paths);
}

void handle(int const argc, char const **const argv) {
  _init_util();
  FileQueue fq = init_filequeue(argc, argv);

  if (!handle_all(&fq))
    handle_each(&fq);
}

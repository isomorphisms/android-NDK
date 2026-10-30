/* This observes the native provider's internal POSIX path boundary directly.
 * It is not a second transport or an Idric implementation. */
#define _GNU_SOURCE
#include "transport.c"

int main(void) {
    const char *temporary = getenv("TMPDIR");
    char directory[4096], body[4128], metadata[4128];
    int written = snprintf(directory, sizeof(directory), "%s/icu-path-probe-XXXXXX",
                           temporary == NULL ? "/tmp" : temporary);
    if (written < 0 || (size_t)written >= sizeof(directory) || mkdtemp(directory) == NULL) {
        perror("FAIL create private diagnostic directory");
        return 1;
    }
    printf("uid\t%lu\nprivate_directory\t%s\n", (unsigned long)geteuid(), directory);
    char ancestor[4096];
    strcpy(ancestor, directory);
    for (char *cursor = ancestor + 1; ; ++cursor) {
        if (*cursor != '/' && *cursor != '\0') continue;
        char saved = *cursor;
        *cursor = '\0';
        errno = 0;
        int readable = open(ancestor, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
        int read_error = readable < 0 ? errno : 0;
        errno = 0;
        int searchable = open(ancestor, O_PATH | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
        int search_error = searchable < 0 ? errno : 0;
        printf("ancestor\t%s\tread\t%d\t%s\tsearch\t%d\t%s\n", ancestor,
               read_error, strerror(read_error), search_error, strerror(search_error));
        if (readable >= 0) close(readable);
        if (searchable >= 0) close(searchable);
        *cursor = saved;
        if (saved == '\0') break;
    }
    snprintf(body, sizeof(body), "%s/body", directory);
    snprintf(metadata, sizeof(metadata), "%s/metadata", directory);
    int accepted = capture_paths_valid(body, metadata);
    printf("capture_paths_valid\t%d\n", accepted);
    if (rmdir(directory) != 0) { perror("FAIL remove diagnostic directory"); return 1; }
    return 0;
}

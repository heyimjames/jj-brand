/* The Dock app's executable: a real binary, built for both architectures.
 *
 * A bundle whose CFBundleExecutable is a shell script makes macOS ask for
 * Rosetta — there is no Mach-O header to read an architecture from, so
 * LaunchServices assumes x86_64. All this does is exec the script that holds
 * the actual work. */
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(void) {
    const char *home = getenv("HOME");
    if (!home) return 1;
    char path[PATH_MAX];
    snprintf(path, sizeof path, "%s/.claude/themes/terminal-app/jj-app.sh", home);
    execl("/bin/sh", "sh", path, (char *)NULL);
    return 1;
}

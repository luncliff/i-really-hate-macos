#include "interface.h"

// #include <png.h>
// #include <zlib.h>

fs::path workspace = fs::current_path();

int init(int argc, char* argv[]) {
    if (argc >= 2)
        workspace = fs::path{argv[1]};

    fprintf(stderr, "workspace: %s\n", workspace.c_str());
    return 0;
}

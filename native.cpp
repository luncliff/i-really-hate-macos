#include <filesystem>
#include <memory>

namespace fs = std::filesystem;

fs::path workspace = fs::current_path();

uint32_t init(int argc, char* argv[]) {
  if (argc >= 2)
    workspace = fs::path{argv[1]};
  fprintf(stderr, "workspace: %s\n", workspace.c_str());
  return 0;
}

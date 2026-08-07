import std/[parseopt, paths, dirs]


var
  currentPath = getCurrentDir()
  showDirs = false
  showFiles = false


iterator getDirectories(path: Path): Path =
  for kind, p in walkDir(path):
    if kind == pcDir:
      yield p

iterator getFiles(path: Path): Path =
  for kind, p in walkDir(path):
    if kind == pcFile:
      yield p


for kind, key, val in getopt():
  case kind
  of cmdEnd:
    break
  of cmdShortOption, cmdLongOption:
    case key
    of "h", "help":
      echo """
      
Usage: pd [options] [path]

Options:
  -d, --dirs    Show only directories
  -f, --files   Show only files
  -h, --help    Show this help
"""
      quit(0)
    of "d", "dirs":
      showDirs = true
    of "f", "files":
      showFiles = true
    else:
      echo "Unknown option: ", key
      quit(1)
  of cmdArgument:
    currentPath = Path(key)


if showDirs:
  for dir in getDirectories(currentPath):
    echo dir

elif showFiles:
  for file in getFiles(currentPath):
    echo file

else:
  for kind, path in walkDir(currentPath):
    echo path

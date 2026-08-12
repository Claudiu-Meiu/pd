import std/[parseopt, os, strformat, times, terminal]


type Filter = enum
  all
  dirs
  files


var
  currentPath = getCurrentDir()
  filter = all


for kind, key, val in getopt():
  case kind
  of cmdEnd: break
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
    of "d", "dirs": filter = dirs
    of "f", "files": filter = files
    else:
      echo "Unknown option: ", key
      quit(1)
  of cmdArgument: currentPath = key


proc pathInfo(path: string): FileInfo =
  result = getFileInfo(path, false)

proc formatDateTime(path: string): string =
  let dateTimeFormat = "MMM d HH:mm"
  result = local(pathInfo(path).lastWriteTime).format(dateTimeFormat)

proc formatPermissions(path: string): string =
  let permissions = pathInfo(path).permissions

  for (permission, letter) in [
    (fpUserRead, 'r'), (fpUserWrite, 'w'), (fpUserExec, 'x'),
    (fpGroupRead, 'r'), (fpGroupWrite, 'w'), (fpGroupExec, 'x'),
    (fpOthersRead, 'r'), (fpOthersWrite, 'w'), (fpOthersExec, 'x')
  ]:
    result.add(if permission in permissions: letter else: '-')

proc output() =
  for kind, path in walkDir(currentPath):
    let
      isLink = kind == pcLinkToFile or kind == pcLinkToDir
      symlinkTarget = if isLink: expandSymlink(path) else: ""

      isDir =
        kind == pcDir or
        kind == pcLinkToDir

      isFile =
        kind == pcFile or
        kind == pcLinkToFile

      shouldShow =
        case filter
        of all: true
        of dirs: isDir
        of files: isFile

    if not shouldShow: continue

    let
      extractedPathName = path.extractFilename

      pathType =
        case kind
        of pcDir: "d"
        of pcFile: "f"
        of pcLinkToFile, pcLinkToDir: "-"

      color =
        case kind
        of pcDir, pcLinkToDir: ansiForegroundColorCode(fgBlue)
        of pcFile, pcLinkToFile: ansiForegroundColorCode(fgWhite)

      coloredPathType = color & pathType & ansiResetCode
      coloredPathName = color & extractedPathName & ansiResetCode
      symlink = if isLink: " -> " & symlinkTarget else: ""

    echo fmt"{coloredPathType} {formatPermissions(path)} {pathInfo(path).size:>8} {formatDateTime(path):>16} {coloredPathName}{symlink}"


output()

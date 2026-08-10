import std/[parseopt, os, strformat, times, terminal]


var
  currentPath = getCurrentDir()
  showOnlyDirs = false
  showOnlyFiles = false


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
    of "d", "dirs": showOnlyDirs = true
    of "f", "files": showOnlyFiles = true
    else:
      echo "Unknown option: ", key
      quit(1)
  of cmdArgument: currentPath = key


iterator directories(): string =
  for kind, dirPath in walkDir(currentPath):
    if kind == pcDir: yield dirPath

iterator files(): string =
  for kind, filePath in walkDir(currentPath):
    if kind == pcFile: yield filePath


proc pathInfo(path: string): FileInfo =
  result = getFileInfo(path, false)

proc formatDateTime(path: string): string =
  let dateTimeFormat = "MMM d HH:mm"
  result = local(pathInfo(path).lastWriteTime).format(dateTimeFormat)

proc formatPermissions(path: string): string =
  let permissions = getFileInfo(path, false).permissions

  for (permission, letter) in [
    (fpUserRead, 'r'), (fpUserWrite, 'w'), (fpUserExec, 'x'),
    (fpGroupRead, 'r'), (fpGroupWrite, 'w'), (fpGroupExec, 'x'),
    (fpOthersRead, 'r'), (fpOthersWrite, 'w'), (fpOthersExec, 'x')
  ]:
    result.add(if permission in permissions: letter else: '-')


if showOnlyDirs:
  for dir in directories():
    let
      extractedDirName = dir.extractFilename
      coloredExtractedDirName = ansiForegroundColorCode(fgBlue) &
        extractedDirName & ansiResetCode
      coloredDirType = ansiForegroundColorCode(fgBlue) & "d" & ansiResetCode

    echo fmt"{coloredDirType} {formatPermissions(dir)} {pathInfo(dir).size:>8} {formatDateTime(dir):>16} {coloredExtractedDirName}"

elif showOnlyFiles:
  for file in files():
    let
      extractedFileName = file.extractFilename
      coloredExtractedFileName = ansiForegroundColorCode(fgWhite) &
          extractedFileName & ansiResetCode
      coloredFileType = ansiForegroundColorCode(fgWhite) & "f" & ansiResetCode

    echo fmt"{coloredFileType} {formatPermissions(file)} {pathInfo(file).size:>8} {formatDateTime(file):>16} {coloredExtractedFileName}"

else:
  for kind, path in walkDir(currentPath):
    let
      extractedPathName = path.extractFilename
      pathType =
        if kind == pcDir: "d"
        elif kind == pcFile: "f"
        elif kind == pcLinkToFile: "-"
        else: ""
      color =
        if kind == pcDir: ansiForegroundColorCode(fgBlue)
        elif kind == pcFile: ansiForegroundColorCode(fgWhite)
        else: ""
      coloredExtractedPathName = color & extractedPathName & ansiResetCode
      coloredPathType = color & pathType & ansiResetCode

    if kind == pcLinkToFile:
      echo fmt"{coloredPathType} {formatPermissions(path)} {pathInfo(path).size:>8} {formatDateTime(path):>16} {coloredExtractedPathName} -> {expandSymlink(path)}"
    else:
      echo fmt"{coloredPathType} {formatPermissions(path)} {pathInfo(path).size:>8} {formatDateTime(path):>16} {coloredExtractedPathName}"




import std/[parseopt, os, strformat, times, terminal]


var
  currentPath = getCurrentDir()
  showDirs = false
  showFiles = false

let dateTimeFormat = "MMM d HH:mm"


proc pathInfo(path: string): FileInfo =
  result = getFileInfo(path, false)

proc formatPermissions(path: string): string =
  let permissions = getFileInfo(path, false).permissions

  template bit(flag: FilePermission, letter: char): char =
    if flag in permissions: letter else: '-'

  result = ""
  result.add bit(fpUserRead, 'r')
  result.add bit(fpUserWrite, 'w')
  result.add bit(fpUserExec, 'x')
  result.add bit(fpGroupRead, 'r')
  result.add bit(fpGroupWrite, 'w')
  result.add bit(fpGroupExec, 'x')
  result.add bit(fpOthersRead, 'r')
  result.add bit(fpOthersWrite, 'w')
  result.add bit(fpOthersExec, 'x')


iterator directories(): string =
  for kind, dirPath in walkDir(currentPath):
    if kind == pcDir: yield dirPath

iterator files(): string =
  for kind, filePath in walkDir(currentPath):
    if kind == pcFile: yield filePath


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
    of "d", "dirs": showDirs = true
    of "f", "files": showFiles = true
    else:
      echo "Unknown option: ", key
      quit(1)
  of cmdArgument: currentPath = key


if showDirs:
  for dir in directories():
    let
      extractedDirName = dir.extractFilename
      dateTime = local(pathInfo(dir).lastWriteTime).format(dateTimeFormat)
      coloredExtractedDirName = ansiForegroundColorCode(fgBlue) &
        extractedDirName & ansiResetCode
      coloredDirType = ansiForegroundColorCode(fgBlue) & "D" & ansiResetCode

    echo fmt"{coloredDirType} {formatPermissions(dir)} {pathInfo(dir).size:>8} {dateTime:>16} {coloredExtractedDirName}"

elif showFiles:
  for file in files():
    let
      extractedFileName = file.extractFilename
      dateTime = local(pathInfo(file).lastWriteTime).format(dateTimeFormat)
      coloredExtractedFileName = ansiForegroundColorCode(fgWhite) &
          extractedFileName & ansiResetCode
      coloredFileType = ansiForegroundColorCode(fgWhite) & "F" & ansiResetCode

    echo fmt"{coloredFileType} {formatPermissions(file)} {pathInfo(file).size:>8} {dateTime:>16} {coloredExtractedFileName}"

else:
  for kind, path in walkDir(currentPath):
    let
      extractedPathName = path.extractFilename
      dateTime = local(pathInfo(path).lastWriteTime).format(dateTimeFormat)
      pathType =
        if kind == pcDir: "D"
        elif kind == pcFile: "F"
        elif symlinkExists(path): "-"
        else: ""
      color =
        if kind == pcDir: ansiForegroundColorCode(fgBlue)
        elif kind == pcFile: ansiForegroundColorCode(fgWhite)
        else: ""
      coloredExtractedPathName = color & extractedPathName & ansiResetCode
      coloredPathType = color & pathType & ansiResetCode

    if symlinkExists(path):
      echo fmt"{coloredPathType} {formatPermissions(path)} {pathInfo(path).size:>8} {dateTime:>16} {coloredExtractedPathName} -> {expandSymlink(path)}"
    else:
      echo fmt"{coloredPathType} {formatPermissions(path)} {pathInfo(path).size:>8} {dateTime:>16} {coloredExtractedPathName}"




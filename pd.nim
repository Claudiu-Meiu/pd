import std/[parseopt, os, strutils, strformat, times]


var
  currentPath = getCurrentDir()
  showDirs = false
  showFiles = false


proc formatPermissions(path: string): string =
  let permissions = getFileInfo(path, false).permissions
  var user: seq[string] = @[]
  var group: seq[string] = @[]
  var others: seq[string] = @[]

  for perm in permissions:
    case perm
    of fpUserExec:
      user.add("x")
    of fpGroupExec:
      group.add("x")
    of fpOthersExec:
      others.add("x")
    of fpUserRead:
      user.add("r")
    of fpGroupRead:
      group.add("r")
    of fpOthersRead:
      others.add("r")
    of fpUserWrite:
      user.add("w")
    of fpGroupWrite:
      group.add("w")
    of fpOthersWrite:
      others.add("w")

  return user.join("") & "-" & group.join("") & "-" & others.join("")



iterator directories(): string =
  for kind, dirPath in walkDir(currentPath):
    if kind == pcDir:
      yield dirPath

iterator files(): string =
  for kind, filePath in walkDir(currentPath):
    if kind == pcFile:
      yield filePath


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
    currentPath = key


if showDirs:
  for dir in directories():
    let extractedDirName = dir.extractFilename
    let dateTime = local(getFileInfo(dir).lastWriteTime).format("MMM d HH:mm")

    echo fmt"{formatPermissions(dir):<12} {getFileInfo(dir).size:<12} {dateTime:<14} {extractedDirName}"

elif showFiles:
  for file in files():
    let extractedFileName = file.extractFilename
    let dateTime = local(getFileInfo(file).lastWriteTime).format("MMM d HH:mm")

    echo fmt"{formatPermissions(file):<12} {getFileInfo(file).size:<12} {dateTime:<14} {extractedFileName}"

else:
  for kind, path in walkDir(currentPath):
    let extractedPathName = path.extractFilename
    let dateTime = local(getFileInfo(path, false).lastWriteTime).format("MMM d HH:mm")

    if symlinkExists(path):
      echo fmt"{formatPermissions(path):<12} {getFileInfo(path, false).size:<12} {dateTime:<14} {extractedPathName} -> {expandSymlink(path)}"
    else:
      echo fmt"{formatPermissions(path):<12} {getFileInfo(path).size:<12} {dateTime:<14} {extractedPathName}"



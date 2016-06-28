import os
import parseopt2
import streams
import strutils
import endians
import tables
import zip/libzip

# the magic number identifying a java class file
let cafebabe = 3405691582'u32
let javaClassEndianness = bigEndian

proc writeHelp() =
  echo "javaversion prints the java runtime version for which a jar file was compiled"
  echo "usage: javaversion file [file ...]"
  echo "  options:"
  echo "    -h: print this help text"
  echo "    -v: print the current version of this binary"

proc writeVersion() =
  echo "Version 1.0 (by Rudi Angela)\n"

proc readUint32(zipfile: PZipFile, fileEndian: Endianness): uint32 =
  var readInt: uint32
  var readlength: int
  var output: uint32
  readlength = zip_fread(zipfile, addr readInt, 4)
  assert(readlength == 4)
  if (cpuEndian == fileEndian):
    output = readInt
  else:
    swapEndian32(addr output, addr readInt)
  return output

proc readUint16(zipfile: PZipFile, fileEndian: Endianness): uint16 =
  var readInt: uint16
  var readlength: int
  var output: uint16
  readlength = zip_fread(zipfile, addr readInt, 2)
  assert(readlength == 2)
  if (cpuEndian == fileEndian):
    output = readInt
  else:
    swapEndian16(addr output, addr readInt)
  return output

proc checkJarFile(path: string) =
  var err: int32
  var pzip: PZip = zip_open(path, 0, addr err)
  if (pzip == nil):
    echo "Could not open file: ", err
  else:
    var entries = zip_get_num_files(pzip)
    block done:
      for i in countup(0, entries-1):
        var entryname = zip_get_name(pzip, i, 0)
        if (endsWith($entryname, ".class")):
          let zipfile: PZipFile = zip_fopen_index(pzip, i, 0)
          if (isNil(zipfile)):
            echo "Could not open file"
          else:
            var magic: uint32 = readUint32(zipfile, javaClassEndianness)
            assert(magic == cafebabe)
            # now read the minor version and forget it
            var version: uint16 = readUint16(zipfile, javaClassEndianness)
            # read the major version
            version = readUint16(zipfile, javaClassEndianness)
            zip_fclose(zipfile)
            echo format("[1.$#] $#", version - 44, path)
            break done
        else: discard
    zip_close(pzip)

# collector for filenames from command line
var filenames: seq[string] = @[]
var nooptions = true

# extract the arguments and options
for kind, key, val in getopt():
  case kind
  of cmdArgument:
    filenames.add(key)
  of cmdLongOption, cmdShortOption:
    nooptions = false
    case key
    of "help", "h": writeHelp()
    of "version", "v": writeVersion()
  of cmdEnd: assert(false) # cannot happen

# call the version extraction function for every file given
if nooptions and filenames.len == 0:
  # no filename has been given, so we show the help:
  writeHelp()
else:
  for name in filenames:
    checkJarFile(name)

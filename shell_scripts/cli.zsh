sw() {
  if [ $# -eq 0 ]
    then
      dir="$(/Users/nwf/Desktop/projects/zig/dir-cli/zig-out/bin/dir-cli)"
      echo "${dir}"
      cd "${dir}"
    else 
    /Users/nwf/Desktop/projects/zig/dir-cli/zig-out/bin/dir-cli $*  
  fi
}
sw() {
  if [ $# -eq 0 ]
    then
      dir="$(/Users/nwf/Desktop/projects/zig/dir-cli/zig-out/bin/dir-cli)"
    if [ -z "$dir" ]
      then
        return
      else
        echo "${dir}"
        cd "${dir}"
    fi
    else 
    /Users/nwf/Desktop/projects/zig/dir-cli/zig-out/bin/dir-cli $*  
  fi
}
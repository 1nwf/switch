function sw
  if test (count $argv) -gt 0       
        /Users/nwf/Desktop/projects/zig/dir-cli/zig-out/bin/dir-cli $argv
    else
        set -l output (/Users/nwf/Desktop/projects/zig/dir-cli/zig-out/bin/dir-cli)
        echo $output
        cd $output
  end
end

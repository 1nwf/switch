function sw
  if test (count $argv) -gt 0       
        /Users/nwf/Desktop/projects/zig/dir-cli/zig-out/bin/switch $argv
    else
        set -l output (/Users/nwf/Desktop/projects/zig/dir-cli/zig-out/bin/switch)
        if test -z $output 
            return
        end
        # echo $output
        cd $output
  end
end

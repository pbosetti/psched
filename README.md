# psched [![Gem Version](https://badge.fury.io/rb/psched.svg)](https://badge.fury.io/rb/psched)

- [Homepage](https://rubygems.org/gems/psched)
- [Documentation](http://rubydoc.info/gems/psched/frames)

## Description

`psched` is a Ruby gem for precise time-scheduling of recurring tasks. Whenever a simple `sleep()` call is not precise enough, and not even a timing thread can satisfy your demands, `psched` is to the rescue!

The precise timing is obtained through the use of OS semaphores and a Ruby block as an anonymous callback that is regularly called by proper `Signal::trap(:ALRM)` usage. For this reason, `psched` only works on UNIX-like OSs (tested on MacOS and Linux).

In particular, scheduling of OS alarms is performed by `ualarm(3)` and `alarm(3)` LIBC calls, imported in `PSched` module through the Ruby FFI gem.

The FFI gem is also used for importing the `setpriority(3)` LICB function call, that can be used for elevating (under proper user access, sudo) the process priority for further improvements in timing precision (through `PSched::Operation::prioritize()` call.

## Examples

    require 'psched'
    
    # Uncomment if needed:
    # PSched::Operation.prioritize
    
    op = PSched::Operation.new(0.5)
    op.start(10) do |i|
      puts "Ping #{i}"
    end

    Signal.trap("SIGINT") do
      print "Stopping recurring process..."
      op.stop
      puts "done!"
    end

    sleep(0.2) while op.active?  # waits for scheduling to complete

## Requirements
FFI gem and an OS supporting semaphores.

## Install

```
$ gem install psched
```

## Development

The gem is built using the [`ore` gem](https://rubygems.org/gems/ore)

## Copyright

Copyright (c) 2017 Paolo Bosetti

See [LICENSE.txt](https://raw.githubusercontent.com/pbosetti/psched/master/LICENSE.txt) for details.

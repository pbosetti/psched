# psched

- [Homepage](https://rubygems.org/gems/psched)
- [Documentation](http://rubydoc.info/gems/psched/frames)
- [Email](mailto:paolo.bosetti at unitn.it)

## Description

TODO: Description

## Features

TODO: Features

## Examples

    require 'psched'
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

## Copyright

Copyright (c) 2017 Paolo Bosetti

See {file:LICENSE.txt} for details.

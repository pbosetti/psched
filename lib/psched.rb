#!/usr/bin/env ruby
# psched.rb

# Created by Paolo Bosetti on 2011-04-21.
# Copyright (c) 2011 University of Trento. All rights reserved.

require 'ffi'
require 'psched/version'


# A module and a class ({PSched::Operation}) for implementing a recurring
# call as deterministic as possible.
#
# See {PSched::Operation} for usage details. Module functions are FFI
# wrappers and are not intended to be used directly.
# @author Paolo Bosetti
# @todo Are there better ways?
module PSched
  extend FFI::Library
  ffi_lib FFI::Library::LIBC
  # @!method ualarm(useconds, interval)
  #   The `ualarm()` function waits a count of useconds before asserting the
  #   terminating signal `SIGALRM`.  System activity or time used in processing
  #   the call may cause a slight delay.
  #   If the interval argument is non-zero, the `SIGALRM` signal will be sent to
  #   the process every interval microseconds after the timer expires
  #   (e.g.,after useconds number of microseconds have passed).
  #   @param [Fixnum] useconds initial delay in microseconds
  #   @param [Fixnum] interval recurring interval in microseconds
  #   @return [Fixnum] the amount of time left on the clock
  attach_function :ualarm, [:uint, :uint], :uint

  # @!method alarm(seconds)
  #   Set a timer to deliver the signal `SIGALRM` to the calling process after
  #   the specified number of seconds
  #   @param [Fixnum] seconds delay in microseconds
  #   @return [Fixnum] the amount of time left on the clock from a previous
  #                    call to alarm()
  attach_function :alarm, [:uint], :uint

  enum :which, [
    :prio_process,	0,
    :prio_pgrp,
    :prio_user,
    :prio_darwin_thread,
    :prio_darwin_process
  ]

  # @!method setpriority(which, who, prio)
  #   Set the scheduling priority of the current process
  #   @param [Fixnum] which The type of priority, as for the enum `which`
  #   @param [Fixnum] who The process, group, user or thread
  #   @param [Fixnum] prio The priority level, from -20 to 20
  #   @return [0|-1] 0 if no error, -1 if error
  attach_function :setpriority, [:which, :uint, :int], :int

  # Implements a recurring operation.
  # @example General usage. Note the `sleep` call.
  #   op = PSched::Operation.new(0.5)
  #   op.start(10) do |i|
  #     puts "Ping #{i}"
  #   end
  #
  #   Signal.trap("SIGINT") do
  #     print "Stopping recurring process..."
  #     op.stop
  #     puts "done!"
  #   end
  #
  #   sleep(0.2) while op.active?  # THIS IS IMPORTANT!!!
  #
  # @author Paolo Bosetti
  class Operation
    # Changes scheduling priority of the current process
    # @param [Fixnum] nice sets the nice level (-20..+20)
    # @todo better return message and error management
    def self.prioritize(nice = -20)
      result = PSched.setpriority(:prio_process,0,nice)
      puts "Setting max priority: #{result == 0 ? 'success' : 'failure (missing sudo?)'}"
    end

    # @!attribute [rw] strict_timing
    #   If true, raise a {RealTimeError} when `TET >= step`
    #   (default to `false`)
    attr_accessor :strict_timing

    # @!attribute [r] tet
    #   The Task Execution Time
    # @!attribute [r] step
    #   The time step in seconds
    # @!attribute [r] start_time
    #   The time at the beginning of the current Operation
    attr_reader :step, :tet, :start_time

    # Initializer
    # @param [Numeric] step the timestep in seconds
    def initialize(step)
      @step          = step
      @active        = false
      @lock          = false
      @strict_timing = false
      @tet           = 0
    end

    # Sets the time step (in seconds) and reschedule pending alarms.
    # @param [Numeric] secs Timestep in seconds
    def step=(secs)
      @step = secs
      self.schedule
    end

    # Updates scheduling of pending alarms.
    # @note Usually, there's no need to call this, since {#step=} automatically
    #       calls it after having set the +@step+ attribute.
    def schedule
      usecs = @step * 1E6
      PSched::ualarm(usecs, usecs)
    end

    # Tells id the recurring operation is active or not.
    # @return [Boolean] the status of the recurring alarm operation
    def active?; @active; end

    # Starts a recurring operation, described by the passed block.
    # If the block returns the symbol :stop, the recurrin operation gets
    # disabled.
    # @param [Fixnum,nil] n_iter the maximum number of iterations.
    #   If nil it loops indefinitedly
    # @yieldparam [Fixnum] i the number of elapsed iterations
    # @yieldparam [Float] t the time elapsed since the beginning of current Operation
    # @yieldparam [Float] tet the Task Execution Time of previous step
    # @raise [ArgumentError] unless a block is given
    # @raise [RealTimeError] if TET exceeds @step
    def start(n_iter=nil)
      raise ArgumentError, "Need a block!" unless block_given?
      @active = true
      i = 0
      @start_time = Time.now
      Signal.trap(:ALRM) do
        # If there is still a pending step, raises an error containing
        # information about the CURRENT step
        if @lock then
          if @strict_timing
            @lock = false
            raise RealTimeError.new({:tet => @tet, :step => @step, :i => i, :time => Time.now})
          end
        else
          start = Time.now
          @lock = true
          result = yield(i, Time.now - @start_time, @tet)
          i += 1
          self.stop if (n_iter and i >= n_iter)
          self.stop if (result.kind_of? Symbol and result == :stop)
          @tet = Time.now - start
          @lock = false
        end
      end
      self.schedule
    end

    # Stops the recurring process by resetting alarm and disabling management
    # of `SIGALRM` signal.
    def stop
      PSched::ualarm(0, 0)
      Signal.trap(:ALRM, "DEFAULT")
      @active = false
      @lock = false
    end
  end
end

class RealTimeError < RuntimeError
  attr_reader :status
  def initialize(status)
    @status = status
  end
  def ratio
    (@status[:tet] / @status[:step]) * 100
  end
end

if $0 == __FILE__ then
  PSched::Operation.prioritize

  op = PSched::Operation.new(0.5)
  op.start(10) do |i, t|
    puts "Ping #{i}: #{t}"
  end

  Signal.trap("SIGINT") do
    print "Stopping recurring process..."
    op.stop
    puts "done!"
  end

  sleep while op.active?
end

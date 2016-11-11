# frozen_string_literal: true

require 'timeout'
require 'English'
require 'tempfile'

class Task
  PLACEHOLDER = 'FILE'

  attr_reader :status, :command, :target, :output

  def initialize(target, command)
    @system_options = { out: Tempfile.new, err: File::NULL }.freeze
    @command = command
    @target = target
    @status = :prerun
    @pid = nil
  end

  def run(timeout)
    runnable = lambda do
      @pid = spawn @command, @system_options
      Process.wait @pid
    end

    if timeout == :infinite
      runnable.call
    else
      Timeout.timeout(timeout) { runnable.call }
    end

    @status = $CHILD_STATUS.success? ? :success : :failure
  rescue Timeout::Error
    kill @pid

    @status = :timeout
  ensure
    tmp = @system_options[:out]
    if @status == :success
      tmp.rewind
      @output = tmp.read
    end
    tmp.close
  end

  def self.generate(prototype, targets)
    targets.map do |target|
      Task.new target, prototype.gsub(PLACEHOLDER, target)
    end
  end

  private

  def kill(pid)
    Process.kill 'KILL', pid
  end
end

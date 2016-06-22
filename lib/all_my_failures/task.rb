# frozen_string_literal: true

require 'timeout'
require 'English'

class Task
  PLACEHOLDER = 'FILE'
  SYSTEM_OPTIONS = { out: File::NULL, err: File::NULL }.freeze

  attr_reader :status, :command, :target

  def initialize(target, command)
    @command = command
    @target = target
    @status = :prerun
    @pid = nil
  end

  def run(timeout)
    runnable = lambda do
      @pid = spawn @command, SYSTEM_OPTIONS
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

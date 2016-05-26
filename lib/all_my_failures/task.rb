require 'timeout'
require 'English'

class Task
  PLACEHOLDER = 'FILE'.freeze
  SYSTEM_OPTIONS = { out: File::NULL, err: File::NULL }.freeze

  attr_reader :status, :command, :target

  def initialize(target, command)
    @command = command
    @target = target
    @status = :prerun
    @pid = nil
  end

  def run(timeout)
    Timeout.timeout(timeout) do
      @pid = spawn @command, SYSTEM_OPTIONS
      Process.wait @pid
    end

    @status = $CHILD_STATUS.success? ? :success : :failure
  rescue Timeout::Error
    kill @pid

    @status = :timeout
  end

  def cancel
    kill @pid if @pid
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

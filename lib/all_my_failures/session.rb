# frozen_string_literal: true

require 'all_my_failures/task'
require 'all_my_failures/coloured_string'
require 'parallel'

class Session
  using ColouredString

  DEFAULT_TIMEOUT = :infinite
  DEFAULT_THREAD_COUNT = Parallel.processor_count

  def initialize(input_files,
                 command,
                 n_of_threads: DEFAULT_THREAD_COUNT,
                 timeout: DEFAULT_TIMEOUT,
                 suppress_failure: false)
    @tasks = Task.generate command, input_files
    @n_of_threads = n_of_threads
    @timeout = timeout
    @suppress_failure = suppress_failure
    @status_counts = {
      to_run: @tasks.size,
      success: 0,
      failure: 0,
      timeout: 0,
    }
  end

  def note_result(status)
    @status_counts[status] += 1
    @status_counts[:to_run] -= 1
  end

  def run
    # Thread for displaying progress
    Thread.new do
      loop do
        STDIN.gets
        puts print_failures
      end
    end

    Signal.trap 'INT' do
      raise Parallel::Kill
    end

    Parallel.each(@tasks, in_threads: @n_of_threads) do |task|
      task.run @timeout

      case task.status
      when :success
        print  '.'.green
      when :failure
        print  'F'.red
      when :timeout
        print  'T'.light_blue
      else
        raise 'Unexpected process status. Must not happen.'
      end

      note_result task.status
    end

  rescue Parallel::Kill
    # do nothing
  ensure
    puts

    Signal.trap 'INT', 'DEFAULT'
  end

  def to_s
    n_of_tasks = @status_counts.inject(0) { |a, e| a + e[1] }

    StringIO.open do |str|
      str.puts 'Statistics'
      str.puts '-' * 80
      str.print 'targets:'.rjust(10), "\t", n_of_tasks, "\n"
      @status_counts.each do |k, v|
        str.print "#{k}:".rjust(10), "\t", v, "\n"
      end

      non_mistakes = @status_counts[:success] + @status_counts[:to_run]
      if non_mistakes != n_of_tasks && !@suppress_failure
        str.print print_failures
      end

      str.string
    end
  end

  def coloured_failrues
    @tasks.lazy.map do |task|
      if task.status == :failure
        task.target.red
      elsif task.status == :timeout
        task.target.light_blue
      end
    end.select { |e| e }.to_a
  end

  def failures
    @tasks.lazy.map do |task|
      task.target if [:failure, :timeout].include? task.status
    end.select { |e| e }.to_a
  end

  private

  def print_failures
    StringIO.open do |str|
      str.puts
      str.puts 'Failures & Timeouts:'
      str.puts '-' * 80
      str.puts coloured_failrues
      str.string
    end
  end
end

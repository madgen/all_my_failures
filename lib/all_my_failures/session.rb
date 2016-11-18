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
                 timeout: DEFAULT_TIMEOUT)
    @tasks = Task.generate command, input_files
    @n_of_threads = n_of_threads
    @timeout = timeout
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

      str.string
    end
  end

  def failures
    @tasks.lazy.map do |task|
      task if [:failure, :timeout].include? task.status
    end.select { |e| e }
  end

  def successes
    @tasks.lazy.map do |task|
      task if task.status == :success
    end.select { |e| e }
  end
end

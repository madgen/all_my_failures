# frozen_string_literal: true

require 'all_my_failures/task'
require 'parallel'

class Session
  DEFAULT_N_OF_THREADS = Parallel.processor_count
  DEFAULT_TIMEOUT = 60

  def initialize(command, input_files, n_of_threads, timeout)
    @tasks = Task.generate command, input_files
    @n_of_threads = n_of_threads || DEFAULT_N_OF_THREADS
    @timeout = timeout || DEFAULT_TIMEOUT
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
        print  '.'
      when :failure
        print  'F'
      when :timeout
        print  'T'
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

      str.print print_failures if @status_counts[:success] != n_of_tasks

      str.string
    end
  end

  private

  def print_failures
    StringIO.open do |str|
      str.puts
      str.puts 'Failures & Timeouts:'
      str.puts '-' * 80
      @tasks.each do |task|
        str.puts task.target if [:failure, :timeout].include? task.status
      end
      str.string
    end
  end
end

require 'all_my_failures/task'

class Session
  def initialize(command, input_files, n_of_threads, timeout)
    @tasks = Task.generate command, input_files
    @n_of_threads = n_of_threads
    @timeout = timeout
    @status_counts = {
      prerun: @tasks.size,
      success: 0,
      failure: 0,
      timeout: 0,
    }
  end

  def note_result(status)
    @status_counts[status] += 1
    @status_counts[:prerun] -= 1
  end

  def run
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
        raise 'Unexpected process status. Must not happen.'.freeze
      end

      note_result task.status
    end
    puts
  end

  def to_s
    n_of_tasks = @status_counts.inject(0) { |a, e| a + e[1] }

    StringIO.open '' do |str|
      str.puts 'Statistics'
      str.puts '-' * 80
      str.print 'targets:'.rjust(10), "\t", n_of_tasks, "\n"
      @status_counts.each do |k, v|
        str.print "#{k}:".rjust(10), "\t", v, "\n"
      end

      record_failure str if @status_counts[:success] != n_of_tasks

      str.string
    end
  end

  private

  def record_failure(str)
    str.puts
    str.puts 'Failures & Timeouts:'.freeze
    str.puts '-' * 80
    @tasks.each do |task|
      str.puts task.target if [:failure, :timeout].include? task.status
    end
  end
end

require 'all_my_failures/task'
require 'parallel'

class AllMyFailures
  VERSION = '0.0.1'.freeze

  def self.run(input_files, command, n_of_threads, timeout)
    tasks = Task.generate command, input_files, timeout

    Parallel.each(tasks, in_threads: n_of_threads) do |task|
      task.run
      case task.status
      when :success
        print  '.'
      when :failure
        print  'F'
      when :timeout
        print  'T'
      else
        raise 'Unexpected process status'.freeze
      end
    end
    puts

    Task.display tasks
  end
end

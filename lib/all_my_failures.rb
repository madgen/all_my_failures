require 'parallel'
require 'timeout'

class AllMyFailures
  PLACEHOLDER = 'FILE'.freeze
  VERSION = '0.0.1'.freeze
  SYSTEM_OPTIONS = { out: File::NULL, err: File::NULL }.freeze
  TIMEOUT = 60

  def self.run(input_files, command, n_of_threads)
    failures = []
    timeouts = []

    Parallel.each(input_files, in_threads: n_of_threads) do |file_name|
      actual_command = command.gsub PLACEHOLDER, file_name

      begin
        success = false
        Timeout.timeout(TIMEOUT) do
          success = system(actual_command, SYSTEM_OPTIONS)
        end

        if success
          print '.'.freeze
        else
          print 'F'.freeze
          failures << file_name
        end
      rescue Timeout::Error
        print 'T'.freeze
        timeouts << file_name
      end
    end
    puts

    output input_files, failures, timeouts
  end

  def self.output(input_files, failures, timeouts)
    n_of_files = input_files.size
    n_of_failures = failures.size
    n_of_timeouts = timeouts.size

    puts "Number of targets: #{n_of_files}"
    puts "Number of failures: #{n_of_failures}"
    puts "Number of timeouts after #{TIMEOUT} seconds: #{n_of_timeouts}"

    puts 'Failures:'.freeze
    puts '-' * 80
    STDERR.puts failures
    puts
    puts 'Timeouts:'.freeze
    puts '-' * 80
    STDERR.puts timeouts
  end
end

# frozen_string_literal: true

require 'all_my_failures/session'
require 'parallel'

class AllMyFailures
  PROGRAM_NAME = 'all_my_failures'
  VERSION = '0.0.1'
  TERMINAL_WIDTH_R = /^\d\d (?<cols>\d\d)$/

  def self.run(session, failure_output: nil, success_output: nil)
    print header
    session.run
    puts
    puts session

    if success_output
      File.open success_output, 'w' do |f|
        f.puts session.successes
      end
    end

    if failure_output
      File.open failure_output, 'w' do |f|
        f.puts session.failures
      end
    end
  end

  private_class_method
  def self.header
    # Attempt to retrieve column width using stty UNIX utility
    n_of_cols = TERMINAL_WIDTH_R.match(`stty size`)&.[](:cols)&.to_i

    # Only create header if we know how many columns there are
    if n_of_cols
      header = '|' * n_of_cols

      (10...n_of_cols).step(10) do |i|
        marker_beg = i - 1
        marker = i.to_s
        marker_end = marker_beg + marker.length
        container = header[marker_beg...marker_end]

        # Only add the marker if there are enough columns left
        if container.length == marker.length
          header[marker_beg...marker_end] = marker
        end
      end

      header << "\n"
    end
    header
  end
end

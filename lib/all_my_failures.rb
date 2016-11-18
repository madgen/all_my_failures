# frozen_string_literal: true

require 'all_my_failures/session'
require 'parallel'

# Entry point to the dispatcher
class AllMyFailures
  PROGRAM_NAME = 'all_my_failures'
  VERSION = '0.0.1'
  TERMINAL_WIDTH_R = /^\d\d (?<cols>\d\d)$/

  def self.run(session, keep:)
    print header
    session.run
    puts
    puts session

    record session, keep
  end

  private_class_method
  def self.record(session, keep)
    [[:success, :successes],
     [:failure, :failures]].each do |outcome_sym, method|
      outcome = keep[outcome_sym]
      # Skip if success/failure needs to be kept
      next unless outcome

      # Collect successes/failures
      outcomes = session.send(method)

      [:target, :output].each do |data_type_sym|
        # If target doesn't need to be printed, skip.
        next unless outcome[data_type_sym]

        File.open(outcome[data_type_sym], 'w') do |f|
          f.puts outcomes.map(&data_type_sym).to_a
        end
      end
    end
  end

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

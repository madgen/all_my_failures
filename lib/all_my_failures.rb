# frozen_string_literal: true

require 'all_my_failures/session'
require 'parallel'

class AllMyFailures
  VERSION = '0.0.1'

  def self.run(input_files, command, n_of_threads, timeout)
    session = Session.new command, input_files, n_of_threads, timeout
    session.run
    puts
    puts session
  end
end

# frozen_string_literal: true

require 'all_my_failures/session'
require 'parallel'

class AllMyFailures
  PROGRAM_NAME = 'all_my_failures'
  VERSION = '0.0.1'

  def self.run(session, failure_output: nil)
    session.run
    puts
    puts session

    if failure_output
      File.open failure_output, 'w' do |f|
        f.puts session.failures
      end
    end
  end
end

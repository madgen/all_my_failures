# frozen_string_literal: true

require 'all_my_failures/session'
require 'parallel'

class AllMyFailures
  VERSION = '0.0.1'

  def self.run(session)
    session.run
    puts
    puts session
  end
end

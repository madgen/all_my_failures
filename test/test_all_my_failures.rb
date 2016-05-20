gem "minitest"
require "minitest/autorun"
require "all_my_failures"

class TestAllMyFailures < Minitest::Test
  def test_sanity
    flunk "write tests or I will kneecap you"
  end
end

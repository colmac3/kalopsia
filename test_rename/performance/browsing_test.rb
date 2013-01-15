require 'test_helper'
require 'performance_test_help'

# Profiling results for each test_rename method are written to tmp/performance.
class BrowsingTest < ActionController::PerformanceTest
  def test_homepage
    get '/'
  end
end

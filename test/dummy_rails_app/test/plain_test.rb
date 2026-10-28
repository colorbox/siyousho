require "test_helper"

# Not a system test: it must run untouched even though siyousho is loaded.
class PlainTest < ActiveSupport::TestCase
  test "does not use a browser" do
    a = 1
    assert_equal 1, a
  end
end

require 'test_helper'

# This test, calling user.id, passes
class CacheBugTest < ActionDispatch::IntegrationTest
  test "cached entries should not change part a" do
    f = Rails.cache.fetch("key1") do
      users = User.first(5)
      users[0].id
      [users, 0]
    end

    r = Rails.cache.read("key1")

    assert_equal(f[1], r[1])
  end
end

# This test, calling user.avatar, fails
class CacheBugTest < ActionDispatch::IntegrationTest
  test "cached entries should not change part b" do
    f = Rails.cache.fetch("key2") do
      users = User.first(5)
      users[0].avatar
      [users, 0]
    end

    r = Rails.cache.read("key2")

    assert_equal(f[1], r[1])
  end
end

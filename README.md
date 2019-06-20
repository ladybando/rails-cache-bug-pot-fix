### Steps to reproduce

1.) Create a new Rails app

2.) Set `config.cache_store = :memory_store` in `config/test.rb` (and `config/development.rb`, to replicate via Rails console)

3.) Install Active Storage

4.) Create a model with an Active Storage attachment - we'll use a User model with an attached avatar for this example:

```
rails g model User
rake db:migrate
```

```
# app/models/user.rb

class User < ApplicationRecord
  has_one_attached :avatar
end
```

5.) Add fixtures to populate testing DB:

```
# test/fixtures/users.yml

user_1: {}
user_2: {}
user_3: {}
user_4: {}
user_5: {}
```

Or, if reproducing via the Rails console, add seed data via `db/seeds.rb`:

```
# db/seeds.rb

5.times { User.create }
```

```
rake db:seed
```

6.) The following integration tests demonstrate the unexpected behavior. In both cases, a block is passed to `Rails.cache.fetch`, the last line of which contains a two-element array: The first element of the array is an array of users, and the second element can be any object - we'll use the integer 0 for demonstration.

However, in the second test, when calling `Rails.cache.read` to look up the previously created entry, the second element of the array is no equal to that passed to `Rails.cache.fetch` (0).

```
# test/integration/cache_bug_test.rb

require 'test_helper'

# This test, calling user.id in a block passed to fetch, passes
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

# This test, calling user.avatar in a block passed to fetch, fails
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
```

This may be replicated via the Rails console, if the database has been seeded with multiple user records:

```
# Pass a block to Rails.cache.fetch:
f = Rails.cache.fetch("key") do
  users = User.first(5)
  users[0].avatar
  [users, 0]
end
=> [[#<User id: 1, created_at: "2019-06-20 03:15:21", updated_at: "2019-06-20 03:15:21">, #<User id: 2, created_at: "2019-06-20 03:15:21", updated_at: "2019-06-20 03:15:21">, #<User id: 3, created_at: "2019-06-20 03:15:21", updated_at: "2019-06-20 03:15:21">, #<User id: 4, created_at: "2019-06-20 03:15:21", updated_at: "2019-06-20 03:15:21">, #<User id: 5, created_at: "2019-06-20 03:15:21", updated_at: "2019-06-20 03:15:21">], 0]

# Look up the created entry:
r = Rails.cache.read("key")
r = Rails.cache.read("key")
=> [[#<User id: 1, created_at: "2019-06-20 03:15:21", updated_at: "2019-06-20 03:15:21">, :@attachment_changes, {}, #<User id: 2, created_at: "2019-06-20 03:15:21", updated_at: "2019-06-20 03:15:21">, #<User id: 3, created_at: "2019-06-20 03:15:21", updated_at: "2019-06-20 03:15:21">], #<User id: 4, created_at: "2019-06-20 03:15:21", updated_at: "2019-06-20 03:15:21">]

The second element of the array returned by Rails.cache.fetch is 0, as expected:
f[1]
=> 0

However, when calling Rails.cache.read, the second element is now an instance of the User class:
r[1]
=> #<User id: 4, created_at: "2019-06-20 03:15:21", updated_at: "2019-06-20 03:15:21">

# Also note the first element of the cached array appears to have been altered - the second and third elements are a symbol and empty hash when read back from the cache:
r[0][1..2]
=> [:@attachment_changes, {}]
```

### Expected behavior
The evaluated value of last line of a block passed to Rails.cache.fetch should be that of the cache entry that gets created.

### Actual behavior
The value of the cache entry created appears to be altered during serialization via Marshal.dump.

### System configuration
**Rails version**: 6.0.0.rc1

**Ruby version**: 2.6.3
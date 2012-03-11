# ActsAsStream
A highly configurable activity stream system built on top of Redis

## Installation

Install

```ruby
gem install acts_as_stream
```

or in your ```Gemfile```

```ruby
gem 'acts_as_stream'
```

Make sure your redis server is running! Redis configuration is outside the scope of this README, but
check out the [Redis documentation](http://redis.io/documentation).

## Basic Usage
```ruby
ActsAsStream.configure do |config|
  redis = Redis.new(:db => 15)
  config.redis = redis
  config.namespace = :redis_stream_test
  config.activity_scope = :activity
  config.activity_key = :activity
  config.activity_attr = :id
  config.activity_incr = :activity_counter
  config.page_size = 25
end

class User < ActiveRecord::Base
  acts_as_stream
  acts_as_amico # <- not necessary, any follower system will do

  # Define an all_followers method which will return a list of Redis keys, one per follower
  def all_followers
    get_all(:followers).map{|id| User.find(id.to_i)}.map{|u| u.following_key}
  end

end

actor = User.create
follower = User.create

follower.follow! actor # <- acts_as_amico syntax, follow whatever your follow system is

user.register_activity! 'some smart, perhaps parsable, string package– say, perhaps, JSON'
(1..5).each{|i| user.register_activity! "activity #{i}"}

follower.activity_count
 => 6

follower.get_activity.first
 => 'some smart, perhaps parsable, string package– say, perhaps, JSON'
```

## Advanced Usage

## Configuration

## Future Plans

 * Clean up the ActiveResource integration and figure out why :name is so dangerous.
 * Put activity creation/update into a background worker queue

## Contributing to acts_as_stream

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) John Metta. See MIT-LICENSE for further details.

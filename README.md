# ActsAsStream
A highly configurable activity stream system built on top of Redis

## Warnings

 * I've just written this today (3/11/12)
 * The test suite is complete, but I haven't used it in production.
 * I'm building it into a production app now
 * It's probably going to be updated frequently
 * You're welcome to use it, and I'd love feedback
 * Caveat Downloader

### Extra special notes
The move to 0.0.3.alpha.1 involves a change to the key structure. See below.

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

## Key structure

### Activity Keys
Keys for Redis activity packages are created using the format

```
<namespace>:<activity_scope>:<id>
```

where ```namespace``` and ```activity_scope``` are set in the ActsAsStream configuration and default to
a base key of ```acts_as_stream:activity``` and id is the value of ```activity_incr``` which defaults to
```acts_as_stream:activity:activity_counter```

The Activity ID is also added to a sorted set with the key

```
<namespace>:<activity_scope>:sorted <time> <id>
```

where <time> is floating point seconds since the epoch and <id> is as above. This allows for time-based
sorting of activities.

### Followers

Followers are notified by an arbitrary string key that can literally be whatever you want, but which defaults
to

```
<namespace>:<class.name.tableize.singularize>:<streamable_object_id>:<activity_scope> <time> <activity_id>
```

where ```streamable_object_id``` is the value of ```activity_attr```, both of which are set in the configuration options.
```activity_attr``` defaults to ```id``` and can be set on a per model basis. ```activity_id``` is the id of the activity
given above.

Activities are also stored as a list keyed by id

```
<namespace>:<activity_scope>:followers:<activity_id> <follower_key>
```

where ```follower_key``` is the key used above, and activity_id is the id of the activity.

The following system allows for time sorted organization of activities, and ability to see all "viewers" of an activity.

### Mentions

Unless ```:ignore_mentions``` is provided to the acts_as_stream method, mentioned objects can be notified if they were "discussed" in activity. The key
pattern for this is

```
<namespace>:<class.name.tableize.singularize>:<streamable_object_id>:<mentions_scope> <time> <activity_id>
```

and the list by id is
```
<namespace>:<activity_scope>:<mentions_key>:<activity_id> <mentioned_key>
```

The attribute ```mentions_scope``` is provided in the ActsAsStream configuration and defaults to ```:mentions```. This can
be overwritten by sending :mentions_scope as an attribute to acts_as_stream.

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

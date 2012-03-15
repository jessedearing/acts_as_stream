module ActsAsStream
  module Connector

    def register_new_activity! package = nil
      return if package.nil?
      id = increment!
      ActsAsStream.redis.multi do
        #Add the key and package to the system
        ActsAsStream.redis.set "#{base_key}:#{id}", package
        #Add the id to a sorted set scored by time
        ActsAsStream.redis.zadd "#{base_key}:sorted", Time.now.to_f, id
      end
      id
    end

    def deregister_activity! ident
      return if ident.nil?
      ActsAsStream.redis.multi do
        ActsAsStream.redis.del "#{base_key}:#{ident}"
        ActsAsStream.redis.zrem "#{base_key}:sorted", ident
      end
      deregister_followers! ident
      deregister_mentioned! ident
    end

    def register_followers! options = {}
      options.assert_valid_keys(:following_keys, :activity_id)
      return if options[:following_keys].nil? or options[:activity_id].nil?
      raise ":following_keys must be an array of keys" if not options[:following_keys].is_a? Array
      ActsAsStream.redis.multi do
        options[:following_keys].each do |key|
          ActsAsStream.redis.zadd key, Time.now.to_f, options[:activity_id]
          ActsAsStream.redis.lpush "#{base_key}:followers:#{options[:activity_id]}", key
        end
      end
    end

    def deregister_followers! activity_id = nil
      return if activity_id.nil?
      followers_key = "#{base_key}:followers:#{activity_id}"
      len = ActsAsStream.redis.llen followers_key
      followers = ActsAsStream.redis.lrange followers_key, 0, len
      return if followers.nil?
      ActsAsStream.redis.multi do
        followers.each do |f|
          ActsAsStream.redis.zrem f, activity_id
        end
        ActsAsStream.redis.del "#{base_key}:followers:#{activity_id}"
      end
    end

    def register_mentions! options = {}
      options.assert_valid_keys(:mentioned_keys, :activity_id)
      return if options[:mentioned_keys].nil? or options[:activity_id].nil?
      raise ":mentioned_keys must be an array of keys" if not options[:mentioned_keys].is_a? Array
      ActsAsStream.redis.multi do
        options[:mentioned_keys].each do |key|
          ActsAsStream.redis.zadd key, Time.now.to_f, options[:activity_id]
          ActsAsStream.redis.lpush "#{base_key}:mentions:#{options[:activity_id]}", key
        end
      end
    end

    def deregister_mentioned! activity_id = nil
      return if activity_id.nil?
      mentioned_key = "#{base_key}:mentions:#{activity_id}"
      return if mentioned_key.nil?
      len = ActsAsStream.redis.llen mentioned_key
      mentioned = ActsAsStream.redis.lrange mentioned_key, 0, len
      return if mentioned.nil?
      ActsAsStream.redis.multi do
        mentioned.each do |f|
          ActsAsStream.redis.zrem f, activity_id
        end
        ActsAsStream.redis.del "#{base_key}:mentions:#{activity_id}"
      end
    end
    
    def get_activity_for follower_key, options = {}
      options = {:page => 1, :page_size => ActsAsStream.page_size}.merge options
      options[:page] = 1 if options[:page] < 1

      if options[:page] > total_pages(follower_key, options[:page_size])
        options[:page] = total_pages(follower_key, options[:page_size])
      end

      starting_offset = ((options[:page] - 1) * options[:page_size])
      starting_offset = 0 if starting_offset < 0
      ending_offset = (starting_offset + options[:page_size]) - 1

      ActsAsStream.redis.zrevrange(follower_key, starting_offset, ending_offset, :with_scores => false).map{|i| get_activity i}
    end

    def get_activity_since follower_key, since = 2.days.ago

    end

    def get_activity id
      ActsAsStream.redis.get "#{base_key}:#{id}"
    end

    def total_pages key, page_size = ActsAsStream.page_size
      (ActsAsStream.redis.zcard(key) / page_size.to_f).ceil
    end

    def count
      ActsAsStream.redis.get(ActsAsStream.activity_incr).to_i
    end

    def base_key
      "#{ActsAsStream.namespace}:#{ActsAsStream.activity_scope}"
    end
    private

    def increment!
      ActsAsStream.redis.incr(ActsAsStream.activity_incr)
    end
    def time
      Time.now.to_i
    end
  end
end
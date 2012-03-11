module ActsAsStream
  module Connector

    def register_new_activity! package = nil
      return if package.nil?
      id = increment!
      this_time = time
      ActsAsStream.redis.multi do
        #Add the key and package to the system
        ActsAsStream.redis.set "#{base_key}:#{id}", package
        #Add a timed key, scored by id, and an id-based key
        ActsAsStream.redis.zadd "#{base_key}:time:#{this_time}", id, id
        ActsAsStream.redis.set "#{base_key}:id:#{id}", this_time
      end
      raise "### Unable to set Time keys!" if ActsAsStream.redis.get("#{base_key}:id:#{id}") != this_time.to_s
      #return the current activity ID
      id
    end

    def deregister_activity! ident
      return if ident.nil?
      score = ActsAsStream.redis.get "#{base_key}:id:#{ident}"
      ActsAsStream.redis.multi do
        ActsAsStream.redis.del "#{base_key}:#{ident}"
        ActsAsStream.redis.zrem "#{base_key}:time:#{score}", ident
        ActsAsStream.redis.del "#{base_key}:id:#{ident}"
      end
      deregister_followers! ident
    end

    def register_followers! options = {}
      options.assert_valid_keys(:following_keys, :activity_id)
      return if options[:following_keys].nil? or options[:activity_id].nil?
      raise ":following_keys must be an array of keys" if not options[:following_keys].is_a? Array
      time = Time.now.to_i

      ActsAsStream.redis.multi do
        options[:following_keys].each do |key|
          ActsAsStream.redis.zadd key, time, options[:activity_id]
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
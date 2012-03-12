module ActsAsStream
  module StreamActivity

    def package options = {}
      options.assert_valid_keys(:who, :action, :time, :object, :ignore_stream_hash_on)
      raise "You need at least a :who and an :action! to create an activity package" if options[:who].nil? or options[:action].nil?
      opts = {:time => Time.now.to_i, :ignore_stream_hash_on => []}.merge options
      # Try to ensure :time is in seconds
      opts[:time] = opts[:time].to_i if opts[:time].is_a?(Time)

      # If Objects provide the :to_stream_hash method, use it.
      if opts[:ignore_stream_hash_on].present?
        #convenience, make sure it's an array so we can use include? instead of "include? or equals"
        opts[:ignore_stream_hash_on] = [opts[:ignore_stream_hash_on]] unless opts[:ignore_stream_hash_on].is_a?(Array)
      end

      [:who, :object].each do |opt|
        #unless we are ignoring the stream hash for this object, use StreamableObject.stream_hash
        unless opts[:ignore_stream_hash_on].include?(opt) or not opts[opt].respond_to?(:to_stream_hash)
          opts[opt] = opts[opt].to_stream_hash
        end
      end

      opts.delete(:ignore_stream_hash_on)

      # then, if everything is fine, bundle it up into a JSON string
      opts.to_json
    end
  end
end
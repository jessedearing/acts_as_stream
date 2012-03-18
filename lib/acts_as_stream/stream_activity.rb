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
          begin
            opts[opt] = opts[opt].to_stream_hash
          rescue NoMethodError
            raise "The class #{opts[opt].class.name} does not have a method called #{opts[opt].activity_attr}. Perhaps you should look at your ActsAsStream configuration, or set :activity_attr"
          end
        end
      end

      opts.delete(:ignore_stream_hash_on)

      # then, if everything is fine, bundle it up into a JSON string
      opts.to_json
    end
    
    def parse package
      package = JSON.parse(package)
      package.keys.each{|k| package[k.to_sym] = package[k]; package.delete(k)}
      # Try to cast :who and :object to instances
      begin
        package[:who].keys.each{|k| package[:who] = k.titleize.constantize.find(package[:who][k]["id"].to_i)}
      rescue
        raise "Cannot translate :who into an instantiated model. Perhaps the model used as the creator of this activity did not have a :to_stream_hash method? The :who value is:\n #{package[:who]}"
      end
      begin
        package[:object].keys.each{|k| package[:object] = k.titleize.constantize.find(package[:object][k]["id"].to_i)}
      rescue
        raise "Cannot translate :object into an instantiated model. Perhaps the model used as the :object in this activity did not have a :to_stream_hash method? The :object value is:\n #{package[:object]}"
      end
      package
    end

  end
end
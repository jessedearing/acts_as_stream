require 'redis'
require 'acts_as_stream'
require "acts_as_stream/configuration"
require "acts_as_stream/version"
require 'acts_as_stream/streamable_object'

module ActsAsStream
  extend Configuration
end

ActiveRecord::Base.send :include, ActsAsStream::StreamableObject
ActiveResource::Base.send :include, ActsAsStream::StreamableObject
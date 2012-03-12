require 'redis'
require 'acts_as_stream'
require "acts_as_stream/configuration"
require "acts_as_stream/connector"
require "acts_as_stream/version"
require 'acts_as_stream/streamable_object'
require 'acts_as_stream/stream_activity'

module ActsAsStream
  extend Configuration
  extend Connector
  extend StreamActivity
end

ActiveRecord::Base.send :include, ActsAsStream::StreamableObject
ActiveResource::Base.send :include, ActsAsStream::StreamableObject
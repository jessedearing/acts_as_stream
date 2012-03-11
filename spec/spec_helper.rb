require 'simplecov'
SimpleCov.start 'rails'

require 'rubygems'
require 'spork'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.
  # Configure Rails Envirnonment
  ENV["RAILS_ENV"] = "test"

  require File.expand_path("../dummy/config/environment.rb",  __FILE__)
  require "rails/test_help"
  require "rspec/rails"
  require "acts_as_amico"

  ActionMailer::Base.delivery_method = :test
  ActionMailer::Base.perform_deliveries = true
  ActionMailer::Base.default_url_options[:host] = "test.com"

  Rails.backtrace_cleaner.remove_silencers!

  RSpec.configure do |config|
    # Remove this line if you don't want RSpec's should and should_not
    # methods or matchers
    require 'rspec/expectations'
    config.include RSpec::Matchers
    config.color_enabled = true

    # == Mock Framework
    config.mock_with :rspec
    config.before(:all) do
      Amico.configure do |configuration|
        redis = Redis.new(:db => 15)
        configuration.redis = redis
      end
    end
    config.before(:each) do
      Amico.redis.flushdb
    end

    config.after(:all) do
      Amico.redis.flushdb
      Amico.redis.quit
    end

  end
  require 'factory_girl'
  require 'fakeweb'


end

Spork.each_run do

  FactoryGirl.find_definitions
  ActsAsStream.redis.flushdb

  # Load support files
  Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

end

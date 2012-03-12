require 'spec_helper'

describe ActsAsStream::StreamActivity do

  before :each do
    @user = Factory :user
    @widget = Factory :widget
    @admin = Factory :admin
    @time = Time.now.to_i
    @valid_options = {:who => @user,
                      :action => "Tested StreamActivity!",
                      :time => @time,
                      :object => @widget}
    @valid_json = "{\"time\":#{@time},\"who\":{\"user\":{\"id\":#{@user.id}}},\"action\":\"Tested StreamActivity!\",\"object\":{\"widget\":{\"id\":#{@widget.id}}}}"
  end

  describe "time" do
    it "should create a valid package with all valid options" do
      package(@valid_options).should == @valid_json
    end

    it "should create a valid package without a time" do
      options = @valid_options.dup
      options.delete(:time)
      #Making an assumption this won't block on time!
      time = Time.now.to_i

      json = "{\"time\":#{time},\"who\":{\"user\":{\"id\":#{@user.id}}},\"action\":\"Tested StreamActivity!\",\"object\":{\"widget\":{\"id\":#{@widget.id}}}}"
      package(options).should == json
    end

    it "should create a valid package with a Time object" do
      options = @valid_options.dup
      time = Time.now
      options[:time] = time
      #Making an assumption this won't block on time!
      json = "{\"time\":#{time.to_i},\"who\":{\"user\":{\"id\":#{@user.id}}},\"action\":\"Tested StreamActivity!\",\"object\":{\"widget\":{\"id\":#{@widget.id}}}}"
      decode(package(options)).should == decode(json)
    end
  end

  describe "stream_hash" do
    it "should encode the actor as complete json" do
      options = @valid_options.dup
      options[:ignore_stream_hash_on] = :who
      hash = {:who => @user, :action => options[:action], :time => options[:time], :object => @widget.to_stream_hash}
      pack = package(options)
      pack.should_not == @valid_json
      decode(pack).should == decode(hash.to_json)
    end
    it "should encode the object as complete json" do
      options = @valid_options.dup
      options[:ignore_stream_hash_on] = :object
      hash = {:who => @user.to_stream_hash, :action => options[:action], :time => options[:time], :object => @widget}
      pack = package(options)
      pack.should_not == @valid_json
      decode(pack).should == decode(hash.to_json)
    end

    it "should encode the actor and object as complete json" do
      options = @valid_options.dup
      options[:ignore_stream_hash_on] = [:who, :object]
      hash = {:who => @user, :action => options[:action], :time => options[:time], :object => @widget}
      pack = package(options)
      pack.should_not == @valid_json
      decode(pack).should == decode(hash.to_json)
    end

  end
  private

  def decode json
    ActiveSupport::JSON.decode(json)
  end
  def package(options={})
    ActsAsStream.package options
  end
end
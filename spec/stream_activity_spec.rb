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
      ActsAsStream.package(@valid_options).should == @valid_json
    end

    it "should create a valid package without a time" do
      options = @valid_options.dup
      options.delete(:time)
      #Making an assumption this won't block on time!
      time = Time.now.to_i

      json = "{\"time\":#{time},\"who\":{\"user\":{\"id\":#{@user.id}}},\"action\":\"Tested StreamActivity!\",\"object\":{\"widget\":{\"id\":#{@widget.id}}}}"
      ActsAsStream.package(options).should == json
    end

    it "should create a valid package with a Time object" do
      options = @valid_options.dup
      options.delete(:time)
      #Making an assumption this won't block on time!
      time = Time.now
      json = "{\"time\":#{time.to_i},\"who\":{\"user\":{\"id\":#{@user.id}}},\"action\":\"Tested StreamActivity!\",\"object\":{\"widget\":{\"id\":#{@widget.id}}}}"
      ActsAsStream.package(options).should == json
    end
  end

  describe "stream_hash" do
    it "should encode the actor as complete json" do
      options = @valid_options.dup
      options[:ignore_stream_hash_on] = :who
      ActsAsStream.package(options).should_not == @valid_json
    end
  end
  private

  def test_package(options={})
    ActsAsStream.package options
  end
end
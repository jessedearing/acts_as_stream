require "spec_helper"

describe ActsAsStream::StreamableObject do

  before :each do
    @user = Factory :user
    @admin = Factory :admin
    @widget = Factory :widget
    @thing = Factory :thing
    @user_base = "redis_stream_test:activity"
    @admin_base = "redis_stream_test:actions"
  end
  it "should update followers and return a list of other's activity" do
    string = "Test Activity"
    usera = Factory :user
    usera.follow! @user
    @user.register_activity! string
    usera.get_activity_for(:whom => :others).should =~ [string]
  end
  it "should return the correct list of the users own activity" do
    string = "Test Own Activity"
    usera = Factory :user
    @user.follow! usera
    id = usera.register_activity! string
    @user.get_activity_for(:whom => :others).should =~ [string]
    usera.get_activity_for(:whom => :own).should =~ [string]
  end

  it "should return the correct mentions count" do
    string = "Test Mention"
    usera = Factory :user
    id = @user.register_activity! string
    @user.register_mentions! :activity_id => id, :mentioned_keys => usera.mentioned_by_others_key
    usera.get_activity_for(:whom => :mentions).should =~ [string]
  end

  it "should return a count of a user's own mentions of other people" do
    string = "Testing Own Mention"
    usera = Factory :user
    id = @user.register_activity! string
    @user.register_mentions! :key => @user.mentions_key, :activity_id => id, :mentioned_keys => [usera.mentioned_by_others_key]
    @user.get_activity_for(:whom => :own_mentions).should =~ [string]
  end
end
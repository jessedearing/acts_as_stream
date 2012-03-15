class Admin < ActiveRecord::Base
  acts_as_stream :activity_attr => :guid, :activity_scope => :actions, :mentions_scope => :notifications
  acts_as_amico
  validates_uniqueness_of :guid
  validates_presence_of :guid

  def all_followers
    get_all(:followers).map{|id| User.find(id.to_i)}.map{|u| u.following_key}
  end

end

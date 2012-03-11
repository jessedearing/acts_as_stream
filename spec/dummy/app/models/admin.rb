class Admin < ActiveRecord::Base
  acts_as_stream :activity_attr => :guid, :activity_scope => :actions
  validates_uniqueness_of :guid
  validates_presence_of :guid
end

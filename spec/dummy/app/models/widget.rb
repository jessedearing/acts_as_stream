class Widget < ActiveRecord::Base
  acts_as_stream :activity_scope => :people_doings
  acts_as_amico

  def all_followers
    get_all(:following)
  end
end

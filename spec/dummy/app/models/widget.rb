class Widget < ActiveRecord::Base
  acts_as_stream :activity_scope => :people_doings
end

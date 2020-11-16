
class PeopleKiLog < ActiveRecord::Base

  include Redmine::I18n
  belongs_to :people_ki, :foreign_key => :people_ki_id, :class_name => 'PeopleKi'
  belongs_to :user

end

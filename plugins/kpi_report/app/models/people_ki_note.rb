class PeopleKiNote < ActiveRecord::Base

  include Redmine::I18n
  belongs_to :version
  belongs_to :manager, :foreign_key => :lead_id, :class_name => 'User'
  belongs_to :user, :foreign_key => :user_id, :class_name => 'User'
end

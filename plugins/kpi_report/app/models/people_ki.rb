class PeopleKi < ActiveRecord::Base

  include Redmine::I18n
  belongs_to :version
  belongs_to :user

end

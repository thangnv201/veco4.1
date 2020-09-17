class VecoPhone < ActiveRecord::Base

  include Redmine::SafeAttributes
  safe_attributes 'name', 'phone'

end
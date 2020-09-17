class IssueStatuse < ActiveRecord::Base

  include Redmine::SafeAttributes
  safe_attributes 'name'

end
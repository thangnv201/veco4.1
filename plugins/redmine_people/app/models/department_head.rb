class DepartmentHead < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :department, :foreign_key => :department_id, :class_name => 'Department'
  belongs_to :head, :class_name => 'Person', :foreign_key => 'head_id'

  safe_attributes 'department_id', 'head_id'

end

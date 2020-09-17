require_dependency 'issue'

module RedmineAutoclose
  module Patches
    module IssuePatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          after_save do |issue|
            issue.parent.update_attributes({
              :status_id => RedmineAutoclose::parent_status_id
            }) if issue.should_autoclose_parent?
            
          end
        end
      end

      module InstanceMethods
        def should_autoclose_parent?
          return false unless parent && RedmineAutoclose::child_status_id == status_id
          parent.children.all?{ |i| i.status_id == RedmineAutoclose::child_status_id }
        end
      end
    end
  end
end

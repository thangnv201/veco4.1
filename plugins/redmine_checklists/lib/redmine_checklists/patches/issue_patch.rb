# This file is a part of Redmine Checklists (redmine_checklists) plugin,
# issue checklists management plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_checklists is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_checklists is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_checklists.  If not, see <http://www.gnu.org/licenses/>.

require_dependency 'issue'

module RedmineChecklists
  module Patches
    module IssuePatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          attr_accessor :old_checklists
          attr_accessor :removed_checklist_ids
          attr_reader :copied_from

          alias_method :copy_without_checklist, :copy
          alias_method :copy, :copy_with_checklist
          after_save :copy_subtask_checklists

          if ActiveRecord::VERSION::MAJOR >= 4
            has_many :checklists, lambda { order("#{Checklist.table_name}.position") }, :class_name => 'Checklist', :dependent => :destroy, :inverse_of => :issue
          else
            has_many :checklists, :class_name => 'Checklist', :dependent => :destroy, :inverse_of => :issue, :order => 'position'
          end

          accepts_nested_attributes_for :checklists, :allow_destroy => true, :reject_if => proc { |attrs| attrs['subject'].blank? }

          validate :block_issue_closing_if_checklists_unclosed

          safe_attributes 'checklists_attributes',
            :if => lambda { |issue, user| (user.allowed_to?(:done_checklists, issue.project) || user.allowed_to?(:edit_checklists, issue.project)) }
        end
      end
      # Class used to represent issue checklists
      class ChecklistRelations
        def initialize(issue, checklists)
          @issue = issue
          @checklists = checklists
        end

        def to_a
          @checklists.to_a
        end

        def to_s
          to_a.map do |item|
            if item.is_section
              item.subject
            elsif item.is_done
              "[+] #{item.subject}"
            else
              "[-] #{item.subject}"
            end
          end.join("\r\n")
        end
      end

      module InstanceMethods
        def copy_checklists(arg)
          issue = arg.is_a?(Issue) ? arg : Issue.visible.find(arg)
          if issue
            issue.checklists.each do |checklist|
              Checklist.create(checklist.attributes.except('id', 'issue_id').merge(issue: self))
            end
          end
        end

        def copy_subtask_checklists
          return if !copy? || parent_id.nil? || checklists.reload.any?
          copy_checklists(@copied_from)
        end

        def copy_with_checklist(attributes = nil, copy_options = {})
          copy = copy_without_checklist(attributes, copy_options)
          copy.copy_checklists(self)
          copy
        end

        def all_checklist_items_is_done?
          (checklists - checklists.where(id: removed_checklist_ids)).reject(&:is_section).all?(&:is_done)
        end

        def need_to_block_issue_closing?
          RedmineChecklists.block_issue_closing? &&
            checklists.reject(&:is_section).any? &&
            status.is_closed? &&
            !all_checklist_items_is_done?
        end

        def block_issue_closing_if_checklists_unclosed
          if need_to_block_issue_closing?
            errors.add(:checklists, l(:label_checklists_must_be_completed))
          end
        end
        def checklist_relations
          ChecklistRelations.new(self, checklists)
        end
      end
    end
  end
end

unless Issue.included_modules.include?(RedmineChecklists::Patches::IssuePatch)
  Issue.send(:include, RedmineChecklists::Patches::IssuePatch)
end

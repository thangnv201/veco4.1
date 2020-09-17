require 'redmine'

Redmine::Plugin.register :redmine_autoclose do
  name        'redmine_autoclose'
  author      'Hieuht28'
  description 'Auto-close parent task after his childrens are closed'
  

  settings :default => {
    :child_status_id => 0,
    :parent_status_id => 0
  }, :partial => 'autoclose/settings'
end

ActionDispatch::Callbacks.to_param do
  require_dependency 'issue'
  unless Issue.included_modules.include?(RedmineAutoclose::Patches::IssuePatch)
    Issue.send(:include, RedmineAutoclose::Patches::IssuePatch)
  end
end
Redmine::Plugin.register :project_report do
  name 'Project Report plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  permission :project_report, { project_reports: [:index, :show] }, public: true
  menu :project_menu, :project_report, { controller: 'project_reports', action: 'index'}, caption: 'Report', after: :activity, param: :project_id
end

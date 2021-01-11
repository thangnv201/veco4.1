Redmine::Plugin.register :process_manager do
  name 'Process Manager plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  permission :process_test, { process: [:index] }, public: true
  menu :project_menu , :process_test, { controller: 'process', action: 'index' }, caption: 'Process Manager',after: :activity, param: :project_id
end

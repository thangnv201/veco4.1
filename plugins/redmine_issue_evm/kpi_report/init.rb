Redmine::Plugin.register :kpi_report do
  name 'Kpi Report plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  permission :kpi_report , :my_kpi=> :index, require: :member

end

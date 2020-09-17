Redmine::Plugin.register :reportpeople do
  name 'Reportpeople plugin'
  author 'ThangNV74'
  description 'This is a plugin for VECO VHT'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  permission :kpi_people_report, { :reportpeople => [:index]}, :require => :loggedin
end

# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'kpi_people_report', to: 'reportpeople#index'
get 'kpi_people_report/exports', to: 'reportpeople#show', format: 'xlsx'
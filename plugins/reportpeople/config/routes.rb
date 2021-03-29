# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'kpi_people_report', to: 'reportpeople#index'
get 'kpi_people_report/exports', to: 'reportpeople#show', format: 'xlsx'
get 'child_dep', to:'reportpeople#get_child_depart'
get 'get_member',to:'reportpeople#get_member'
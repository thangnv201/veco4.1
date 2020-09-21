# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'my_kpi',to:'my_kpi#index'
get 'cbnv_kpi',to:'my_kpi#cbnvkpi'
get 'my_kpi/status/:id/:user_id', to:'my_kpi#status'
get 'my_kpi/anotherfield/:id/:user_id', to:'my_kpi#get_another_field'
get 'kpi_ranking',to:'cnbv_kpi#index'
get 'kpi_ranking/save',to:'cnbv_kpi#save'
put 'update_ki',to: 'my_kpi#update_people_ki'
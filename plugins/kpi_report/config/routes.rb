# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'my_kpi', to: 'my_kpi#index'
get 'cbnv_kpi', to: 'my_kpi#cbnvkpi'
get 'my_kpi/status/:id/:user_id', to: 'my_kpi#status'
get 'my_kpi/anotherfield/:id/:user_id', to: 'my_kpi#get_another_field'
get 'ki_ranking', to: 'cnbv_kpi#index'
get 'ki_ranking/dep_ki', to: 'cnbv_kpi#dep_ki'
get 'ki_ranking/sub_dep_ki', to: 'cnbv_kpi#sub_dep_ki'
get 'ki_ranking/TCLD', to: 'cnbv_kpi#TCLD'
get 'ki_ranking/tcld2', to: 'cnbv_kpi#tcld2'
get 'ki_ranking/heads',to:'cnbv_kpi#heads'
get 'ki_ranking/heads2',to:'cnbv_kpi#heads2'
get 'ki_ranking/save', to: 'cnbv_kpi#save'
get 'ki_ranking/saveRendKI', to: 'cnbv_kpi#saveRendKI'
get 'ki_ranking/tcldsave', to: 'cnbv_kpi#tcldsave'
get 'ki_ranking/saveAllKI', to: 'cnbv_kpi#saveAllKI'
get 'ki_ranking/get_user_kpi', to: 'cnbv_kpi#get_user_kpi'
put 'update_ki', to: 'my_kpi#update_people_ki'
get 'my_kpi/import', to: 'my_kpi#importkpi'
post 'my_kpi/convert', to: 'my_kpi#convertkpi'
post 'my_kpi/update_kpi_point', to: 'my_kpi#updatekpipoint'
get 'ki_ranking/get_user_kpi',to:'cnbv_kpi#get_user_kpi'
get 'ki_module',to: 'my_kpi#kimodule'
get 'ki_module_data',to: 'my_kpi#kimoduledata'
get 'pa_ki_module_data',to: 'my_kpi#kimodule_pa_data'
get 'pa_kpi',to: 'my_kpi#pa_kpi'
get 'pa_cbnv',to: 'my_kpi#pa_cbnv_kpi'
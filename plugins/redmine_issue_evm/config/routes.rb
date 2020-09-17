# routing
Rails.application.routes.draw do
  resources :projects do
    resources :evms, :evmbaselines, :evmsettings, :evmassignees, :evmparentissues, :evmversions, :evmtrackers, :evmexcludes
  end
  get 'my/page/:login', :to => 'statistic#statisticBGD', :as => 'project_statistic_BGD'

end

# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get :'thangnv',to:'project_reports#index'
get :'testexport',to:'project_reports#show',format: 'docx'

resource :example, only: :show, format: 'docx'
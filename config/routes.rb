Rails.application.routes.draw do
  namespace :cohortly do
    match     'report_all', :controller => 'reports', :action => 'show', :as => :report_all
    resources :metrics, :only => [:index]
    resources :reports, :only => [:index, :show]
  end
end

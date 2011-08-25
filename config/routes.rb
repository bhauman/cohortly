Rails.application.routes.draw do
  namespace :cohortly do
    resources :metrics, :only => [:index]
    resources :reports, :only => [:index, :show]
  end
end
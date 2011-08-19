Rails.application.routes.draw do
  namespace :cohortly do
    resources :metrics, :only => [:index]
  end
end
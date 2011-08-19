class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :record_event


  protected

  def record_event
    payload = { :user_start_date => Time.now - 1.month,
                :user_id         => 5,
                :user_email => "jordon@example.com",
                :tags => [params[:action] + "_tag", params[:controller] + '_tag'],
                :controller => params[:controller],
                :action => params[:action]
                }

    ActiveSupport::Notifications.instrument("cohortly.event", payload)
  end
end

class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :record_event


  protected

  def record_event
    Rails.logger.info(Cohortly::TagConfig.instance)
    payload = { :user_start_date => Time.now - 1.month,
                :user_id         => 5,
                :controller => params[:controller],
                :action => params[:action]
                }

    ActiveSupport::Notifications.instrument("cohortly.event", payload)
  end
end

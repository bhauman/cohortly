require 'test_helper'

class CohortlyTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Cohortly

    payload = { :user_start_date => Time.now - 1.month,
                :user_email => "jordon@example.com",
                :tags => ['login', 'over13'],
                :controller => "session",
                :action => "login"
                }

    ActiveSupport::Notifications.instrument("cohortly.event", payload)

    metric = Cohortly::Metric.first
    assert metric,  "should create metric"
    assert metric.created_at
    assert metric.tags.include? 'login'
    assert metric.tags.include? 'over13'
    assert_equal metric.controller, 'session'
    assert_equal metric.action, 'login'
    assert_equal metric.user_email, 'jordon@example.com'
    assert_equal metric.user_start_date.utc.to_s, payload[:user_start_date].utc.to_s

  end
end

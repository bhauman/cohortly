require 'test_helper'

class CohortlyTest < ActiveSupport::TestCase

  test "cohortly record event" do
    payload = { :user_start_date => Time.now - 1.month,
                :user_id         => 5,
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

  test "report map reduce" do
    setup_data_to_report_on
    Cohortly::Metric.cohort_chart_for_tag
    assert_equal (Cohortly::Metric.all.collect &:user_id).uniq.length, 105

    report = Cohortly::Report.new('cohort_report')
    assert_equal report.month_to_time('2011-08'), Time.utc(2011, 8)
    assert_equal report.start_month, (Time.now - 15.months).year.to_s + '-0' + (Time.now - 15.months).month.to_s
    assert_equal report.month_cohorts.length, 15
    p report.data.collect {|x| x['_id']}
#    assert_equal report.report_line(report.month_cohorts[2]), []
    assert_equal report.report_totals, []
  end

  def setup_data_to_report_on
    payload = { :user_start_date => Time.now - 1.month,
                :user_id         => 5,
                :tags => ['login', 'over13'],
                :controller => "session",
                :action => "login"
                }
    # 15 months of data
    15.times do |start_offset|
      start_offset.times do |m|
        ((start_offset * 100)..((start_offset * 100) + m)).to_a.each do |user_id|
          payload[:user_id] = user_id
          payload[:user_start_date] = Time.now - start_offset.months
          payload[:created_at] = Time.now - m.months

          5.times { ActiveSupport::Notifications.instrument("cohortly.event", payload) }
        end
      end
    end

  end
end

require 'test_helper'

class CohortlyTest < ActiveSupport::TestCase

  test "tag config" do
    assert_equal Cohortly::TagConfig.tags_for(:hi_there, :index), ['hello']
    assert_equal Cohortly::TagConfig.tags_for(:see_ya, :index), []
    assert_equal Cohortly::TagConfig.tags_for(:see_ya, :create), ['goodbye']
    assert_equal Cohortly::TagConfig.tags_for(:hi_there, :what), []
    assert_equal Cohortly::TagConfig.tags_for(:hi_there, :update), ['hello', 'goodbye']
    assert_equal Cohortly::TagConfig.tags_for(:stuff, :a), ['only_good', 'only_bad']
    assert_equal Cohortly::TagConfig.tags_for(:stuff, :b), ['only_good', 'only_bad']
    assert_equal Cohortly::TagConfig.tags_for(:goodies, :a), ['only_good', 'only_bad']
    assert_equal Cohortly::TagConfig.tags_for(:goodies, :b), ['only_good', 'only_bad']
    assert_equal Cohortly::TagConfig.tags_for(:hellas, :b), ['heh', 'whoa']
    assert_equal Cohortly::TagConfig.tags_for(:hellas, :b), ['heh', 'whoa']

    assert_equal Cohortly::TagConfig.all_tags, ['hello', 'goodbye', 'only_good', 'only_bad', 'heh', 'whoa', 'over13', 'login']
  end

  test "cohortly record event" do

    payload = { :user_start_date => Time.now - 1.month,
                :user_id         => 5,
                :user_email => "jordon@example.com",
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
  
 test "cohortly record event without controller or action" do

    payload = { :user_start_date => Time.now - 1.month,
                :user_id         => 5,
                :user_email => "jordon@example.com",
                :add_tags => ['login', 'over13'] }

    ActiveSupport::Notifications.instrument("cohortly.event", payload)

    metric = Cohortly::Metric.first
    assert metric,  "should create metric"
    assert metric.created_at
    assert metric.tags.include? 'login'
    assert metric.tags.include? 'over13'
    assert_equal metric.controller, nil    
    assert_equal metric.user_email, 'jordon@example.com'
    assert_equal metric.user_start_date.utc.to_s, payload[:user_start_date].utc.to_s

  end

  test "one day of data" do
    payload = { :user_start_date => Time.now,
                :user_id         => 5,
                :user_email => "jordon@example.com",
                :controller => "session",
                :action => "login"
                }

    ActiveSupport::Notifications.instrument("cohortly.event", payload)
    Cohortly::Metric.cohort_chart_for_tag()
    report = Cohortly::Report.new( Cohortly::Metric.report_table_name() )
    assert_equal report.report_totals, [[1]]
  end
  
  test "report map reduce" do
    setup_data_to_report_on
    Cohortly::Metric.cohort_chart_for_tag
    assert_equal (Cohortly::Metric.all.collect &:user_id).uniq.length, 136

    report = Cohortly::Report.new(Cohortly::Metric.report_table_name())
    assert_equal report.month_to_time('2011-08'), Time.utc(2011, 8)
    assert_equal report.time_to_month(Time.utc(2011,8)), '2011-08'
    assert_equal report.start_month, (Time.now - 15.months).year.to_s + '-0' + (Time.now - 15.months).month.to_s
    assert_equal report.month_cohorts.length, 16

    assert_equal report.report_totals, [[16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
                                        [15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
                                        [14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
                                        [13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
                                        [12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
                                        [11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
                                        [10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
                                        [9, 8, 7, 6, 5, 4, 3, 2, 1],
                                        [8, 7, 6, 5, 4, 3, 2, 1],
                                        [7, 6, 5, 4, 3, 2, 1],
                                        [6, 5, 4, 3, 2, 1],
                                        [5, 4, 3, 2, 1],
                                        [4, 3, 2, 1],
                                        [3, 2, 1],
                                        [2, 1],
                                        [1]]

  end

  test "counting uniq users in cohort" do
    setup_data_to_report_on
    Cohortly::Metric.cohort_chart_for_tag()
    report = Cohortly::Report.new(Cohortly::Metric.report_table_name())
    start_month = report.start_month
    start_month_time = report.month_to_time(report.start_month)
    next_month  = report.time_to_month(start_month_time + 1.month)
    
    assert_equal report.user_count_in_cohort(start_month), 16
    assert_equal report.user_count_in_cohort(next_month), 15    
  end

  test "getting a line of percentages" do
    setup_data_to_report_on
    Cohortly::Metric.cohort_chart_for_tag
    report = Cohortly::Report.new(Cohortly::Metric.report_table_name())
    line = report.percent_line(report.start_month)
    assert_equal line, [16, 100, 94, 88, 81, 75, 69, 63, 56, 50, 44, 38, 31, 25, 19, 13, 6]
  end

  def setup_data_to_report_on
    payload = { :user_start_date => Time.now,
                :user_id         => 5,
                :controller => "session",
                :action => "login"
    }
    
    (0..15).to_a.each do |user_id|
      start_date = Time.now - user_id.months
      payload[:user_start_date] = start_date      
      (0..15).to_a.each do |iter|
        payload[:user_id] = (1000 * iter) + user_id
        ((iter)..15).to_a.each do |x|
          if Time.now - x.months > start_date
            payload[:created_at] = Time.now - x.months
            Cohortly::Metric.store! [nil, nil, nil, nil, payload] 
          end
        end        
      end
    end
  end
end

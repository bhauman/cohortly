require 'test_helper'

class CohortlyTest < ActiveSupport::TestCase
  include Cohortly
  def setup
    Cohortly::ReportMeta.delete_all
  end
  
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
    Cohortly::Metric.weekly_cohort_chart_for_tag()
    report = Cohortly::Report.new()
    assert_equal report.report_totals, [[1]]
  end

  test "weekly" do
    Cohortly::Metric.delete_all
    setup_weekly_data_to_report_on
    Cohortly::Metric.weekly_cohort_chart_for_tag

    report = Cohortly::Report.new()
    assert report.weekly
    
    time = DateTime.strptime('2011-08', '%Y-%W')
    assert_equal report.key_to_time('2011-08'), time
    assert_equal report.key_to_time(report.time_to_key(time)), time     
    
    assert_equal report.time_to_key(Time.utc(2011,8)), '2011-31'
    assert_equal report.time_to_key(Time.utc(2011,1)), '2011-00'
    assert_equal report.start_key, report.time_to_key(Time.now - 15.weeks)
    assert_equal report.period_cohorts.length, 16

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
  
  test "report map reduce" do
    setup_data_to_report_on
    Cohortly::Metric.cohort_chart_for_tag
    assert_equal (Cohortly::Metric.all.collect &:user_id).uniq.length, 136

    report = Cohortly::Report.new(nil,nil,false)
    assert_equal report.key_to_time('2011-08'), Time.utc(2011, 8)
    assert_equal report.time_to_key(Time.utc(2011,8)), '2011-08'
    assert_equal report.start_key, (Time.now - 15.months).year.to_s + '-0' + (Time.now - 15.months).month.to_s
    assert_equal report.period_cohorts.length, 16

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
    setup_weekly_data_to_report_on
    Cohortly::Metric.weekly_cohort_chart_for_tag()
    report = Cohortly::Report.new()
    start_week = report.start_key
    start_week_time = report.key_to_time(report.start_key)
    next_week  = report.time_to_key(start_week_time + 1.week)
    
    assert_equal report.user_count_in_cohort(start_week), 16
    assert_equal report.user_count_in_cohort(next_week), 15    
  end

  test "getting a line of percentages" do
    setup_weekly_data_to_report_on
    Cohortly::Metric.weekly_cohort_chart_for_tag
    report = Cohortly::Report.new
    line = report.percent_line(report.start_key)
    assert_equal line, [16, 100, 94, 88, 81, 75, 69, 63, 56, 50, 44, 38, 31, 25, 19, 13, 6]
  end
  
  test "javascript day of year" do
    StoredProcedures.store_procedures
    assert_equal Time.now.utc.strftime('%j').to_i, StoredProcedures.execute(:day_of_year, Time.now.utc)
    assert_equal (Time.now.utc + 1.day).strftime('%j').to_i, StoredProcedures.execute(:day_of_year, Time.now.utc + 1.day)
  end

  test "javascript week of year" do
    StoredProcedures.store_procedures
    assert_equal Time.now.utc.strftime('%W').to_i, StoredProcedures.execute(:week_of_year, Time.now.utc)
    assert_equal (Time.now.utc + 1.week).strftime('%W').to_i, StoredProcedures.execute(:week_of_year, Time.now.utc + 1.week)
    30.times { |x|
      assert_equal (Time.now.utc + x.days).strftime('%W').to_i, StoredProcedures.execute(:week_of_year, Time.now.utc + x.days)
    }
  end

  test "javascript time to week key" do
    StoredProcedures.store_procedures
    assert_equal Time.now.utc.strftime('%Y-%W'), StoredProcedures.execute(:week_key, Time.now.utc)
    30.times { |x|
      assert_equal (Time.now.utc + x.days).strftime('%Y-%W'), StoredProcedures.execute(:week_key, Time.now.utc + x.days)
    }
  end
  
  test "name to args" do
    assert_equal Metric.report_name_to_args("cohortly_report-weekly"), [nil, nil, true]
    assert_equal Metric.report_name_to_args("cohortly_report-groups=rand_0-weekly"), [nil, ['rand_0'], true]
    assert_equal Metric.report_name_to_args("cohortly_report-tags=rand_5-groups=rand_0:rand_1-weekly"), [['rand_5'], ['rand_0', 'rand_1'], true]
    assert_equal Metric.report_name_to_args("cohortly_report-tags=rand_1:rand_5-groups=rand_0:rand_1-weekly"), [['rand_1', 'rand_5'], ['rand_0', 'rand_1'], true]
    assert_equal Metric.report_name_to_args("cohortly_report-tags=rand_1:rand_5-monthly"), [['rand_1', 'rand_5'], nil, false]        
  end
  
  def setup_data_to_report_on
    payload = { :user_start_date => Time.now,
                :user_id         => 5,
                :controller => "session",
      :action => "login",
      :add_tags => ['monthly']
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

  def setup_weekly_data_to_report_on(tag = 'weekly' )
    payload = { :user_start_date => Time.now,
                :user_id         => 5,
                :controller => "session",
      :action => "login",
      :add_tags => [tag]
    }
    
    (0..15).to_a.each do |user_id|
      start_date = Time.now - user_id.weeks
      payload[:user_start_date] = start_date      
      (0..15).to_a.each do |iter|
        payload[:user_id] = (1000 * iter) + user_id
        ((iter)..15).to_a.each do |x|
          if Time.now - x.weeks > start_date
            payload[:created_at] = Time.now - x.weeks
            Cohortly::Metric.store! [nil, nil, nil, nil, payload] 
          end
        end        
      end
    end
  end
end

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
    payload = { :user_start_date => Time.now.utc,
                :user_id         => 5,
                :user_email => "jordon@example.com",
                :controller => "session",
                :action => "login",
                :created_at => Time.now.utc
                }

    ActiveSupport::Notifications.instrument("cohortly.event", payload)
    Cohortly::Metric.weekly_cohort_chart_for_tag()
    report = Cohortly::Report.new()
    assert_equal report.report_totals, [[1]]
  end

  test "weekly" do
    Cohortly::Metric.delete_all
    weekly_data
    Cohortly::Metric.weekly_cohort_chart_for_tag

    report = Cohortly::Report.new()
    assert report.weekly
    
    time = DateTime.strptime('2011-08', '%Y-%W').utc
    assert_equal report.key_to_time('2011-08'), time
    assert_equal report.key_to_time(report.time_to_key(time)), time     

    
    assert_equal report.time_to_key(Time.utc(2011,8)), '2011-31'
    assert_equal report.time_to_key(Time.utc(2011,1)), '2011-00'
    assert_equal report.start_key, report.time_to_key(Time.now.utc - 15.weeks)
    assert_equal report.period_cohorts.length, 15

    assert_equal report.report_totals, [
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
  
  test "absolutely correct wwekly data chart" do
    Cohortly::Metric.delete_all
    weekly_data
    Cohortly::Metric.weekly_cohort_chart_for_tag

    report = Cohortly::Report.new()
    assert report.weekly
    
    time = DateTime.strptime('2011-08', '%Y-%W').utc
    assert_equal report.key_to_time('2011-08'), time
    assert_equal report.key_to_time(report.time_to_key(time)), time     

    
    assert_equal report.time_to_key(Time.utc(2011,8)), '2011-31'
    assert_equal report.time_to_key(Time.utc(2011,1)), '2011-00'
    assert_equal report.start_key, report.time_to_key(Time.now.utc - 15.weeks)
    assert_equal report.period_cohorts.length, 15

    assert_equal report.report_totals, [[15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
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
    assert_equal report.period_cohorts.length, 15

    assert_equal report.report_totals, [[16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2],
                                        [15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2],
                                        [14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2],
                                        [13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2],
                                        [12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2],
                                        [11, 10, 9, 8, 7, 6, 5, 4, 3, 2],
                                        [10, 9, 8, 7, 6, 5, 4, 3, 2],
                                        [9, 8, 7, 6, 5, 4, 3, 2],
                                        [8, 7, 6, 5, 4, 3, 2],
                                        [7, 6, 5, 4, 3, 2],
                                        [6, 5, 4, 3, 2],
                                        [5, 4, 3, 2],
                                        [4, 3, 2],
                                        [3, 2],
                                        [2]]

  end

  test "counting uniq users in cohort" do
    setup_weekly_data_to_report_on
    Cohortly::Metric.weekly_cohort_chart_for_tag()
    report = Cohortly::Report.new()

    start_week_time = report.key_to_time(report.start_key) 
    next_week  = report.time_to_key(start_week_time + 1.week)    
    
    assert_equal report.user_count_in_cohort(report.start_key), 16
    assert_equal report.user_count_in_cohort(next_week), 15    
  end

  test "getting a line of percentages" do
    setup_weekly_data_to_report_on
    Cohortly::Metric.weekly_cohort_chart_for_tag
    report = Cohortly::Report.new
    line = report.percent_line(report.time_to_key(report.key_to_time(report.start_key) + 1.week ))
    assert_equal line, [15, 100, 93, 87, 80, 73, 67, 60, 53, 47, 40, 33, 27, 20, 13]
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
    week_end_minus_15 = Time.now.end_of_week - 15.hours
    # these are one second off of eachother bleh :P
    30.times { |x|
      assert_equal (week_end_minus_15 + x.hours + 1.second).utc.strftime('%W').to_i, StoredProcedures.execute(:week_of_year, week_end_minus_15 + x.hours)
    }
  end

  test "javascript time to week key" do
    StoredProcedures.store_procedures
    assert_equal Time.now.utc.strftime('%Y-%W'), StoredProcedures.execute(:week_key, Time.now.utc)
    week_end_minus_15 = Time.now.end_of_week - 15.hours
    30.times { |x|
      assert_equal (week_end_minus_15 + x.days + 1.second).strftime('%Y-%W'), StoredProcedures.execute(:week_key, week_end_minus_15 + x.days)
    }
  end
  
  test "name to args" do
    assert_equal Metric.report_name_to_args("cohortly_report-weekly"), [nil, nil, true]
    assert_equal Metric.report_name_to_args("cohortly_report-groups=rand_0-weekly"), [nil, ['rand_0'], true]
    assert_equal Metric.report_name_to_args("cohortly_report-tags=rand_5-groups=rand_0:rand_1-weekly"), [['rand_5'], ['rand_0', 'rand_1'], true]
    assert_equal Metric.report_name_to_args("cohortly_report-tags=rand_1:rand_5-groups=rand_0:rand_1-weekly"), [['rand_1', 'rand_5'], ['rand_0', 'rand_1'], true]
    assert_equal Metric.report_name_to_args("cohortly_report-tags=rand_1:rand_5-monthly"), [['rand_1', 'rand_5'], nil, false]        
  end
  
  def weekly_data_generate
    data = (1..15).to_a.reverse.collect {|x| (1..x).to_a.reverse}
    user_id_level = 0
    data.collect do |ds|
      start_date = ds.first.weeks.ago;
      user_base = user_id_level * 1000
      ds.each do |d|
        occured_on = d.weeks.ago
        d.times { |user_id| yield user_base + user_id + 1, start_date, occured_on }
      end
      user_id_level += 1
    end
  end

  def weekly_data
     payload = {
        :controller => "session",
        :action => "login",
        :add_tags => ['login']
    }
    weekly_data_generate do |user_id, started_on, occurred_on|
      payload[:user_id] = user_id
      payload[:username] = "user-#{user_id}"      
      payload[:user_start_date] = started_on
      payload[:created_at] = occurred_on
      Cohortly::Metric.store! [nil, nil, nil, nil, payload]       
    end
  end
  
  def setup_data_to_report_on
    payload = { :user_start_date => Time.now,
                :user_id         => 5,
                :controller => "session",
      :action => "login",
      :add_tags => ['monthly']
    }
    
    (0..15).to_a.each do |user_id|
      start_date = Time.now.utc - user_id.months
      payload[:user_start_date] = start_date      
      (0..15).to_a.each do |iter|
        payload[:user_id] = (1000 * iter) + user_id
        ((iter)..15).to_a.each do |x|
          if Time.now.utc - x.months > start_date
            payload[:created_at] = Time.now.utc - x.months
            Cohortly::Metric.store! [nil, nil, nil, nil, payload] 
          end
        end        
      end
    end
  end

  def setup_weekly_data_to_report_on(tag = 'weekly' )
    payload = { :user_start_date => Time.now.utc,
                :user_id         => 5,
                :controller => "session",
      :action => "login",
      :add_tags => [tag]
    }
    
    (0..15).to_a.each do |user_id|
      start_date = Time.now.utc - user_id.weeks
      payload[:user_start_date] = start_date      
      (0..15).to_a.each do |iter|
        payload[:user_id] = (1000 * iter) + user_id
        ((iter)..15).to_a.each do |x|
          if Time.now.utc - x.weeks > start_date
            payload[:created_at] = Time.now.utc - x.weeks
            Cohortly::Metric.store! [nil, nil, nil, nil, payload] 
          end
        end        
      end
    end
  end
end

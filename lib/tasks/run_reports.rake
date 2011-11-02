namespace :cohortly do
  namespace :run do
    desc "run the reports for all the tags"
    task :recalc_reports => :environment do
      real_tags = Cohortly::Metric.collection.distinct(:tags)
      real_tags.each do |tag|
        report = Cohortly::TagReport.where(:tags => tag).first
        report ||= Cohortly::TagReport.new(:tags => [tag])
        report.recalc_table
        report.save
      end

      # the empty report
      report = Cohortly::TagReport.where(:tags => []).first
      report ||= Cohortly::TagReport.new(:tags => [])
      report.recalc_table
      report.save
    end

    desc "update all existing reports"
    task :updates => :environment do
      real_tags = Cohortly::Metric.collection.distinct(:tags)
      real_tags.each do |tag|
        report = Cohortly::TagReport.where(:tags => tag).first
        report ||= Cohortly::TagReport.new(:tags => [tag])
        report.run
        report.save
      end
      
      # the empty report
      report = Cohortly::TagReport.where(:tags => []).first
      report ||= Cohortly::TagReport.new(:tags => [])
      report.run
      report.save      
    end

    desc "build cohorts"
    task :build_cohorts => :environment do
      Cohortly::Cohorts.group_names.each do |name|
        cohort = Cohortly::GroupCohort.find_or_create_by_name(name)
        cohort.store!
      end

      #weekly cohort
      cur_time = Cohortly::Cohorts.first_user_start_date.utc.beginning_of_week
      while(cur_time < Time.now) do
        time_key = (cur_time + 3.days).strftime("%Y-%W")
        cohort = Cohortly::PeriodCohort.find_or_create_by_name(time_key)
        cohort.start_time = cur_time
        cohort.weekly = true
        cohort.store!
        cur_time += 1.week
      end
    end
  end
end

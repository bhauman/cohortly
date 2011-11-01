namespace :cohortly do
  namespace :run do
    desc "run the reports for all the tags"
    task :reseed_reports => :environment do
      Cohortly::ReportMeta.delete_all
      Cohortly::Metric.cohort_chart(nil, nil, true)
      puts "main report"
      real_tags = (Cohortly::Metric.collection.distinct(:tags) - Cohortly::TagConfig.all_groups)
      real_tags.each do |tag|
        Cohortly::Metric.cohort_chart([tag], nil, true)
        puts "tag: #{tag}"
      end
      Cohortly::TagConfig.all_groups.each do |group|
        real_tags.each do |tag|
          puts "tag: #{tag} group: #{group}"          
          Cohortly::Metric.cohort_chart([tag], [group], true)
        end        
      end
    end

    desc "update all existing reports"
    task :updates => :environment do
      Cohortly::ReportMeta.all.each do |rep|
        puts rep.collection_name
        rep.run
      end
    end

    desc "build cohorts"
    task :build_cohorts => :environment do
      
      Cohortly::Cohorts.group_names.each do |name|
        cohort = TagCohort.find_or_create_by_name(name)
        cohort.store!
      end

      #weekly cohort
      cur_time = Cohortly::Cohorts.first_user_start_date.utc.beginning_of_week
      while(cur_time < Time.now) do
        time_key = cur_time.strftime("%Y-%W")
        cohort = Cohortly::PeriodCohort.find_or_create_by_tag(time_key)
        cohort.start_time = cur_time
        cohort.weekly = true
        cohort.store!
        cur_time += 1.week
      end
    end
  end
end

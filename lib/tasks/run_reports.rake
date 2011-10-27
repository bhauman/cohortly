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
  end
end

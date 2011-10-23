namespace :cohortly do
  namespace :run do
    desc "run the reports for all the tags"
    task :reports => :environment do
      report_names = Cohortly::Metric.database.collections.select { |c| c.name =~ /^cohortly_report/ }.collect &:name
      report_names.each do |name|
        args = Cohortly::Metric.report_name_to_args(name)
        Cohortly::Metric.cohort_chart(*args)
        puts name  
      end
      (Cohortly::Metric.collection.distinct(:tags) - Cohortly::TagConfig.all_groups).each do |tag|
        Cohortly::Metric.cohort_chart([tag], nil, true)
        puts "tag: #{tag}"
      end
      Cohortly::TagConfig.all_groups.each do |group|
        Cohortly::TagConfig.all_tags.each do |tag|
          puts "tag: #{tag} group: #{group}"          
          Cohortly::Metric.cohort_chart([tag], [group], true)
        end        
      end
    end
  end
end

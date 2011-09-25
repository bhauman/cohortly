namespace :cohortly do
  namespace :run do
    desc "run the reports for all the tags"
    task :reports => :environment do
      Cohortly::Metric.cohort_chart_for_tag
      Cohortly::TagConfig.all_tags.each do |tag|
        Cohortly::Metric.cohort_chart_for_tag(tag)
      end
    end
  end
end

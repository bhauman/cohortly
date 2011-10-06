class Cohortly::ReportsController < Cohortly::CohortlyController
  def index
    @metric_search = Cohortly::Metric.new(params[:cohortly_metric])
    tags = @metric_search.tags.any? ? @metric_search.tags : nil
    report_name =  Cohortly::Metric.report_table_name(tags)
    unless Cohortly::Metric.database.collections.collect(&:name).include?( report_name )
      Cohortly::Metric.cohort_chart_for_tag(tags)
    end  
    @report = Cohortly::Report.new( report_name )
  end

end

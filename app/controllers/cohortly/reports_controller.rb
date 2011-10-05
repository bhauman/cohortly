class Cohortly::ReportsController < Cohortly::CohortlyController
  def index
    @metric_search = Cohortly::Metric.new(params[:cohortly_metric])
    tags = @metric_search.tags.any? ? @metric_search.tags : nil
    Cohortly::Metric.cohort_chart_for_tag(tags)    
    @report = Cohortly::Report.new( Cohortly::Metric.report_table_name(tags) )
  end

end

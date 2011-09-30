class Cohortly::ReportsController < Cohortly::CohortlyController
  def index
    @metric_search = Cohortly::Metric.new(params[:cohortly_metric])
    Cohortly::Metric.cohort_chart_for_tag(params[:tags])    
    @report = Cohortly::Report.new( Cohortly::Metric.report_table_name(params[:tags]) )  
  end

end

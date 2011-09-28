class Cohortly::ReportsController < Cohortly::CohortlyController
  def index
    @tags = Cohortly::TagConfig.all_tags
  end

  def show
    Cohortly::Metric.cohort_chart_for_tag(params[:id])
    @report = Cohortly::Report.new( Cohortly::Metric.report_table_name(params[:id]) )
  end
end

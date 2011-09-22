class Cohortly::ReportsController < ApplicationController
  def index
    @tags = Cohortly::TagConfig.all_tags
  end

  def show
    @report_name = Cohortly::Metric.cohort_chart_for_tag(params[:id])
    @report = Cohortly::Report.new(@report_name)
  end
end

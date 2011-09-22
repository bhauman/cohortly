class Cohortly::ReportsController < ApplicationController
  def index
    @tags = Cohortly::TagConfig.all_tags
  end

  def show
#    Cohortly::Metric.cohort_chart_for_tag
    @report = Cohortly::Report.new('cohort_report')
  end
end

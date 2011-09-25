class Cohortly::ReportsController < ApplicationController
  def index
    @tags = Cohortly::TagConfig.all_tags
  end

  def show
    @report = Cohortly::Report.new( Cohortly::Metric.report_table_name(params[:id]) )
  end
end

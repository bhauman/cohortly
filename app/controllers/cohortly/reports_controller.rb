class Cohortly::ReportsController < Cohortly::CohortlyController
  def index
    Cohortly::Metric.send :attr_accessor, :groups
    @metric_search = Cohortly::Metric.new(params[:cohortly_metric])
    tags = @metric_search.tags.any? ? @metric_search.tags : nil
    groups = @metric_search.groups    
    report_name =  Cohortly::Metric.report_table_name(tags, groups, true)
   # unless Cohortly::Metric.database.collections.collect(&:name).include?( report_name )
      Cohortly::Metric.weekly_cohort_chart_for_tag(tags, groups)
   # end
    @report = Cohortly::Report.new( tags, groups, true )
    respond_to do |format|
      format.html
      format.js { render :json => @report }
    end

  end

end

class Cohortly::ReportsController < Cohortly::CohortlyController
  def index
    Cohortly::Metric.send :attr_accessor, :groups
    @metric_search = Cohortly::Metric.new(params[:cohortly_metric])
    tags = @metric_search.tags.any? ? @metric_search.tags : nil
    groups = @metric_search.groups    
      
    @report_meta = ReportMeta.first
    
    @base_n = { }
    
    @report_meta.cohort_iter(@report_meta.start_time) do |cohort_range|
      key = cohort_range.begin.strftime('%Y-%W')
      @base_n[key] = Cohortly::Metric.collection.distinct(:user_id,
                                                          { :user_start_date => {
                                                              :$gt => cohort_range.begin,
                                                              :$lt => cohort_range.end }}).count
    end
    
    json_res = {
      :groups => groups,
      :tags => tags,
      :weekly => true,
      :data => @report_meta.data,
      :base_n => @base_n
    }
    
    respond_to do |format|
      format.html
      format.js {
        render :json => json_res
      }
    end
  end
end

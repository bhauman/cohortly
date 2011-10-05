class Cohortly::MetricsController < Cohortly::CohortlyController
  def index
    @metric_search = Cohortly::Metric.new(params[:cohortly_metric])
    
    scope = Cohortly::Metric.sort(:created_at.desc)
    if params[:cohortly_metric] && params[:cohortly_metric][:tags]
      scope = scope.where(:tags => { :$all => @metric_search.tags })
    end
    if @metric_search.user_id
      scope = scope.where(:user_id => @metric_search.user_id)
    end
    @metrics = scope.paginate(:per_page => 200, :page => params[:page])
  end
end

class Cohortly::MetricsController < Cohortly::CohortlyController
  def index
    @metric_search = Metric.new(params[:cohortly_metric])
    
    scope = Cohortly::Metric.limit(250).sort(:created_at.desc)
    if params[:tags]
      scope = scope.where(:tags => { :$all => params[:tags] })
    end
    if @metric_search.user_id
      scope = scope.where(:user_id => @metric_search.user_id)
    end
    @metrics = scope.all
  end
end

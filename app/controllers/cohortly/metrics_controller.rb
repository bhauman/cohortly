class Cohortly::MetricsController < Cohortly::CohortlyController
  def index
    @metric_search = Cohortly::Metric.new(params[:cohortly_metric])
    
    scope = Cohortly::Metric.sort(:created_at.desc)
    if params[:cohortly_metric] && params[:cohortly_metric][:tags]
      scope = scope.where(:tags => { :$in => @metric_search.tags })
    end
    if params[:cohortly_metric] && params[:cohortly_metric][:groups]
      groups = params[:cohortly_metric][:groups]
      scope = scope.where(:$where => "function() { return #{ groups.collect {|x| 'this.tags.indexOf("' + x + '") >= 0'  }.join(' || ') }; }"      )
    end    
    if !@metric_search.user_id.blank?
      scope = scope.where(:user_id => @metric_search.user_id)
    end
    if !@metric_search.username.blank?
      scope = scope.where(:username => @metric_search.username)
    end    
    @metrics = scope.paginate(:per_page => 200, :page => params[:page])
  end
end

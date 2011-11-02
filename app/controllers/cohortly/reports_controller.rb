class Cohortly::ReportsController < Cohortly::CohortlyController
  def index
    Cohortly::Metric.send :attr_accessor, :groups      
    @metric_search = Cohortly::Metric.new(params[:cohortly_metric])    
    json_res = { }
    
    if params[:cohortly_metric]
      tags = @metric_search.tags.any? ? @metric_search.tags : ['upload']
      groups = @metric_search.groups    
    
      @tag_report = Cohortly::TagReport.where(:tags => tags).first

      @base_n = Cohortly::PeriodCohort.all.inject({ }) do |base_n, per_coh|
        base_n.merge( per_coh.name => per_coh.user_ids.length )
      end
    
      json_res = {
        :groups => groups,
        :tags => tags,
        :weekly => true,
        :data => @tag_report.data,
        :base_n => @base_n
      }
    end

    respond_to do |format|
      format.html
      format.js {
        render :json => json_res
      }
    end
  end
end

class Cohortly::ReportsController < Cohortly::CohortlyController
  def index
    Cohortly::Metric.send :attr_accessor, :groups      
    @metric_search = Cohortly::Metric.new(params[:cohortly_metric])    
    json_res = { }
    
    if params[:cohortly_metric]
      tags = @metric_search.tags.any? ? @metric_search.tags : ['upload']
      groups = @metric_search.groups    

      reports = Cohortly::TagReport.where(:tags => tags).all       

      @tag_report = reports.inject(Cohortly::TagReport.new) { |accum, tag_report| accum.merge(tag_report) }  

      user_func = lambda { |user_ids| user_ids.length }
      
      if groups
        cohorts = Cohortly::GroupCohort.where(:name => groups).all
        all_base_users = Cohortly::UserCohort.union(cohorts)
        user_func = lambda { |user_ids| (all_base_users & user_ids).length }
        @tag_report.intersect(all_base_users.map(&:to_s))
      end
      
      @base_n = Cohortly::PeriodCohort.all.inject({ }) do |base_n, per_coh|
        base_n.merge( per_coh.name => user_func.call(per_coh.user_ids) )
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

class Cohortly::ReportsController < Cohortly::CohortlyController
  def index
    Cohortly::Metric.send :attr_accessor, :groups
    Cohortly::Metric.send :attr_accessor, :groups_intersect    
    @metric_search = Cohortly::Metric.new(params[:cohortly_metric])    
    json_res = { }
    
    if params[:cohortly_metric]
      tags = @metric_search.tags.any? ? @metric_search.tags : ['upload']
      groups = @metric_search.groups
      groups_intersect = @metric_search.groups_intersect          
  
      reports = Cohortly::TagReport.where(:tags => tags).all       

      @tag_report = reports.inject(Cohortly::TagReport.new) { |accum, tag_report| accum.merge(tag_report) }  

      user_base_func = lambda { |user_ids| user_ids.length }

      if groups || groups_intersect
        users_constraint = false
        if groups && groups.any?
          users_constraint = Cohortly::UserCohort.union(Cohortly::GroupCohort.where(:name => groups).all)
        end
        if groups_intersect && groups_intersect.any?
          group_intersect_users =  Cohortly::UserCohort.intersect(Cohortly::GroupCohort.where(:name => groups_intersect).all)
          users_constraint = users_constraint ? users_constraint & group_intersect_users : group_intersect_users
        end
        if users_constraint
          user_base_func = lambda { |user_ids| (users_constraint & user_ids).length }
          @tag_report.intersect(users_constraint.map(&:to_s))          
        end
      end
      
      @base_n = Cohortly::PeriodCohort.all.inject({ }) do |base_n, per_coh|
        base_n.merge( per_coh.name => user_base_func.call(per_coh.user_ids) )
      end        
    
      json_res = {
        :groups => groups,
        :tags => tags,
        :weekly => true,
        :data => @tag_report.data_without_empty_rows,
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

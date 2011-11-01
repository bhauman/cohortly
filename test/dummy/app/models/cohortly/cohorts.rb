module Cohortly
  class Cohorts
    def group_names
      [:rand_1, :rand_2, :rand_3]
    end

    def group_name(name)
      Cohortly::Metric.collection.distinct(:user_id, :tag => [name])
    end

    def range(time_range)
      Cohortly::Metric.collection.distinct(:user_id, :user_start_time => { :$gte => time_range.begin, :lt => time_range.end })
    end  
  end
end

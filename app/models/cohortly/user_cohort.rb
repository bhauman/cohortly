module Cohortly
  class UserCohort
    include MongoMapper::Document
    key :user_ids, Array
    key :name,      String
    key :_type,    String    
    timestamps!
    
    def self.intersect(cohorts)
      cohorts.inject(cohorts.first.user_ids) { |user_ids, cohort| user_ids & cohort.user_ids }
    end

    def self.union(cohorts)
      cohorts.inject([]) { |user_ids, cohort| user_ids | cohort.user_ids }
    end    
    
  end
end

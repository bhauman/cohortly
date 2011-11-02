module Cohortly
  class GroupCohort < Cohortly::UserCohort
    def store!
      return unless self.name
      self.user_ids = Cohortly::Cohorts.group_name(self.name)
      self.save        
    end
  end
end

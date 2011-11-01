module Cohortly
  class TagCohort < Cohortly::Cohort
    def store!
      return unless self.tag
      self.user_ids = Cohortly::Cohorts.group(self.tag)
      self.save        
    end
  end
end

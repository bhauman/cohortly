module Cohortly
  class PeriodCohort < Cohortly::UserCohort
    key :start_time, Time
    key :weekly, Boolean

    def end_time
      self.start_time + period
    end

    def period
      self.weekly ? 1.week : 1.month
    end

    def key_pattern
      self.weekly ? "%Y-%W" : "%Y-%m"
    end

    def store!
      self.user_ids = Cohortly::Cohorts.range(self.start_time..self.end_time)
      self.name = self.start_time.strftime(key_pattern)
      self.save        
    end
  end
end

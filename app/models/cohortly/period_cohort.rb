module Cohortly
  class UserCohort
    include MongoMapper::Document
    
    key :user_ids, Array
    key :tag,      String
    key :_type,    String    
    timestamps!
    
    def store!
      return unless self.tag
      self.user_ids = Cohortly::Cohorts.group(self.tag)
      self.save        
    end
  end
end

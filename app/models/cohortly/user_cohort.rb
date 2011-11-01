module Cohortly
  class UserCohort
    include MongoMapper::Document
    key :user_ids, Array
    key :tag,      String
    key :_type,    String    
    timestamps!
  end
end

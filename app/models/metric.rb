module Cohortly
  class Metric
    include MongoMapper::Document

    key :user_start_date, Time
    key :user_email, String
    key :tags, Array
    key :controller, String
    key :action, String
    timestamps!

    def self.store!(args)
      create(args[4])
    end
  end
end
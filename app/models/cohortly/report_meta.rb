module Cohortly
  class ReportMeta
    include MongoMapper::Document

    key :collection_name, String
    key :last_update_on, Time
  end
end

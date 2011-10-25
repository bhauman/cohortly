module Cohortly
  class ReportMeta
    include MongoMapper::Document

    key :collection_name, String
    key :last_update_on, Time

    def store_name
      "cohortly_report_#{self.id}"
    end    
  end
end

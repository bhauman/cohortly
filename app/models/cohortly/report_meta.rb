module Cohortly
  class ReportMeta
    include MongoMapper::Document

    key :collection_name, String
    key :last_update_on, Time

    def store_name
      "cohortly_report_#{self.id}"
    end

    def run
      args = Metric.report_name_to_args(self.collection_name)
      Cohortly::Metric.cohort_chart(*args)
    end
  end
end

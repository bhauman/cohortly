class Cohortly::MetricsController < Cohortly::CohortlyController
   def index
     @metrics = Cohortly::Metric.limit(250).sort(:created_at.desc).all
   end
end

class Cohortly::MetricsController < ApplicationController
   def index
     @metrics = Cohortly::Metric.limit(20).sort(:created_at.desc).all
   end
end
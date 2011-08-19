require 'mongo_mapper'
require "cohortly/engine"

MongoMapper.database = "cohortly-#{Rails.env}"

require "active_support/notifications"

ActiveSupport::Notifications.subscribe "cohortly.event" do |*args|
  Cohortly::Metric.store!(args)
end

module Cohortly

end
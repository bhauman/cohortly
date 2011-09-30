class Cohortly::CohortlyController < ApplicationController
  layout 'cohortly/application'
  before_filter do
    if self.respond_to? :cohortly_authenticate
      self.cohortly_authenticate
    end
  end
end

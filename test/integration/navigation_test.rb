require 'test_helper'

class NavigationTest < ActiveSupport::IntegrationCase
  test "" do
    assert_kind_of Dummy::Application, Rails.application
  end

  test "reporting navigation" do
    visit cohortly_reports_path
    
    
  end

end

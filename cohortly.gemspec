# -*- encoding: utf-8 -*-  
$:.push File.expand_path("../lib", __FILE__)  
require "cohortly/version"  
  
# Provide a simple gemspec so you can easily use your enginex
# project in your rails apps through git.
Gem::Specification.new do |s|
  s.name = "cohortly"
  s.summary = "Cohortly: the cohort analysis engine for Rails."
  s.description = "Cohortly records user actions and with minimal configuration allows you to get decent cohort analysis of ser activity."
  s.files = Dir["{app,lib,config}/**/*"] + ["MIT-LICENSE", "Rakefile", "Gemfile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]
  s.version = Cohortly::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Bruce Hauman"]
  s.email = ["bhauman@gmail.com"]
  s.homepage = 'https://github.com/bhauman/cohortly'
end

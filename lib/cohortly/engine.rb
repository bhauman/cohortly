module Cohortly
  class Engine < Rails::Engine
    initializer "read_config" do |app|
      config_file = File.join(Rails.root, 'config', 'cohortly.yml')
      if File.exists?(config_file)
        conf = YAML.load_file(config_file)[Rails.env]
        conf.keys.each do |k|
          Cohortly::Config.config.send("#{k}=", conf[k])
        end
      end
      p Cohortly::Config.config
    end
  end
end

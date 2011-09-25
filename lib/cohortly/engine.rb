module Cohortly
  class Engine < Rails::Engine
    initializer "read_config" do |app|
      config_file = File.join(Rails.root, 'config', 'cohortly.yml')
      if File.exists?(config_file)
        Cohortly::Config.config.tap do |cfg|
          conf = YAML.load_file(config_file)[Rails.env]
          conf.keys.each { |k| cfg.send("#{k}=", conf[k]) }          
          Cohortly::Metric.connection Mongo::Connection.new(cfg.host, cfg.port)
          Cohortly::Metric.set_database_name cfg.database
          Cohortly::Metric.database.authenticate(cfg.username, cfg.password) if(cfg.password)
        end        
      end
    end
  end
end

module Cohortly
  class Metric
    include MongoMapper::Document

    key :user_start_date, Time
    key :user_id, Integer
    key :user_email, String
    key :username, String    
    key :tags, Array
    key :controller, String
    key :action, String
    timestamps!

    ensure_index :tags
    
    def self.store!(args)
      data = args[4]
      data[:tags] = []
      if data[:controller]
        return if data[:controller]['cohortly']
        data[:tags] = Cohortly::TagConfig.tags_for(data[:controller], data[:action])
      end
      data[:user_email] = data[:email] if data[:email]
      data[:tags] += data[:add_tags] if data[:add_tags]
      create(data)
    end

    def self.cohort_chart_for_tag(tags = nil)
      query = {}
      query = { :tags => { :$all => tags } } if tags
      self.collection.map_reduce(self.month_map,
                                 self.reduce,
                                 { :out => self.report_table_name(tags),
                                   :raw => true,
                                   :query => query})  
    end

    def self.report_table_name(tags = nil)
      "cohort_report#{ tags ? "_#{ tags.sort.join('_') }" : '' }_#{ Time.now.strftime("%m-%d-%Y") }"
    end

    def self.month_map
      <<-JS
        function() {
          function get_month_date(date) {
            var year = date.getYear() + 1900;
            var month = date.getMonth() + 1;
            if(month < 10) { month = '0' + month }
            return year + '-' + month;
          }
          var start_date = get_month_date(this.user_start_date);
          var happened_on = get_month_date(this.created_at);
          var payload = {};
          payload[happened_on] = {};
          payload[happened_on][this.user_id] = 1;
          emit( start_date, payload );
        }
      JS
    end

    def self.reduce
      <<-JS
        function(key, values) {
          var result = {};
          values.forEach(function(value) {
            for(happened_date in value) {
                if(!result[happened_date]) {
                  result[happened_date] = value[happened_date];
                } else {
                  for(user_id in value[happened_date]) {
                    result[happened_date][user_id] = 1;
                  }
                }
            }
          });
          return result;
        }
      JS
    end

  end
end

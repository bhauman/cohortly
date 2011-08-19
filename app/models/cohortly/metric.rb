module Cohortly
  class Metric
    include MongoMapper::Document

    key :user_start_date, Time
    key :user_id, Integer
    key :user_email, String
    key :tags, Array
    key :controller, String
    key :action, String
    timestamps!

    def self.store!(args)
      create(args[4])
    end

    def self.cohort_chart_for_tag
      self.collection.map_reduce(self.month_map, self.reduce,  {:out => "cohort_report", :raw => true} )
    end

    def self.month_map
      <<-JS
        function() {
          function get_month_date(date) {
            var year = date.getYear() + 1900;
            var month = date.getMonth();
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
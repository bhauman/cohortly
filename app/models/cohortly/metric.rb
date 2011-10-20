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

    def self.weekly_cohort_chart_for_tag(tags = nil)
      query = {}
      query = { :tags => { :$all => tags } } if tags
      self.collection.map_reduce(self.week_map,
                                 self.reduce,
                                 { :out => self.report_table_name(tags, true),
                                   :raw => true,
                                   :query => query})  
    end
    
    def self.report_table_name(tags = nil, weekly = false)
      "cohort_report#{ tags ? "_#{ tags.sort.join('_') }" : '' }_#{ Time.now.strftime("%m-%d-%Y") }_#{ weekly ? 'weekly' : 'monthly'}"
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

     def self.week_map
      <<-JS
        function() {
          function getWeek(date) {
	    var dowOffset = 0;
	    var newYear = new Date(date.getFullYear(),0,1);
	    var day = newYear.getDay() - dowOffset;
	    day = (day >= 0 ? day : day + 7);
	    var daynum = Math.floor((date.getTime() - newYear.getTime() - 
	    (date.getTimezoneOffset()-newYear.getTimezoneOffset())*60000)/86400000) + 1;
	    var weeknum;
	    if(day < 4) {
	      weeknum = Math.floor((daynum+day-1)/7) + 1;
	      if(weeknum > 52) {
	        nYear = new Date(date.getFullYear() + 1,0,1);
		nday = nYear.getDay() - dowOffset;
		nday = nday >= 0 ? nday : nday + 7;
		weeknum = nday < 4 ? 1 : 53;
	      }
	    } else {
	      weeknum = Math.floor((daynum+day-1)/7);
	    }
	    return weeknum;
          }
          function get_week_date(date) {
            var year = date.getYear() + 1900;
            var week = getWeek(date);
            if(week < 10) { week = '0' + week }
            return year + '-' + week;
          }
          var start_date = get_week_date(this.user_start_date);
          var happened_on = get_week_date(this.created_at);
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

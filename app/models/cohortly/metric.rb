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
    ensure_index :user_start_date
    
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
    
    def self.cohort_chart(tags = nil, groups = nil, weekly = false)
      query = { }
      query = {:tags => { :$in => tags} } if tags
      if groups      
        query[:$where] = "function() { return #{ groups.collect {|x| 'this.tags.indexOf("' + x + '") >= 0'  }.join(' || ') }; }"
      end      
      collection_name = self.report_table_name(tags, groups, weekly)
      # incremental map_reduce pattern
      meta = Cohortly::ReportMeta.find_or_create_by_collection_name(collection_name)
      query[:created_at] = { :$gt => meta.last_update_on.utc } if meta.last_update_on
      self.collection.map_reduce(weekly ? self.week_map : self.month_map,
                                 self.reduce,
                                 { :out => meta.last_update_on ? { :reduce => meta.store_name } : meta.store_name,
                                   :raw => true,
                                   :query => query})        
      meta.last_update_on = Time.now.utc
      meta.save        
    end
    
    def self.cohort_chart_for_tag(tags = nil, groups = nil)
      self.cohort_chart(tags, groups, false)
    end

    def self.weekly_cohort_chart_for_tag(tags = nil, groups = nil)
      self.cohort_chart(tags, groups, true)      
    end
    
    def self.report_table_name(tags = nil, groups = nil, weekly = true)
      "cohortly_report#{ tags ? "-tags=#{ tags.sort.join(':') }" : '' }#{ groups ? "-groups=#{ groups.sort.join(':') }" : '' }#{ weekly ? '-weekly' : '-monthly'}"
    end
    
    def self.report_name_to_args(name)
      name = name.gsub(/^cohortly_report/, '')
      if name =~ /-weekly$/
        weekly = true
        name = name.gsub(/-weekly$/, '')
      else
        weekly = false
        name = name.gsub(/-monthly$/, '')        
      end
      tags = nil
      groups = nil
      if name.length > 0
        name = name.gsub(/-tags/, 'tags')
        tags, groups = name.split('-')        
        tags = tags.gsub(/tags=/, '').split(':')
        tags = tags.any? ? tags : nil        
        if groups
          groups = groups.gsub(/groups=/,'').split(':')              
          groups = groups.any? ? groups : nil                      
        end
      end
      [tags, groups, weekly] 
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
          var start_date = week_key(this.user_start_date);
          var happened_on = week_key(this.created_at);
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

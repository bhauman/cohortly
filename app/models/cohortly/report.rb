module Cohortly
  class Report
    # this is the reduced collection
    attr_accessor :collection, :weekly, :key_pattern, :groups, :tags, :report_meta
    def initialize( tags = nil, groups = nil, weekly = true )
      self.collection = Cohortly::Metric.report_table_name(tags, groups, weekly)
      self.report_meta = ReportMeta.find_or_create_by_collection_name(self.collection)
      self.groups = groups
      self.tags = tags
      self.weekly = weekly
      self.key_pattern = self.weekly ? "%Y-%W" : "%Y-%m"
    end

    def data
      @data ||= (Cohortly::Metric.database[self.report_meta.store_name].find().collect {|x| x}).sort_by {|x| x['_id'] }
    end

    def fix_data_lines
      data.each do |line|
        period_cohorts_from(line['_id']).collect do |key|
          if line["value"][key].nil?
            line["value"][key] = { }
          end
        end        
      end
    end
    
    def offset
      self.weekly ? 1.week : 1.month
    end
    
    def start_key
      data.first['_id']
    end

    def end_key
      time_to_key(Time.now.utc)
    end

    def time_to_key(time)
      time.strftime(self.key_pattern)
    end

    def key_to_time(report_key)
      DateTime.strptime(report_key, self.key_pattern).to_time.utc
    end

    def user_count_in_cohort(report_key)
      params = { :user_start_date => { :$gt => key_to_time(report_key),
                                       :$lt => (key_to_time(report_key) + 1.week)}}
      params[:tags] = { :$in => groups } if self.groups
      Cohortly::Metric.collection.distinct(:user_id, params).length
    end

    def period_cohorts
      return [] unless data.first
      start_time = key_to_time(start_key)
      end_time = key_to_time(end_key)
      cur_time = start_time
      res = [start_key]
      cur_time += self.offset
      while(cur_time < end_time) do
        res << time_to_key(cur_time)
        cur_time += self.offset
      end
      res
    end
    
    def period_cohorts_from(cohort_key)
      index = period_cohorts.index(cohort_key)
      period_cohorts[index..-1]
    end

    def report_line(cohort_key)
      line = data.find {|x| x['_id'] == cohort_key}
      return [] unless line
      period_cohorts_from(cohort_key).collect do |key|
        if line["value"][key]
          line["value"][key].keys.length
        else
          0
        end
      end
    end

    def percent_line(cohort_key)
      line = report_line(cohort_key)
      base = user_count_in_cohort(cohort_key)
      line.collect { |x| (x && base > 0.0 ) ? (x/base.to_f * 100).round : 0 }.unshift base
    end
    
    def report_totals
      period_cohorts.collect do |cohort_key|
        report_line(cohort_key)
      end
    end
    
    def base_n
      @base_n ||= self.period_cohorts.inject({ }) { |accum, key| accum[key] = user_count_in_cohort(key); accum  }
    end
    
    def as_json(*args)
      fix_data_lines
      { :name => report_meta.collection_name,
        :store_name => report_meta.store_name,
        :groups => self.groups,
        :tags   => self.tags,
        :weekly => self.weekly,
        :data => data,
        :base_n => base_n 
      }
    end
  end
end

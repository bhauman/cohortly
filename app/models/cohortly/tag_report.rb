module Cohortly
  class TagReport
    include MongoMapper::Document
    
    key :collection_name, String
    key :last_update_on, Time
    key :data, Hash
    key :tags, Array

    def run
      if self.last_update_on.nil?
        self.recalc_table 
      else
        self.update_table
      end
    end
    
    def tag_query
      self.tags.any? ? { :tags => self.tags } : { }  
    end
    
    def cell_query(cohort_range, cell_range)
      { :created_at => {
          :$gt => cell_range.begin,
          :$lt => cell_range.end},
        :user_start_date => {
          :$gt => cohort_range.begin,
          :$lt => cohort_range.end } }.tap { |x|
        self.tags ? x.merge( tag_query ) : x  
      }
    end

    def start_time
      Cohortly::Metric.where(tag_query).sort(:user_start_date).limit(1).first.user_start_date.utc.beginning_of_week
    end

    def cohort_iter(starting_time)
      cohort_time = starting_time
      while cohort_time <= Time.now
        yield cohort_time..(cohort_time + 1.week)
        cohort_time += 1.week
      end
    end
    
    def cell_iter(cell_starting_time)
      cohort_time = start_time
      while cohort_time <= Time.now
        cell_time = [cohort_time, cell_starting_time].max
        while cell_time <= Time.now
          store_cell cohort_time..(cohort_time + 1.week), cell_time..(cell_time + 1.week)
          cell_time += 1.week
        end
        cohort_time += 1.week
      end
    end

    def recalc_table
      self.last_update_on = Time.now
      self.cell_iter(self.start_time)
    end

    def update_table
      starting_time = self.last_update_on.utc.beginning_of_week
      self.last_update_on = Time.now      
      self.cell_iter(starting_time)
    end

    def store_cell(cohort_range, cell_range)
      cohort_key = cohort_range.begin.strftime('%Y-%W')
      cell_key = cell_range.begin.strftime('%Y-%W')        
      p cohort_key + " " + cell_key 
      self.data[cohort_key] ||= { }
      self.data[cohort_key][cell_key] ||= { }
      Cohortly::Metric.collection.distinct( :user_id, cell_query(cohort_range, cell_range) ).each do |user_id|
        self.data[cohort_key][cell_key][user_id.to_s] = 1
      end
    end

    def merge(report_meta)
      ReportMeta.new(:tags => self.tags + report_meta.tags,
                     :data => self.deep_merge(self.data, report_meta.data))
    end

    def deep_merge(data1, data2)
      (data1.keys + data2.keys).uniq.inject({}) do |accum, key|
        if (data1[key] || data2[key]).is_a?(Hash)
          accum[key] = deep_merge(data1[key] || { }, data2[key] || { })  
        else
          accum[key] = data1[key] || data2[key] 
        end
        accum
      end
    end
    
  end
end

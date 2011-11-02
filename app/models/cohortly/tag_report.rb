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
      self.tags.any? ? { :tags => self.tags.first } : { }  
    end
    
    def cell_query(cohort_range, cell_range)
      { :created_at => {
          :$gt => cell_range.begin,
          :$lt => cell_range.end},
        :user_start_date => {
          :$gt => cohort_range.begin,
          :$lt => cohort_range.end } }.tap { |x|
        self.tags ? x.merge!( tag_query ) : x  
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
          yield cohort_time..(cohort_time + 1.week), cell_time..(cell_time + 1.week)
          cell_time += 1.week
        end
        cohort_time += 1.week
      end
    end

    def recalc_table
      self.data = { }
      self.last_update_on = Time.now
      self.cell_iter(self.start_time) { |cohort_range, cell_range| self.store_cell(cohort_range, cell_range)}
    end

    def update_table
      starting_time = self.last_update_on.utc.beginning_of_week
      self.last_update_on = Time.now      
      self.cell_iter(starting_time) { |cohort_range, cell_range| self.store_cell(cohort_range, cell_range)} 
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
    
    def merge(tag_report)
      TagReport::Product.new(:tag_report => self, :tags => self.tags, :data => self.data).merge(tag_report)
    end
    
    class Product
      attr_accessor :tag_report, :tags, :data
      def initialize(options = { })
        self.tags = options[:tags]
        self.tag_report = options[:tag_report]
        self.data = options[:data]        
      end

      def merge(tag_report)
        TagReport::Product.new(:tag_report => self.tag_report,
                               :tags => self.tags | tag_report.tags,
                               :data => self.deep_merge(self.data, tag_report.data))
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
      
      # user_ids need to be strings
      def intersect(user_ids)
        self.tag_report.cell_iter(self.tag_report.start_time) do |cohort_range, cell_range|
          cohort_key = cohort_range.begin.strftime('%Y-%W')
          cell_key = cell_range.begin.strftime('%Y-%W')
          cell = self.data[cohort_key][cell_key]
          intersected_ids = cell.keys & user_ids
          self.data[cohort_key][cell_key] = intersected_ids.inject({ }) { |accum, user_id| accum.merge!(user_id => 1); accum }
        end
      end
      
      def data_without_empty_rows
        self.data.keys.sort.inject({ }) { |new_data, key| puts ; self.data[key].values.collect(&:length).sum > 0 ? new_data.merge(key => self.data[key]) : new_data }
      end
      
    end
  end
end

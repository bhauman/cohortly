module Cohortly
  class Report
    # this is the reduced collection
    attr_accessor :collection
    def initialize(collection)
      self.collection = collection
    end

    def data
      @data ||= (Cohortly::Metric.database[self.collection].find().collect {|x| x}).sort_by {|x| x['_id'] }
    end

    def start_month
      data.first['_id']
    end

    def end_month
      time_to_month(Time.now)
    end

    def time_to_month(time)
      time.strftime('%Y-%m')
    end

    def month_to_time(str_month)
      year, month = str_month.split('-')
      Time.utc(year.to_i, month.to_i)
    end

    def user_count_in_cohort(str_month)
      Cohortly::Metric.collection.distinct(:user_id,
                                           { :user_start_date => { :$gt => month_to_time(str_month),
                                                                   :$lt => (month_to_time(str_month) + 1.month)}}).length
    end

    def month_cohorts
      return [] unless data.first
      start_time = month_to_time(start_month)
      end_time = month_to_time(end_month)
      cur_time = start_time
      res = []
      while(cur_time <= end_time) do
        res << time_to_month(cur_time)
        cur_time += 1.month
      end
      res
    end

    def month_cohorts_from(cohort_key)
      index = month_cohorts.index(cohort_key)
      month_cohorts[index..-1]
    end

    def report_line(cohort_key)
      line = data.find {|x| x['_id'] == cohort_key}
      return [] unless line
      month_cohorts_from(cohort_key).collect do |key|
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
      month_cohorts.collect do |cohort_key|
        report_line(cohort_key)
      end
    end
  end
end

module Cohortly
  class StoredProcedures
    PROCS = [:day_of_year,
             :week_of_year,
             :week_key]
    
    def self.eval_js(javascript)
      Cohortly::Metric.database.eval(javascript)
    end

    def self.day_of_year
      <<-JS
      function(date) {
        var ms = date - new Date('' + date.getUTCFullYear() + '/1/1 UTC');
        return parseInt(ms / 60000 / 60 / 24, 10) + 1;
      }
    JS
    end

    def self.week_of_year
      <<-JS
      function(date) {
         var doy = day_of_year(date);
         var dow = date.getUTCDay();
         dow = ((dow === 0) ? 7 : dow);
         var rdow = 7 - dow;
         var woy = parseInt((doy + rdow) / 7, 10);
         return woy;
      }
    JS
    end

    def self.week_key
      <<-JS
      function(date) {
        var year = date.getYear() + 1900;
        var week = week_of_year(date);
        if(week < 10) { week = '0' + week }
        return year + '-' + week;                
      }
    JS
    end

    def self.store_procedures()
      PROCS.each do |proc_name|
        Cohortly::Metric.database.add_stored_function(proc_name.to_s, self.send(proc_name))
      end
    end

    def self.execute(proc_name, *args)
      Cohortly::Metric.database.eval(self.send(proc_name), *args)
    end
  end
end

module Superset
  module DuplicateDashboardLogger
   
    
    def logger
      @logger ||= begin
        if defined?(Rails)
          Rails.try(:logger) || Logger.new(STDOUT)
        else
          Logger.new(STDOUT)
        end
      end
    end
  end
end
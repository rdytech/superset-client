module Superset
  module Services
    class ReadDashboardConfig 

      attr_reader :path, :configs

      CONFIG_TYPES = %w(dashboards charts databases datasets)

      def initialize(path)
        @path = path
        @configs = {}
      end
    
      def perform
        init_config_hash

        CONFIG_TYPES.each do |type|

          config_files = Dir.glob(File.join("#{path}#{type}", '**', '*.yaml'))
          config_files.each do |config_file|
            puts "Reading config file: #{config_file}"
            config = YAML.load_file(config_file).with_indifferent_access
            @configs[type.to_sym] << {      
              config_file: config_file,
              config: config
            }
          
          end
        end
        @configs
      end

      def init_config_hash
        CONFIG_TYPES.each do |type|
          @configs[type.to_sym] = [ ]
        end
      end
    end
  end
end
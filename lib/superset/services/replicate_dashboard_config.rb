

# This class is responsible for copying, manipulating then saving the new configuration of a Superset dashboard.
# It reads the existing configuration files, updates the UUIDs, changes the dataset schema, validates the new configuration,
# and writes the updated configuration files to disk.

# Example call:
# config_path = "/path/to/config"
# target_schema = "new_schema"
# copy_dashboard_config = Superset::Services::CopyDashboardConfig.new(config_path: config_path, target_schema: target_schema)
# copy_dashboard_config.perform

module Superset
  module Services
    class ReplicateDashboardConfig

      attr_reader :config_path, :target_schema

      def initialize(config_path: , target_schema: )
        @config_path = config_path
        @target_schema = target_schema
      end

      def perform
        # read config files and store initial source_summary
        configs && source_summary

        # update with new uuids and store target_summary
        update_config_uuids && target_summary

        validate_new_config? && write_config_files

      end

      def write_config_files
        # write new config files from config  
        configs.each do |type, config_array|
          config_array.each do |config_hash|
            file_path = config_hash[:config_file]
            puts "Writing config file: #{file_path}"
            File.open(file_path, 'w') do |file|
              file.write(Psych.dump(config_hash[:config].to_hash))
            end
          end
        end
      end


      def validate_new_config?
        # compare source_summary and target_summary and raise error if any uuids match
        if target_summary[:dashboard_uuid] == source_summary[:dashboard_uuid]
          raise "Dashboard UUIDs should not match"
        # validate new dashboard chart layout uuids
        elsif !matching_dashboard_chart_layout_uuids.empty?
          raise "Dashboard chart layout UUIDs should not match"
        # validate new chart uuids
        elsif !matching_chart_uuids.empty?
          raise "Chart UUIDs should not match"
        elsif !matching_chart_dataset_uuids.empty?
          raise "Chart Dataset UUIDs should not match"
        else
          true
        end
        
      end

      def matching_dashboard_chart_layout_uuids
        # get the intersection of the dashboard chart layout uuids
        source_summary[:dashboard_charts_layout].sort_by { |hash| hash[:slice_name] }.map{|c| c[:uuid] } &
          target_summary[:dashboard_charts_layout].sort_by { |hash| hash[:slice_name] }.map{|c| c[:uuid] }
      end

      def matching_chart_uuids
        # get the intersection of the chart uuids
        source_summary[:charts].sort_by { |hash| hash[:slice_name] }.map{|c| c[:uuid] } &
          target_summary[:charts].sort_by { |hash| hash[:slice_name] }.map{|c| c[:uuid] }
      end

      def matching_chart_dataset_uuids
        # get the intersection of the chart uuids
        source_summary[:charts].sort_by { |hash| hash[:slice_name] }.map{|c| c[:dataset_uuid] } &
          target_summary[:charts].sort_by { |hash| hash[:slice_name] }.map{|c| c[:dataset_uuid] }
      end

      def update_config_uuids
        # loop through datasets .. and create new uuids, update schema and sql
        #   find each related charts and create new uuids, and update dataset uuids
        #   find the chart entry in the dashboard config and update the chart uuid
        # write new configs to new files

        configs[:datasets].each do |dataset|
          dataset_config = dataset[:config]
          previous_schema = dataset_config[:schema]
          previous_dataset_uuid = dataset_config[:uuid]

          new_dataset_uuid = SecureRandom.uuid
          dataset_config[:uuid] = new_dataset_uuid             # new_dataset_uuid

          dataset_config[:schema] = target_schema
          dataset_config[:sql] = dataset_config[:sql].gsub(previous_schema, target_schema)

          configs[:charts].each do |chart|
            chart_config = chart[:config]
            #only update chart if its dataset_uuid matches the previous_dataset_uuid
            if chart_config[:dataset_uuid] == previous_dataset_uuid
              chart_config[:dataset_uuid] = new_dataset_uuid  # charts FK for new_dataset_uuid
              previous_chart_uuid = chart_config[:uuid]
              new_chart_uuid = SecureRandom.uuid
              chart_config[:uuid] = new_chart_uuid            # new_chart_uuid chart update

              # find and update dashboard->position->children config for chart from previous_chart_uuid to new_chart_uuid
              configs[:dashboards].each do |dashboard|
                dashboard[:config][:position].each do |chart_layout|
                  if chart_layout[0].start_with?('CHART') && chart_layout[1][:meta][:uuid] == previous_chart_uuid
                    chart_layout[1][:meta][:uuid] = new_chart_uuid
                  end
                end
              end
            end
          end
        end

        configs[:dashboards].first[:config][:uuid] = SecureRandom.uuid # new_dashboard_uuid
      end

      # summary used for a before and after comparison
      def summary
        result = {}

        # details for dashboard and chart layouts 
        dashboard = configs[:dashboards].first # only one dashboard
        result[:dashboard_uuid] = dashboard[:config][:uuid]
        # dashboard charts layout
        dashboard_charts_layout = dashboard[:config][:position].select { |item| item.include?('CHART') }
        result[:dashboard_charts_layout] =
          dashboard_charts_layout.map do |chart|
            { 
              slice_name: chart[1][:meta][:sliceName],
              uuid: chart[1][:meta][:uuid],
              # chartId: chart[1][:meta][:chartId],
              # id: chart[1][:id],
            }
          end
        # details for charts
        result[:charts] = 
          configs[:charts].map do |chart|
            { 
              slice_name: chart[:config][:slice_name], 
              uuid: chart[:config][:uuid],
              dataset_uuid: chart[:config][:dataset_uuid]
            }
          end

        # details for datasets
        result[:datasets] = 
          configs[:datasets].map do |dataset|
            { 
              table_name: dataset[:config][:table_name], 
              uuid: dataset[:config][:uuid],
              schema: dataset[:config][:schema],
              sql: dataset[:config][:sql],
              database_uuid: dataset[:config][:database_uuid]
            }
          end
        # details for databases, UUID SHOULD NOT CHANGE FOR THE DATABASE !!!
        # ie we point to the same database, just a different schema
        result[:databases] = 
          configs[:databases].map do |database|
            { 
              uuid: database[:config][:uuid],
              database_name: database[:config][:database_name]
            }
          end
        result
      end

      def source_summary
        @source_summary ||= summary
      end

      def target_summary
        @target_summary ||= summary
      end

      def configs
        @configs ||= ReadDashboardConfig.new(config_path).perform
      end
    end
  end
end
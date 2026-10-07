# frozen_string_literal: true

# WARNING: DESTRUCTIVE OPERATION .. use with caution
# This class is used to delete multiple dashboards and all related charts and datasets.
# There are NO CHECKS currently to confirm if a dataset is used on other dashboards.

module Superset
  module Dashboard
    class BulkDeleteCascade
      class InvalidParameterError < StandardError; end

      attr_reader :dashboard_ids, :dry_run

      def initialize(dashboard_ids: [], dry_run: true)
        @dashboard_ids = dashboard_ids
        @dry_run = dry_run
      end

      def perform
        raise InvalidParameterError, "dashboard_ids array of integers expected" unless dashboard_ids.is_a?(Array)
        raise InvalidParameterError, "dashboard_ids array must contain Integer only values" unless dashboard_ids.all? { |item| item.is_a?(Integer) }

        dashboard_ids.sort.each do |dashboard_id|
          chart_ids = retrieve_chart_ids(dashboard_id)
          dataset_ids = retrieve_dataset_ids(dashboard_id)

          log_msg("------------------------- DRY RUN ONLY ---------------------------") if dry_run
          log_msg("Dashboard Id: #{dashboard_id.to_s} Attempting CASCADE delete of dashboard, charts, datasets")
          log_msg("  Charts: #{chart_ids.sort.join(', ')}")
          log_msg("  Datasets: #{dataset_ids.sort.join(', ')}")

          delete_charts(chart_ids)
          delete_datasets(dataset_ids)
          delete_dashboard(dashboard_id)
        end
        true
      end

      private

      def delete_datasets(dataset_ids)
        Superset::Dataset::BulkDelete.new(dataset_ids: dataset_ids).perform if dataset_ids.any? && !dry_run
      end

      def delete_charts(chart_ids)
        Superset::Chart::BulkDelete.new(chart_ids: chart_ids).perform if chart_ids.any? && !dry_run
      end

      def delete_dashboard(dashboard_id)
        Superset::Dashboard::Delete.new(dashboard_id: dashboard_id, confirm_zero_charts: true).perform if !dry_run
      end

      def retrieve_chart_ids(dashboard_id)
        Superset::Dashboard::Charts::List.new(dashboard_id).chart_ids
      end

      def retrieve_dataset_ids(dashboard_id)
        Superset::Dashboard::Datasets::List.new(dashboard_id: dashboard_id).ids
      end

      def log_msg(message)
        puts message
        logger.info(message)
      end

      def logger
        @logger ||= Superset::Logger.new
      end
    end
  end
end

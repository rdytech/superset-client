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
          logger.info("Dashboard Id: #{dashboard_id.to_s} Attempting CASCADE delete of dashboard, charts, datasets")
          delete_charts(dashboard_id)
          delete_datasets(dashboard_id)
          delete_dashboard(dashboard_id)
        end
        true
      end

      private

      def delete_datasets(dashboard_id)
        datasets_to_delete = Superset::Dashboard::Datasets::List.new(dashboard_id: dashboard_id).datasets_details.map{|d| d[:id] }
        if dry_run
          logger.info("  NOTICE: Dry run only. Would delete datasets: #{datasets_to_delete.join(', ')}")
        else
          Superset::Dataset::BulkDelete.new(dataset_ids: datasets_to_delete).perform if datasets_to_delete.any?
        end
      end

      def delete_charts(dashboard_id)
        charts_to_delete = Superset::Dashboard::Charts::List.new(dashboard_id).chart_ids
        if dry_run
          logger.info("  NOTICE: Dry run only. Would delete charts: #{charts_to_delete.join(', ')}")
        else
          Superset::Chart::BulkDelete.new(chart_ids: charts_to_delete).perform if charts_to_delete.any?
        end
      end

      def delete_dashboard(dashboard_id)
        if dry_run
          logger.info("  NOTICE: Dry run only. Would delete dashboard: #{dashboard_id}")
        else
          Superset::Dashboard::Delete.new(dashboard_id: dashboard_id, confirm_zero_charts: true).perform
        end
      end

      def logger
        @logger ||= Superset::Logger.new
      end
    end
  end
end

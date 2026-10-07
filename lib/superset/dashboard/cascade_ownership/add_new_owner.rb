module Superset
  module Dashboard
    module CascadeOwnership
      class AddNewOwner < Superset::Request
        attr_reader :dashboard_id, :user_id

        def initialize(dashboard_id:, user_id:)
          @dashboard_id = dashboard_id
          @user_id = user_id
        end

        def perform
          raise "Error: dashboard_id integer is required" unless dashboard_id.present? && dashboard_id.is_a?(Integer)
          raise "Error: user_id integer is required" unless user_id.present? && user_id.is_a?(Integer)

          add_user_to_dashboard_ownership
          add_user_to_charts_ownership
          add_user_to_datasets_ownership
        end

        private

        def add_user_to_dashboard_ownership
          return if current_dashboard_owner_ids.include?(user_id)
          Superset::Dashboard::Put.new(target_id: dashboard_id, params: { "owners":  current_dashboard_owner_ids << user_id }).perform
        end

        def add_user_to_charts_ownership
          chart_ids = Superset::Dashboard::Charts::List.new(dashboard_id).ids
          chart_ids.each do |chart_id|
            current_chart_owner_ids = Superset::Chart::Get.new(chart_id).result['owners'].map{|c| c['id']}
            next if current_chart_owner_ids.include?(user_id)

            Superset::Chart::Put.new(target_id: chart_id, params: { "owners":  current_chart_owner_ids << user_id }).perform
          end
        end

        def add_user_to_datasets_ownership
          dataset_ids = Superset::Dashboard::Datasets::List.new(dashboard_id: dashboard_id, include_filter_datasets: true).ids
          dataset_ids.each do |dataset_id|
            current_dataset_owner_ids = Superset::Dataset::Get.new(dataset_id).result['owners'].map{|c| c['id']}
            next if current_dataset_owner_ids.include?(user_id)

            Superset::Dataset::Put.new(target_id: dataset_id, params: { "owners":  current_dataset_owner_ids << user_id }).perform
          end
        end

        def current_dashboard_owner_ids
          @current_dashboard_owner_ids ||= Superset::Dashboard::Get.new(dashboard_id).result['owners'].map{|i| i['id'] }
        end
      end
    end
  end
end

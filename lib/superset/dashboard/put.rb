
# frozen_string_literal: true

# Usage:
# params = { owners: [ 58, 3 ] }
# Superset::Dashboard::Put.new(target_id: 101, params: params ).perform

module Superset
  module Dashboard
    class Put < Superset::BasePutRequest

      private

      def route
        "dashboard/#{target_id}"
      end
    end
  end
end

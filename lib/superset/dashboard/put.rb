
# frozen_string_literal: true

# Example Usage: Update Dashboard Ownership to a new set of users
# this will override the existing owners and set the new owners
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

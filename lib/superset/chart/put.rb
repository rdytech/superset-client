# Updates a chart in Superset with the given params
#
# Usage:
# params = { owners: [ 58, 3 ] }
# Superset::Chart::Put.new(object_id: 202, params: params ).perform

module Superset
  module Chart
    class Put < Superset::BasePutRequest

      private

      def route
        "chart/#{object_id}"
      end
    end
  end
end

# Updates a dataset in Superset with the given params
#
# Usage:
# params = { owners: [ 58, 3 ] }
# Superset::Dataset::Put.new(object_id: 101, params: params ).perform

module Superset
  module Dataset
    class Put < Superset::BasePutRequest

      private

      def route
        "dataset/#{object_id}"
      end
    end
  end
end

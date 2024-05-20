# The API demands that the new_dataset_name be uniq within the schema it points to.
# same behaviour as in the GUI

module Superset
  module Dataset
    class Create < Superset::Request

      attr_reader :target_database_id, :new_dataset_name, :new_dataset_schema, :sql

      def initialize(target_database_id: , new_dataset_name: , new_dataset_schema: 'public', sql: )
        @target_database_id = target_database_id
        @new_dataset_name = new_dataset_name
        @new_dataset_schema = new_dataset_schema
        @sql = sql
      end

      def perform
        raise "Error: target_database_id integer is required" unless target_database_id.present? && target_database_id.is_a?(Integer)
        raise "Error: new_dataset_name string is required" unless new_dataset_name.present? && new_dataset_name.is_a?(String)
        raise "Error: Dataset Name #{new_dataset_name} is already in use in the schema: #{new_dataset_schema}. Suggest you add (COPY) as a suffix to the name" if new_dataset_name_already_in_use?
        raise "Error: sql string is required" unless sql.present? && sql.is_a?(String)

        logger.info("Creating New Dataset #{new_dataset_name} in DB #{target_database_id} Schema #{new_dataset_schema}")

        response
        { id: response['id'], dataset_name: response['data']['datasource_name'] }
      end

      def response
        @response ||= client.post(route, params)
      end

      def params
        {
          "schema": new_dataset_schema,
          "sql": sql,
          "table_name": new_dataset_name,
          "database": target_database_id

          # Optional Params .. pulled straight from the GUI swagger example

          #"always_filter_main_dttm": false,
          #"external_url": "string",
          #"is_managed_externally": false,
          #"normalize_columns": false,
          # "owners": [ 0 ],
        }
      end

      private

      # The API demands that the new_dataset_name be uniq within the schema it points to.
      def new_dataset_name_already_in_use?
        Dataset::List.new(title_equals: new_dataset_name, schema_equals: new_dataset_schema, database_id_eq: target_database_id).result.any?
      end

      def route
        "dataset/"
      end
    end
  end
end

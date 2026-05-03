# frozen_string_literal: true

# Upload a CSV file to a database table via the Superset API.
#
# Usage:
#   Superset::Database::UploadCsv.new(
#     database_id: 1,
#     file: "/path/to/data.csv",
#     table_name: "my_table"
#   ).perform
#
#   # With optional params:
#   Superset::Database::UploadCsv.new(
#     database_id: 1,
#     file: "/path/to/data.csv",
#     table_name: "my_table",
#     already_exists: "replace",
#     schema: "public",
#     delimiter: ","
#   ).perform

module Superset
  module Database
    class UploadCsv < Request
      ALREADY_EXISTS_OPTIONS = %w[fail replace append].freeze

      attr_reader :database_id, :file, :table_name, :already_exists, :column_data_types,
                  :column_dates, :columns_read, :dataframe_index, :day_first,
                  :decimal_character, :delimiter, :header_row, :index_column,
                  :index_label, :null_values, :rows_to_read, :schema, :sheet_name,
                  :skip_blank_lines, :skip_initial_space, :skip_rows

      def initialize(
        database_id:,
        file:,
        table_name:,
        already_exists: nil,
        column_data_types: nil,
        column_dates: nil,
        columns_read: nil,
        dataframe_index: nil,
        day_first: nil,
        decimal_character: nil,
        delimiter: nil,
        header_row: nil,
        index_column: nil,
        index_label: nil,
        null_values: nil,
        rows_to_read: nil,
        schema: nil,
        sheet_name: nil,
        skip_blank_lines: nil,
        skip_initial_space: nil,
        skip_rows: nil
      )
        @database_id      = database_id
        @file             = file
        @table_name       = table_name
        @already_exists   = already_exists
        @column_data_types  = column_data_types
        @column_dates     = column_dates
        @columns_read     = columns_read
        @dataframe_index  = dataframe_index
        @day_first        = day_first
        @decimal_character = decimal_character
        @delimiter        = delimiter
        @header_row       = header_row
        @index_column     = index_column
        @index_label      = index_label
        @null_values      = null_values
        @rows_to_read     = rows_to_read
        @schema           = schema
        @sheet_name       = sheet_name
        @skip_blank_lines = skip_blank_lines
        @skip_initial_space = skip_initial_space
        @skip_rows        = skip_rows
      end

      def perform
        validate_params
        response
      end

      def response
        @response ||= client(use_json: false).post(route, payload)
      end

      def result
        response['message']
      end

      private

      def validate_params
        raise ArgumentError, "database_id is required" if database_id.nil?
        raise ArgumentError, "file is required" if file.nil?
        raise ArgumentError, "file does not exist" unless File.exist?(file)
        raise ArgumentError, "table_name is required" if table_name.nil? || table_name.strip.empty?

        if already_exists && !ALREADY_EXISTS_OPTIONS.include?(already_exists)
          raise ArgumentError, "already_exists must be one of: #{ALREADY_EXISTS_OPTIONS.join(', ')}"
        end
      end

      def payload
        p = {
          file:       Faraday::UploadIO.new(file, "text/csv"),
          table_name: table_name,
          type:       "csv"
        }

        p[:already_exists]    = already_exists                    if already_exists
        p[:column_data_types] = column_data_types.to_json         if column_data_types
        p[:column_dates]      = column_dates                      if column_dates
        p[:columns_read]      = columns_read                      if columns_read
        p[:dataframe_index]   = dataframe_index.to_s              unless dataframe_index.nil?
        p[:day_first]         = day_first.to_s                    unless day_first.nil?
        p[:decimal_character] = decimal_character                 if decimal_character
        p[:delimiter]         = delimiter                         if delimiter
        p[:header_row]        = header_row                        unless header_row.nil?
        p[:index_column]      = index_column                      if index_column
        p[:index_label]       = index_label                       if index_label
        p[:null_values]       = null_values                       if null_values
        p[:rows_to_read]      = rows_to_read                      unless rows_to_read.nil?
        p[:schema]            = schema                            if schema
        p[:sheet_name]        = sheet_name                        if sheet_name
        p[:skip_blank_lines]  = skip_blank_lines.to_s             unless skip_blank_lines.nil?
        p[:skip_initial_space] = skip_initial_space.to_s          unless skip_initial_space.nil?
        p[:skip_rows]         = skip_rows                         unless skip_rows.nil?

        p
      end

      def route
        "database/#{database_id}/upload/"
      end
    end
  end
end

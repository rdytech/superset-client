module Superset
  module Display
    def list
      puts table.to_s
    end

    def table
      Terminal::Table.new(
        title: title,
        headings: headings,
        rows: rows
      )
    end

    def rows
      result.map do |d|
        list_attributes.map { |la| d[la].to_s }
      end
    end

    def rows_hash
      rows.map { |value| list_attributes.zip(value).to_h }
    end

    def title
      self.class.to_s
    end

    def headings
      headings = display_headers ? display_headers : list_attributes
      headings.map(&:to_s).map(&:humanize)
    end

    def display_headers
      # optionally override this method to display custom headers
    end

    def list_attributes
      raise NotImplementedError.new("You must implement list_attributes.")
    end

    def result
      raise NotImplementedError.new("You must implement result.")
    end
  end
end

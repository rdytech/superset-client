module Superset
  module Display
    def list
      puts table.to_s
    end

    def table
      Terminal::Table.new(
        title: title,
        headings: list_attributes.map(&:to_s).map(&:humanize),
        rows: rows
      )
    end

    def rows
      to_h.map { |d| list_attributes.map { |la| d[la].to_s } }
    end

    def to_h
      if result.is_a?(Hash)
        list_attributes.to_h { |la| [la, result[la]] }
      else
        result.map do |d|
          list_attributes.to_h { |la| [la, d[la]] }
        end
      end
    end

    def title
      self.class.to_s
    end

    def list_attributes
      raise NotImplementedError.new("You must implement list_attributes.")
    end

    def result
      raise NotImplementedError.new("You must implement result.")
    end
  end
end

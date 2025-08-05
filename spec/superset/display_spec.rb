require 'spec_helper'

RSpec.describe Superset::Display do
  let(:dummy_class) { Class.new { include Superset::Display } }
  let(:dummy_instance) { dummy_class.new }
  let(:result) { [{ 'foo' => 1, 'bar' => 2, 'baz' => 3 }, { 'foo' => 4, 'bar' => 5, 'baz' => 6 }] }
  let(:list_attributes) { ['foo', 'bar', 'baz'] }

  before do
    allow(dummy_instance).to receive(:list_attributes).and_return(list_attributes)
    allow(dummy_instance).to receive(:result).and_return(result)
    allow(dummy_instance).to receive(:title).and_return('Dummy Class')
  end

  describe "#list" do
    it "displays a table with the correct title, headings, and rows" do
      expect(dummy_instance.table.to_s).to eq(
        "+-----------------+\n" \
        "|   Dummy Class   |\n" \
        "+-----+-----+-----+\n" \
        "| Foo | Bar | Baz |\n" \
        "+-----+-----+-----+\n" \
        "| 1   | 2   | 3   |\n" \
        "| 4   | 5   | 6   |\n" \
        "+-----+-----+-----+"
      )
    end
  end

  describe "#headings" do
    context "when display_headers is defined" do
      let(:display_headers) { ['foo', 'bar', 'baz_be_boo'] }

      before do
        allow(dummy_instance).to receive(:display_headers).and_return(display_headers)
      end

      it "returns the display_headers array with humanized values" do
        expect(dummy_instance.headings).to eq(["Foo", "Bar", "Baz be boo"])
      end
    end

    context "when display_headers is not defined" do
      it "returns the list_attributes array with humanized values" do
        expect(dummy_instance.headings).to eq(["Foo", "Bar", "Baz"])
      end
    end
  end

  describe "#rows" do
    it "returns an array of arrays containing the values of each list_attribute for each result" do
      expect(dummy_instance.rows).to eq([['1', '2', '3'], ['4', '5', '6']])
    end
  end

  describe "#display_headers" do
    it "returns nil by default" do
      expect(dummy_instance.display_headers).to be_nil
    end
  end
end

require 'spec_helper'

RSpec.describe Superset::Display do
  let(:dummy_class) { Class.new { include Superset::Display } }
  let(:dummy_instance) { dummy_class.new }
  let(:result) { [{ 'foo' => 1, 'bar' => 2, 'baz' => 3, 'qux' => 4 }, { 'foo' => 4, 'bar' => 5, 'baz' => 6, 'qux' => 8 }] }
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

  describe "#rows" do
    it "returns an array of arrays containing the values of each list_attribute for each result" do
      expect(dummy_instance.rows).to eq([['1', '2', '3'], ['4', '5', '6']])
    end
  end

  describe "#to_h" do
    it "returns an array of hashes with list_attributes as keys and corresponding result values" do
      expect(dummy_instance.to_h).to eq([
        { 'foo' => 1, 'bar' => 2, 'baz' => 3 },
        { 'foo' => 4, 'bar' => 5, 'baz' => 6 }
      ])
    end
  end

  describe "#list_attributes" do
    it "raises NotImplementedError" do
      allow(dummy_instance).to receive(:list_attributes).and_call_original
      expect { dummy_instance.list_attributes }.to raise_error(NotImplementedError, "You must implement list_attributes.")
    end
  end

  describe "#result" do
    it "raises NotImplementedError" do
      allow(dummy_instance).to receive(:result).and_call_original
      expect { dummy_instance.result }.to raise_error(NotImplementedError, "You must implement result.")
    end
  end
end

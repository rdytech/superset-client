require 'spec_helper'

RSpec.describe Superset::Tag::GetObjects do
  subject { described_class.new(tag_id) }
  let(:tag_id) { 5 }
  let(:result) do
    [
      {
        "id" => 1,
        "name" => "Sales Dashboard",
        "type" => "dashboard",
        "url" => "/dashboard/1",
        "changed_on" => "2026-05-07T22:05:09.195Z",
        "creator" => "Jon B",
        "created_by" => { "first_name" => "Jon", "id" => 9, "last_name" => "B" },
        "owners" => [],
        "tags" => [{ "id" => 5, "name" => "finance", "type" => "CustomTag" }]
      },
      {
        "id" => 42,
        "name" => "Revenue Chart",
        "type" => "chart",
        "url" => "/chart/42",
        "changed_on" => "2026-05-06T10:00:00.000Z",
        "creator" => "Jane D",
        "created_by" => { "first_name" => "Jane", "id" => 3, "last_name" => "D" },
        "owners" => [],
        "tags" => [{ "id" => 5, "name" => "finance", "type" => "CustomTag" }]
      }
    ]
  end

  before do
    allow(subject).to receive(:result).and_return(result)
  end

  describe '#rows' do
    it 'returns id, name, type, url for each tagged object' do
      expect(subject.rows).to match_array([
        ["1", "Sales Dashboard", "dashboard", "/dashboard/1"],
        ["42", "Revenue Chart", "chart", "/chart/42"]
      ])
    end
  end
end

require 'spec_helper'

RSpec.describe Superset::Chart::Get do
  subject { described_class.new(id) }
  let(:id) { 54507 }
  let(:result) do
    [{
      "cache_timeout"=>nil,
      "certification_details"=>nil,
      "certified_by"=>nil,
      "changed_on_delta_humanized"=>"14 days ago",
      "dashboards"=>[],
      "description"=>nil,
      "id"=>54507,
      "is_managed_externally"=>false,
      "owners"=>[{"first_name"=>"Jonathon", "id"=>9, "last_name"=>"Batson"}],
      "params"=>"{}",
      "query_context"=>nil,
      "slice_name"=>"JRStg DoB per Year",
      "tags"=>[{"id"=>1, "name"=>"owner:9", "type"=>3}, {"id"=>28, "name"=>"type:chart", "type"=>2}],
      "thumbnail_url"=>"/api/v1/chart/54507/thumbnail/1595a10937091faff0aed5df628a1292/",
      "url"=>"/explore/?slice_id=54507",
      "viz_type"=>"echarts_timeseries_bar"
    }]
  end

  before do
    allow(subject).to receive(:result).and_return([result])
  end

  describe '.call' do
    specify do
      expect_any_instance_of(described_class).to receive(:list) 
      described_class.call(id)
    end
  end

  describe '#rows' do
    specify do
      [["54507", "JRStg DoB per Year", "[{\"first_name\"=>\"Jonathon\", \"id\"=>9, \"last_name\"=>\"Batson\"}]", "[]"]]
    end
  end
end

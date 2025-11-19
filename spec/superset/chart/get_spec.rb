require 'spec_helper'

RSpec.describe Superset::Chart::Get do
  subject { described_class.new(id) }
  let(:id) { 54507 }
  let(:datasource_id) { 299 }
  let(:params) { "{\"datasource\":\"#{datasource_id}__table\"}" }
  let(:query_context) { "{\"datasource\":{\"id\":#{datasource_id},\"type\":\"table\"}}" }
  let(:result) do
    {
      "cache_timeout"=>nil,
      "certification_details"=>nil,
      "certified_by"=>nil,
      "changed_on_delta_humanized"=>"14 days ago",
      "dashboards"=>[],
      "description"=>nil,
      "id"=>54507,
      "is_managed_externally"=>false,
      "owners"=>[{"first_name"=>"Jay", "id"=>9, "last_name"=>"Bee"}, {"first_name"=>"Ron", "id"=>8, "last_name"=>"Vee"}],
      "params"=>params,
      "query_context"=>query_context,
      "slice_name"=>"JRStg DoB per Year",
      "tags"=>[{"id"=>1, "name"=>"owner:9", "type"=>3}, {"id"=>28, "name"=>"type:chart", "type"=>2}],
      "thumbnail_url"=>"/api/v1/chart/54507/thumbnail/1595a10937091faff0aed5df628a1292/",
      "url"=>"/explore/?slice_id=54507",
      "viz_type"=>"echarts_timeseries_bar"
    }
  end

  before do
    allow(subject).to receive(:result).and_return(result)
  end

  describe '.call' do
    specify do
      expect_any_instance_of(described_class).to receive(:list) 
      described_class.call(id)
    end
  end

  describe '#rows' do
    specify do
      expect(subject.rows).to eq [
        "54507", 
        "JRStg DoB per Year", 
        "[{\"first_name\"=>\"Jay\", \"id\"=>9, \"last_name\"=>\"Bee\"}, {\"first_name\"=>\"Ron\", \"id\"=>8, \"last_name\"=>\"Vee\"}]"
      ]
    end
  end

  describe '#datasource_id' do
    context 'with query_context containing the datasource_id' do
      specify do
        expect(subject.datasource_id).to eq(datasource_id)
      end
    end
 
    context 'with query_context not containing the datasource_id' do
      let(:query_context) { "{}" }
      let(:datasource_id) { 300 }

      specify 'reverts to params datasource' do
        expect(subject.datasource_id).to eq(datasource_id)
      end
    end

    context 'with params and query context empty' do
      let(:params) { "{}" }
      let(:query_context) { "{}" }

      specify 'reverts to params datasource' do
        expect(subject.datasource_id).to eq(nil)
      end
    end
  end

  describe '#owner_ids' do
    specify do
      expect(subject.owner_ids).to match_array([9,8])
    end
  end

  describe '#params' do
    specify do
      expect(subject.params).to eq(JSON.parse(params))
    end
  end

  describe '#query_context' do
    specify do
      expect(subject.query_context).to eq(JSON.parse(query_context))
    end
  end
end
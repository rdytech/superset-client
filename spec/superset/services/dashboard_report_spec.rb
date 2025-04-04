require 'spec_helper'

RSpec.describe Superset::Services::DashboardReport do
  let(:dashboard_ids) { [1] }
  let(:service) { described_class.new(dashboard_ids: dashboard_ids) }

    describe '#perform' do
    let(:dashboard_response) do
      {
        'dashboard_title' => 'Test Dashboard',
        'tags' => [{'name' => 'tag1'}, {'name' => 'tag2'}],
        'json_metadata' => {
          'native_filter_configuration' => [
            {
              'type' => 'NATIVE_FILTER',
              'targets' => [{'datasetId' => 100}]
            }
          ],
          'chart_configuration' => [{}, {}]
        }.to_json
      }
    end

    let(:datasets_response) do
      [
        {id: 1, schema: 'schema1', title: 'Dataset 1'},
        {id: 2, schema: 'schema1', title: 'Dataset 2'}
      ]
    end

    before do
#      allow(ENV).to receive(:[]).with('SUPERSET_HOST').and_return('http://example.com/')
      allow_any_instance_of(Superset::Dashboard::Get).to receive(:result).and_return(dashboard_response)
      allow_any_instance_of(Superset::Dashboard::Get).to receive(:url).and_return('http://example.com/dashboard/1')
      allow(Superset::Dashboard::Datasets::List).to receive(:new).with(dashboard_id: 1, include_filter_datasets: true).and_return(
        instance_double(Superset::Dashboard::Datasets::List, rows_hash: datasets_response)
      )     

      allow(Superset::Dataset::Get).to receive(:new).with(100).and_return(
        instance_double(Superset::Dataset::Get,
          result: { 'id' => 100, 'title' => "Dataset 1" },
          id: 100,
          title: "Dataset 1"
        )
      )
    end

    context 'when report_on_data_sovereignty_only is true' do
      it 'returns data sovereignty issues only' do
        result = service.perform
        
        expect(result).to be_an(Array)
        expect(result).to all(include(:reasons, :dashboard))
      end
    end

    context 'when report_on_data_sovereignty_only is false' do
      let(:service) { described_class.new(dashboard_ids: dashboard_ids, report_on_data_sovereignty_only: false) }
      
      it 'returns full dashboard report' do
        result = service.perform
        expect(result).to be_an(Array)
        expect(result.first).to include(
          :dashboard_id,
          :dashboard_title,
          :dashboard_url,
          :dashboard_tags,
          :filters,
          :charts,
          :datasets
        )
      end
    end
  end

  describe '#data_sovereignty_issues' do
    context 'when filter dataset is not in chart datasets' do
      let(:dashboard_response) do
        {
          'dashboard_title' => 'Test Dashboard',
          'tags' => [],
          'json_metadata' => {
            'native_filter_configuration' => [
              {
                'type' => 'NATIVE_FILTER',
                'targets' => [{'datasetId' => 999}]
              }
            ],
            'chart_configuration' => []
          }.to_json
        }
      end

      let(:datasets_response) do
        [
          {id: 1, schema: 'schema1', title: 'Dataset 1'}
        ]
      end

      before do
        allow_any_instance_of(Superset::Dashboard::Get).to receive(:result).and_return(dashboard_response)
        allow_any_instance_of(Superset::Dashboard::Get).to receive(:url).and_return('http://example.com/dashboard/1')
        allow(Superset::Dashboard::Datasets::List).to receive(:new).with(dashboard_id: anything, include_filter_datasets: true).and_return(
          instance_double(Superset::Dashboard::Datasets::List, rows_hash: datasets_response)
        )
        allow_any_instance_of(Superset::Dataset::Get).to receive(:result)
        allow_any_instance_of(Superset::Dataset::Get).to receive(:id).and_return(999)
        allow_any_instance_of(Superset::Dataset::Get).to receive(:title).and_return('Unknown Dataset')
      end

      it 'reports warning for unknown filter datasets' do
        result = service.perform
        expect(result.first[:reasons]).to include(a_string_matching(/WARNING: One or more filter datasets/))
      end
    end

    context 'when multiple schemas are found' do
      let(:datasets_response) do
        [
          {id: 1, schema: 'schema1', title: 'Dataset 1'},
          {id: 2, schema: 'schema2', title: 'Dataset 2'}
        ]
      end

      before do
        allow_any_instance_of(Superset::Dashboard::Get).to receive(:result).and_return(
          {
            'dashboard_title' => 'Test Dashboard',
            'tags' => [],
            'json_metadata' => {
              'native_filter_configuration' => [],
              'chart_configuration' => [{}, {}]
            }.to_json
          }
        )
        allow_any_instance_of(Superset::Dashboard::Get).to receive(:url).and_return('http://example.com/dashboard/1')
        allow(Superset::Dashboard::Datasets::List).to receive(:new).with(dashboard_id: anything, include_filter_datasets: true).and_return(
          instance_double(Superset::Dashboard::Datasets::List, rows_hash: datasets_response)
        )
      end

      it 'reports error for multiple schemas' do
        result = service.perform
        expect(result.first[:reasons]).to include(a_string_matching(/ERROR: Multiple distinct chart dataset schemas/))
      end
    end
  end


    
end

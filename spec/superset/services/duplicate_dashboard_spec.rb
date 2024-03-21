require 'spec_helper'
require 'superset/services/duplicate_dashboard'

RSpec.describe Superset::Services::DuplicateDashboard do
  subject { described_class.new(
              source_dashboard_id: source_dashboard_id,
              target_schema:       target_schema,
              target_database_id:  target_database_id) }

  let(:source_dashboard_id) { 1 }
  let(:target_schema) { 'schema_one' }
  let(:target_database_id) { 6 }
  let(:target_database_available_schemas) { ['schema_one', 'schema_two', 'schema_three'] }

  let(:source_dataset_1) { 101 }
  let(:source_dataset_2) { 102 }
  let(:source_dashboard_datasets) {[
    {id: source_dataset_1, datasource_name: "Dataset 1", schema: "schema1", database: {id: 9, name: "db_9", backend: "postgresql"}},
    {id: source_dataset_2, datasource_name: "Dataset 2", schema: "schema1", database: {id: 9, name: "db_9", backend: "postgresql"}}
  ]}

  let(:new_dashboard_id) { 2 }
  let(:new_dashboard) { double('new_dashboard', id: new_dashboard_id, url: "http://superset-host.com/superset/dashboard/#{new_dashboard_id}") }

  let(:new_dataset_1) { 201 }
  let(:new_dataset_2) { 202 }

  let(:new_chart_1) { 3001 }
  let(:new_chart_2) { 3002 }

  before do
    allow(subject).to receive(:superset_host).and_return('http://superset-host.com')
    allow(subject).to receive(:target_database_available_schemas).and_return(target_database_available_schemas)
    allow(subject).to receive(:new_dashboard).and_return(new_dashboard)
    allow(subject).to receive(:source_dashboard_datasets).and_return(source_dashboard_datasets)
  end

  describe '#perform' do
    context 'with valid params' do

      before do
        # duplicating the current datasets
        expect(Superset::Dataset::Duplicate).to receive(:new).with(source_dataset_id: source_dataset_1, new_dataset_name: "Dataset 1 schema_one DUPLICATION").and_return(double(perform: new_dataset_1))
        expect(Superset::Dataset::Duplicate).to receive(:new).with(source_dataset_id: source_dataset_2, new_dataset_name: "Dataset 2 schema_one DUPLICATION").and_return(double(perform: new_dataset_2))

        # updating the new datasets to point to the target schema and target database
        expect(Superset::Dataset::UpdateSchema).to receive(:new).with(source_dataset_id: new_dataset_1, target_database_id: target_database_id, target_schema: target_schema).and_return(double(response: true))
        expect(Superset::Dataset::UpdateSchema).to receive(:new).with(source_dataset_id: new_dataset_2, target_database_id: target_database_id, target_schema: target_schema).and_return(double(response: true))

        # getting the list of charts for the source dashboard
        allow(Superset::Dashboard::Charts::List).to receive(:new).with(new_dashboard_id).and_return(double(chart_ids: [new_chart_1, new_chart_2]))

        # getting the current dataset_id for the new charts .. still pointing to the old datasets
        expect(Superset::Chart::Get).to receive(:new).with(3001).and_return(double(datasource_id: source_dataset_1))
        expect(Superset::Chart::Get).to receive(:new).with(3002).and_return(double(datasource_id: source_dataset_2))

        # updating the new charts to point to the new datasets
        expect(Superset::Chart::UpdateDataset).to receive(:new).with(chart_id: new_chart_1, target_dataset_id: new_dataset_1).and_return(double(response: true))
        expect(Superset::Chart::UpdateDataset).to receive(:new).with(chart_id: new_chart_2, target_dataset_id: new_dataset_2).and_return(double(response: true))
      end

      specify do
        expect(subject.perform).to eq( { new_dashboard_id: 2, new_dashboard_url: "http://superset-host.com/superset/dashboard/2" })
      end
    end

    context 'with invalid params' do
      context 'source_dashboard_id is empty' do
        let(:source_dashboard_id) { nil }

        specify do
          expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "source_dashboard_id integer is required")
        end
      end

      context 'target_schema is empty' do
        let(:target_schema) { nil }

        specify do
          expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "target_schema string is required")
        end
      end

      context 'target_database_id is empty' do
        let(:target_database_id) { nil }

        specify do
          expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "target_database_id integer is required")
        end
      end

      context 'target_schema is invalid' do
        let(:target_schema) { 'schema_four' }

        specify do
          expect { subject.perform }.to raise_error(Superset::Request::ValidationError, "Schema schema_four does not exist in target database: 6")
        end
      end

      context 'source dashboard datasets use multiple schemas' do
        before do
          allow(subject).to receive(:source_dashboard_schemas).and_return(['schema_one', 'schema_five'])
        end

        specify do
          expect { subject.perform }.to raise_error(Superset::Request::ValidationError, "The source_dashboard_id #{source_dashboard_id} datasets are required to point to one schema only. Actual schema list is schema_one,schema_five")
        end
      end
    end
  end
end

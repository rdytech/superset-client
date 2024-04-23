require 'spec_helper'
require 'superset/services/duplicate_dashboard'

RSpec.describe Superset::Services::DuplicateDashboard do
  subject { described_class.new(
              source_dashboard_id: source_dashboard_id,
              target_schema:       target_schema,
              target_database_id:  target_database_id,
              allowed_domains:     allowed_domains,
              tags:                tags ) }

  let(:source_dashboard_id) { 1 }
  let(:source_dashboard) { double('source_dashboard', id: source_dashboard_id, url: "http://superset-host.com/superset/dashboard/#{source_dashboard_id}", json_metadata: json_metadata_initial_settings) }

  let(:target_schema) { 'schema_two' }
  let(:target_database_id) { 6 }
  let(:allowed_domains) { [] }
  let(:tags) { [] }
  let(:target_database_available_schemas) { ['schema_one', 'schema_two', 'schema_three'] }
  let(:source_dataset_1) { 101 }
  let(:source_dataset_2) { 102 }
  let(:source_dashboard_datasets) {[
    {id: source_dataset_1, datasource_name: "Dataset 1", schema: "schema_one", database: {id: 9, name: "db_9", backend: "postgresql"}, sql: 'SELECT * FROM table1'},
    {id: source_dataset_2, datasource_name: "Dataset 2", schema: "schema_one", database: {id: 9, name: "db_9", backend: "postgresql"}, sql: 'SELECT * FROM table1'}
  ]}
  let(:source_chart_1) { 1001 }
  let(:source_chart_2) { 1002 }

  let(:source_dashboard_filter_dataset_ids) { [source_dataset_1, source_dataset_2] }
  let(:source_dashboard_dataset_ids) {[source_dataset_1, source_dataset_2 ]}
  let(:dataset_duplication_tracker) { [{ source_dataset_id: 101, new_dataset_id: 201 }] }

  let(:new_dashboard_id) { 2 }
  let(:new_dashboard) do
    OpenStruct.new(
      id: new_dashboard_id,
      url: "http://superset-host.com/superset/dashboard/#{new_dashboard_id}",
      result: { 'json_metadata' => json_metadata_initial_settings.to_json },
      json_metadata: json_metadata_initial_settings )  # mock the new_dashboard_json_metadata method
  end
      # { double('new_dashboard', id: new_dashboard_id, url: "http://superset-host.com/superset/dashboard/#{new_dashboard_id}", json_metadata: json_metadata_initial_settings) }

  let(:new_dataset_1) { 201 }
  let(:new_dataset_2) { 202 }

  let(:new_chart_1) { 2001 }
  let(:new_chart_2) { 2002 }
  let(:existing_target_datasets_list) {[]}

  # initial json metadata settings will be copied to the new dashboard and requires updating
  let(:json_metadata_initial_settings) do 
    {
      "chart_configuration"=>
        { "#{source_chart_1}"=>{"id"=>source_chart_1, "crossFilters"=>{"scope"=>"global", "chartsInScope"=>[source_chart_2]}},
          "#{source_chart_2}"=>{"id"=>source_chart_2, "crossFilters"=>{"scope"=>"global", "chartsInScope"=>[source_chart_1]}}},
      "global_chart_configuration"=>{"scope"=>{"rootPath"=>["ROOT_ID"], "excluded"=>[]}, "chartsInScope"=>[source_chart_1, source_chart_2]},
      "native_filter_configuration"=>
        [
          {"id"=>"NATIVE_FILTER-k-UxewZyI",
            "name"=>"JobTitleLimit5",
            "targets"=>[{"datasetId"=>source_dataset_1, "column"=>{"name"=>"job_title"}}],
            "chartsInScope"=>[source_chart_1, source_chart_2]},
          {"id"=>"NATIVE_FILTER-eoi3FEQ1C",
            "name"=>"Count",
            "filterType"=>"filter_select",
            "targets"=>[{"datasetId"=>source_dataset_2, "column"=>{"name"=>"count"}}],
            "chartsInScope"=>[source_chart_1, source_chart_2]}
        ]
      }
  end

  # expected json metadata settings after the new dashboard is created and json is updated
  let(:json_metadata_updated_settings) do 
    {
      "chart_configuration"=>
        { "#{new_chart_1}"=>{"id"=>new_chart_1, "crossFilters"=>{"scope"=>"global", "chartsInScope"=>[new_chart_2]}},
          "#{new_chart_2}"=>{"id"=>new_chart_2, "crossFilters"=>{"scope"=>"global", "chartsInScope"=>[new_chart_1]}}},
      "global_chart_configuration"=>{"scope"=>{"rootPath"=>["ROOT_ID"], "excluded"=>[]}, "chartsInScope"=>[new_chart_1, new_chart_2]},
      "native_filter_configuration"=>
        [
          {"id"=>"NATIVE_FILTER-k-UxewZyI",
            "name"=>"JobTitleLimit5",
            "targets"=>[{"datasetId"=>new_dataset_1, "column"=>{"name"=>"job_title"}}],
            "chartsInScope"=>[new_chart_1, new_chart_2]},
          {"id"=>"NATIVE_FILTER-eoi3FEQ1C",
            "name"=>"Count",
            "filterType"=>"filter_select",
            "targets"=>[{"datasetId"=>new_dataset_2, "column"=>{"name"=>"count"}}],
            "chartsInScope"=>[new_chart_1, new_chart_2]}
        ]
      }
  end

  before do
    allow(subject).to receive(:superset_host).and_return('http://superset-host.com')
    allow(subject).to receive(:target_database_available_schemas).and_return(target_database_available_schemas)
    allow(subject).to receive(:source_dashboard).and_return(source_dashboard)
    allow(subject).to receive(:new_dashboard).and_return(new_dashboard)
    allow(subject).to receive(:source_dashboard_datasets).and_return(source_dashboard_datasets)
    allow(subject).to receive(:target_schema_matching_dataset_names).and_return(existing_target_datasets_list)
    allow(subject).to receive(:source_dashboard_filter_dataset_ids).and_return(source_dashboard_filter_dataset_ids)
    allow(subject).to receive(:source_dashboard_dataset_ids).and_return(source_dashboard_dataset_ids)
    allow(subject).to receive(:dataset_duplication_tracker).and_return(dataset_duplication_tracker)
  end

  describe '#perform' do
    context 'with valid params' do
      before do
        # duplicating the current datasets
        expect(Superset::Dataset::Duplicate).to receive(:new).with(source_dataset_id: source_dataset_1, new_dataset_name: "Dataset 1-schema_two").and_return(double(perform: new_dataset_1))
        expect(Superset::Dataset::Duplicate).to receive(:new).with(source_dataset_id: source_dataset_2, new_dataset_name: "Dataset 2-schema_two").and_return(double(perform: new_dataset_2))

        # updating the new datasets to point to the target schema and target database
        expect(Superset::Dataset::UpdateSchema).to receive(:new).with(source_dataset_id: new_dataset_1, target_database_id: target_database_id, target_schema: target_schema).and_return(double(perform: new_dataset_1))
        expect(Superset::Dataset::UpdateSchema).to receive(:new).with(source_dataset_id: new_dataset_2, target_database_id: target_database_id, target_schema: target_schema).and_return(double(perform: new_dataset_2))

        # getting the list of charts for the source dashboard
        allow(Superset::Dashboard::Charts::List).to receive(:new).with(source_dashboard_id).and_return(double(result: [{ 'slice_name' => "chart 1", "id" => source_chart_1}, { 'slice_name' => "chart 2", "id" => source_chart_2}])) # , chart_ids: [source_chart_1, source_chart_2]
        allow(Superset::Dashboard::Charts::List).to receive(:new).with(new_dashboard_id).and_return(double(result: [{ 'slice_name' => "chart 1", "id" => new_chart_1}, { 'slice_name' => "chart 2", "id" => new_chart_2}]))

        # getting the current dataset_id for the new charts .. still pointing to the old datasets
        expect(Superset::Chart::Get).to receive(:new).with(new_chart_1).and_return(double(datasource_id: source_dataset_1))
        expect(Superset::Chart::Get).to receive(:new).with(new_chart_2).and_return(double(datasource_id: source_dataset_2))

        # updating the new charts to point to the new datasets
        expect(Superset::Chart::UpdateDataset).to receive(:new).with(chart_id: new_chart_1, target_dataset_id: new_dataset_1, target_dashboard_id: new_dashboard_id).and_return(double(perform: true))
        expect(Superset::Chart::UpdateDataset).to receive(:new).with(chart_id: new_chart_2, target_dataset_id: new_dataset_2, target_dashboard_id: new_dashboard_id).and_return(double(perform: true))

        # update dashboard json metadata chart datasets
        expect(Superset::Dashboard::Put).to receive(:new).once.with(target_dashboard_id: new_dashboard_id, params: { 'json_metadata' => json_metadata_updated_settings.to_json }).and_return(double(perform: true))
      end

      context 'completes duplicate process' do
        context 'and returns the new dashboard details' do
          specify do
            expect(subject.perform).to eq( { new_dashboard_id: 2, new_dashboard_url: "http://superset-host.com/superset/dashboard/2" }) 
          end
        end

        context 'and updates the json_metadata as expected' do
          context 'with stardard json metadata ids' do
            specify do
              expect(subject.new_dashboard_json_metadata_configuration).to eq(json_metadata_initial_settings)
              subject.perform 
              expect(subject.new_dashboard_json_metadata_configuration).to eq(json_metadata_updated_settings)
            end
          end

          context 'with non stardard json metadata ids to confirm gsub' do
            let(:source_chart_1) { 11 }
            let(:source_chart_2) { 1111 }
            let(:json_metadata_initial_settings) do 
              {
                "chart_configuration"=>
                  { "#{source_chart_1}"=>{"id"=>source_chart_1, "crossFilters"=>{"scope"=>"global", "chartsInScope"=>[source_chart_2]}} ,
                    "#{source_chart_2}"=>{"id"=>source_chart_2, "crossFilters"=>{"scope"=>"global", "chartsInScope"=>[source_chart_1]}} } ,
                "global_chart_configuration"=>{"scope"=>{"rootPath"=>["ROOT_ID"], "excluded"=>[]}, "chartsInScope"=>[source_chart_1, source_chart_2]},
                "native_filter_configuration"=>[]
              }
            end

            let(:new_chart_1) { 222 }
            let(:new_chart_2) { 22222 }
            let!(:json_metadata_updated_settings) do 
              {
                "chart_configuration"=>
                  { "#{new_chart_1}"=>{"id"=>new_chart_1, "crossFilters"=>{"scope"=>"global", "chartsInScope"=>[new_chart_2]}} ,
                    "#{new_chart_2}"=>{"id"=>new_chart_2, "crossFilters"=>{"scope"=>"global", "chartsInScope"=>[new_chart_1]}} } ,
                "global_chart_configuration"=>{"scope"=>{"rootPath"=>["ROOT_ID"], "excluded"=>[]}, "chartsInScope"=>[new_chart_1, new_chart_2]},
                "native_filter_configuration"=>[]
              }
            end

            specify do
              expect(subject.new_dashboard_json_metadata_configuration).to eq(json_metadata_initial_settings)
              subject.perform 
              expect(subject.new_dashboard_json_metadata_configuration).to eq(json_metadata_updated_settings)
            end
          end
        end
        
      end

      context 'and embedded domains' do
        context 'are empty' do
          before do
            expect(Superset::Dashboard::Embedded::Put).to_not receive(:new)
          end

          specify { expect(subject.perform).to eq( { new_dashboard_id: 2, new_dashboard_url: "http://superset-host.com/superset/dashboard/2" }) }
        end

        context 'are not empty' do
          let(:allowed_domains) { ['domain1.com', 'domain2.com'] }

          before do
            expect(Superset::Dashboard::Embedded::Put).to receive(:new).with(dashboard_id: new_dashboard_id, allowed_domains: allowed_domains).and_return(double(result: { allowed_domains: allowed_domains }))
          end

          specify { expect(subject.perform).to eq( { new_dashboard_id: 2, new_dashboard_url: "http://superset-host.com/superset/dashboard/2" }) }
        end
      end

      context 'and tags' do
        context 'are empty' do
          specify { expect(subject.perform).to eq( { new_dashboard_id: 2, new_dashboard_url: "http://superset-host.com/superset/dashboard/2" }) }
        end

        context 'are not empty' do
          let!(:tags) {  ["embedded", "product:some-product-name", "client:#{target_schema}"] }

          before do
            expect(Superset::Tag::AddToObject).to receive(:new).with(object_type_id: ObjectType::DASHBOARD, object_id: new_dashboard_id, tags: tags).and_return(double(perform: true))
          end

          specify { expect(subject.perform).to eq( { new_dashboard_id: 2, new_dashboard_url: "http://superset-host.com/superset/dashboard/2" }) }
        end
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

      context 'filters set is outside source schema' do
        let(:target_schema) { 'schema_two' }
        let(:source_dashboard_filter_dataset_ids) { [101, 202] }

        specify do
          expect { subject.perform }.to raise_error(Superset::Request::ValidationError, "One or more source dashboard filters point to a different dataset than the dashboard charts. Identified Unpermittied Filter Dataset Ids are [202]")
        end
      end

      context 'source dashboard datasets use multiple schemas' do
        before do
          allow(subject).to receive(:source_dashboard_schemas).and_return(['schema_one', 'schema_five'])
        end

        specify do
          expect { subject.perform }.to raise_error(Superset::Request::ValidationError, "The source dashboard datasets are required to point to one schema only. Actual schema list is schema_one,schema_five")
        end
      end

      context 'target schema already has matching dataset names' do
        let(:existing_target_datasets_list) {[ 'Dataset 1 (COPY)', 'Dataset 2 (COPY)' ]}
        specify do
          expect { subject.perform }.to raise_error(Superset::Request::ValidationError, 
            "DATASET NAME CONFLICT: The Target Schema schema_two already has existing datasets named: Dataset 1 (COPY),Dataset 2 (COPY)")
        end
      end
    end
  end
end

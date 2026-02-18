require 'spec_helper'

RSpec.describe Superset::Dashboard::Datasets::List do
  subject { described_class.new(dashboard_id: dashboard_id, include_filter_datasets: include_filter_datasets, include_catalog_lookup: include_catalog_lookup) }
  let(:dashboard_id) { 1 }
  let(:include_filter_datasets) { false }
  let(:include_catalog_lookup) { false }
  let(:dashboard_datasets_result) do
    [
      {
        'id' => 101,
        'datasource_name' => 'Acme Forecasts',
        'database' => { 'id' => 1, 'name' => 'DB1', 'backend' => 'postgres' },
        'schema' => 'acme',
        'sql' => 'select * from acme.forecasts'
      }.with_indifferent_access,
      {
        'id' => 102,
        'datasource_name' => 'video_game_sales',
        'database' => { 'id' => 2, 'name' => 'examples', 'backend' => 'postgres' },
        'schema' => 'public',
        'sql' => 'select * from acme_new.forecasts'
      }.with_indifferent_access
    ]
  end

  before do
    allow(subject).to receive(:result).and_return(dashboard_datasets_result)
    allow(subject).to receive(:title).and_return('1: Test Dashboard')
  end

  describe '#databases' do
    it 'returns a list of databases' do
      expect(subject.databases).to eq([
        {'id' => 1, 'name' => 'DB1', 'backend' => 'postgres'}, 
        {'id' => 2, 'name' => 'examples', 'backend' => 'postgres'}])
    end
  end

  describe '#schemas' do
    context 'when the dashboard has datasets from multiple schemas' do
      it 'returns a list of schemas' do
        expect(subject.schemas).to eq(['acme', 'public'])
      end
    end

    context 'with a single schema' do
      before do
        allow(subject).to receive(:schemas).and_return(['acme'])
      end

      it 'returns a single schemas' do
        expect(subject.schemas).to eq(['acme'])
      end

      it 'does not raise a rollbar if there is 1 uniq schema' do
        expect(Rollbar).to_not receive(:error)
        subject.schemas
      end
    end
  end

  describe '#datasets_details' do
    it 'returns a list of datasets' do
      expect(subject.datasets_details).to eq([
        {"id"=>101, "datasource_name"=>"Acme Forecasts", "schema"=>"acme", "database"=>{"id"=>1, "name"=>"DB1", "backend"=>"postgres"}, "sql"=>"select * from acme.forecasts"},
        {"id"=>102, "datasource_name"=>"video_game_sales", "schema"=>"public", "database"=>{"id"=>2, "name"=>"examples", "backend"=>"postgres"}, "sql"=>"select * from acme_new.forecasts"}
      ])
    end

    context 'returns a list of datasets with catalogs when include_catalog_lookup is true' do
      let(:include_catalog_lookup) { true }

      it 'returns a list of datasets with catalogs' do
        allow(Superset::Dataset::Get).to receive(:new).with(101).and_return(double(result: { 'catalog' => 'acme_client_catalog' }))
        allow(Superset::Dataset::Get).to receive(:new).with(102).and_return(double(result: { 'catalog' => 'examples_client_catalog' }))

        expect(subject.datasets_details).to eq([
          {"id"=>101, "datasource_name"=>"Acme Forecasts", "schema"=>"acme", "database"=>{"id"=>1, "name"=>"DB1", "backend"=>"postgres"}, "sql"=>"select * from acme.forecasts", "catalog"=>"acme_client_catalog"}, 
          {"id"=>102, "datasource_name"=>"video_game_sales", "schema"=>"public", "database"=>{"id"=>2, "name"=>"examples", "backend"=>"postgres"}, "sql"=>"select * from acme_new.forecasts", "catalog"=>"examples_client_catalog"},
        ])
      end
    end

    context 'returns both chart and filter datasets when include_filter_datasets is true' do
      before do
        allow(subject).to receive(:filter_dataset_ids).and_return([103,104])
        allow(subject).to receive(:retrieve_filter_datasets).with([103,104]).and_return(filter_dataset_json)
      end
      let(:include_filter_datasets) { true }
      let(:filter_dataset_json) {
      [
        {
          "id"=>103,
          "datasource_name"=>"Filter 1",
          "schema"=>"acme",
          "database"=>{
            "id"=>1,
            "name"=>"DB1",
            "backend"=>"postgres"
          },
          "sql"=>"select * from acme.forecasts"
        },
        {
          "id"=>104,
          "datasource_name"=>"Filter 2",
          "schema"=>"public",
          "database"=>{
            "id"=>2,
            "name"=>"examples",
            "backend"=>"postgres"
          },
          "sql"=>"select * from acme_new.forecasts"
        }
      ]
      }
      specify do
        expect(subject.datasets_details).to eq([
          {"id"=>101, "datasource_name"=>"Acme Forecasts", "schema"=>"acme", "database"=>{"id"=>1, "name"=>"DB1", "backend"=>"postgres"}, "sql"=>"select * from acme.forecasts"},
          {"id"=>102, "datasource_name"=>"video_game_sales", "schema"=>"public", "database"=>{"id"=>2, "name"=>"examples", "backend"=>"postgres"}, "sql"=>"select * from acme_new.forecasts"}
        ] + filter_dataset_json)
      end
    end
  end

  describe '#table' do
    before do
      allow(subject).to receive(:datasets_details).and_return(([
        {"id"=>101, "datasource_name"=>"Acme Forecasts", "schema"=>"acme", "database"=>{"id"=>1, "name"=>"DB1", "backend"=>"postgres"}, "sql"=>"select * from acme.forecasts"},
        {"id"=>102, "datasource_name"=>"video_game_sales", "schema"=>"public", "database"=>{"id"=>2, "name"=>"examples", "backend"=>"postgres"}, "sql"=>"select * from acme_new.forecasts"}
      ]+ filter_dataset_json).map(&:with_indifferent_access))
    end
    let(:filter_dataset_json) { [] }
    it 'prints a table with the dashboard title and charts' do
      expect(subject.table.to_s).to eq(
        "+---------------------------------------------------------------------------------------------+\n" \
        "|                                      1: Test Dashboard                                      |\n" \
        "+-----+------------------+----------+---------------+------------------+--------+-------------+\n" \
        "| Id  | Datasource name  | Database | Database name | Database backend | Schema | Filter only |\n" \
        "+-----+------------------+----------+---------------+------------------+--------+-------------+\n" \
        "| 101 | Acme Forecasts   | 1        | DB1           | postgres         | acme   |             |\n" \
        "| 102 | video_game_sales | 2        | examples      | postgres         | public |             |\n" \
        "+-----+------------------+----------+---------------+------------------+--------+-------------+"
      )
    end

    context 'prints a table with the dashboard title with chart and filter datasets' do
      let(:include_filter_datasets) { true }
      let(:filter_dataset_json) {
      [
        {
          "id"=>103,
          "datasource_name"=>"Filter 1",
          "schema"=>"acme",
          "database"=>{
            "id"=>1,
            "name"=>"DB1",
            "backend"=>"postgres"
          },
          "sql"=>"select * from acme.forecasts",
          "filter_only" => true
        },
        {
          "id"=>104,
          "datasource_name"=>"Filter 2",
          "schema"=>"public",
          "database"=>{
            "id"=>2,
            "name"=>"examples",
            "backend"=>"postgres"
          },
          "sql"=>"select * from acme_new.forecasts",
          "filter_only" => true
        }
      ]
      }
      specify do
        expect(subject.table.to_s).to eq(
          "+---------------------------------------------------------------------------------------------+\n" \
          "|                                      1: Test Dashboard                                      |\n" \
          "+-----+------------------+----------+---------------+------------------+--------+-------------+\n" \
          "| Id  | Datasource name  | Database | Database name | Database backend | Schema | Filter only |\n" \
          "+-----+------------------+----------+---------------+------------------+--------+-------------+\n" \
          "| 101 | Acme Forecasts   | 1        | DB1           | postgres         | acme   |             |\n" \
          "| 102 | video_game_sales | 2        | examples      | postgres         | public |             |\n" \
          "| 103 | Filter 1         | 1        | DB1           | postgres         | acme   | true        |\n" \
          "| 104 | Filter 2         | 2        | examples      | postgres         | public | true        |\n" \
          "+-----+------------------+----------+---------------+------------------+--------+-------------+"
        )
      end
    end
  end
end

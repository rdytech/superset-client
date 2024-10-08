require 'spec_helper'

RSpec.describe Superset::Dataset::UpdateSchema do
  subject { described_class.new(
              source_dataset_id:  source_dataset_id, 
              target_database_id: target_database_id, 
              target_schema:      target_schema,
              remove_copy_suffix: remove_copy_suffix) }

  let(:source_dataset_id) { 226 }
  let(:source_schema) { 'schema_one' }
  let(:target_database_id) { 6 }
  let(:target_schema) { 'schema_three' }
  let(:remove_copy_suffix) { false }

  let(:source_dataset) do
    {
      "id"=>source_dataset_id,
      "result"=>
        {"always_filter_main_dttm"=>false,
        "cache_timeout"=>nil,
        "columns"=>
          [{"advanced_data_type"=>nil,
            "column_name"=>"service",
            "description"=>nil,
            "expression"=>nil,
            "extra"=>"{}",
            "filterable"=>true,
            "groupby"=>true,
            "id"=>5513,
            "is_active"=>true,
            "is_dttm"=>false,
            "python_date_format"=>nil,
            "type"=>"STRING",
            "uuid"=>"577d6...2aee",
            "verbose_name"=>nil},
          {"advanced_data_type"=>nil,
            "column_name"=>"count",
            "description"=>nil,
            "expression"=>nil,
            "extra"=>"{}",
            "filterable"=>true,
            "groupby"=>true,
            "id"=>5512,
            "is_active"=>true,
            "is_dttm"=>false,
            "python_date_format"=>nil,
            "type"=>"LONGINTEGER",
            "uuid"=>"56e3f....2580",
            "verbose_name"=>nil}],
        "default_endpoint"=>nil,
        "description"=>nil,
        "extra"=>nil,
        "fetch_values_predicate"=>nil,
        "filter_select_enabled"=>true,
        "is_managed_externally"=>false,
        "is_sqllab_view"=>false,
        "main_dttm_col"=>nil,
        "metrics"=>[{"currency"=>nil, "d3format"=>nil, "description"=>nil, "expression"=>"COUNT(*)", "extra"=>"{\"warning_markdown\":\"\"}", "id"=>236, "metric_name"=>"count", "metric_type"=>"count", "verbose_name"=>"COUNT(*)", "warning_text"=>nil}],
        "normalize_columns"=>false,
        "offset"=>0,
        "owners"=>[],
        "schema"=>source_schema,
        "sql"=>"select count(*),\nservice\n\nfrom blahblah \ngroup by service",
        "table_name"=>"JR SP Service Counts (COPY)",
        "template_params"=>nil
      }
    }.with_indifferent_access
  end

  let(:response) { { "result" => { "schema"=>"schema_three" } } }
  let(:target_database_available_schemas) { ['schema_one', 'schema_two', 'schema_three'] }

  before do
    allow(subject).to receive(:response).and_return(response)
    allow(subject).to receive(:source_dataset).and_return(source_dataset['result'])
    allow(subject).to receive(:target_database_available_schemas).and_return(target_database_available_schemas)
  end

  describe '#perform' do
    context 'with valid params' do
      specify do
        expect(subject.perform).to eq "Successfully updated dataset schema to schema_three on Database: 6"
      end
    end

    context 'with invalid params' do
      context 'source_dataset_id is empty' do
        let(:source_dataset_id) { nil }
        
        specify do
          expect { subject.perform }.to raise_error(RuntimeError, "Error: source_dataset_id integer is required")
        end
      end

      context 'target_database_id is empty' do
        let(:target_database_id) { nil }
        
        specify do
          expect { subject.perform }.to raise_error(RuntimeError, "Error: target_database_id integer is required")
        end
      end
 
      context 'target_schema is empty' do
        let(:target_schema) { nil }

        specify do
          expect { subject.perform }.to raise_error(RuntimeError, "Error: target_schema string is required")
        end
      end

      context 'target_schema is invalid' do
        let(:target_schema) { 'schema_four' }

        specify do
          expect { subject.perform }.to raise_error(RuntimeError, "Error: Schema schema_four does not exist in database: 6")
        end
      end

      context 'source dataset schema is not configured' do
        let(:source_schema) { '' }

        specify do
          expect { subject.perform }.to raise_error(RuntimeError, "Error: schema must be set on the source dataset")
        end
      end

    end
  end

  describe '#params_updated' do
    context 'with remove_copy_suffix true' do
      specify 'set the new target schema and target database correctly' do
        expect(subject.params_updated['schema']).to eq(target_schema)
        expect(subject.params_updated['database_id']).to eq(target_database_id)
        expect(subject.params_updated['table_name']).to eq('JR SP Service Counts (COPY)') # unchanged if remove_copy_suffix is false
      end
    end

    context 'with remove_copy_suffix true' do
      let(:remove_copy_suffix) { true }

      specify do
        expect(subject.params_updated['table_name']).to eq('JR SP Service Counts') # removed (COPY) suffix
      end
    end
  end
end

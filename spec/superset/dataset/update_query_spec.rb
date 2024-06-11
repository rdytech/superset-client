require 'spec_helper'

RSpec.describe Superset::Dataset::UpdateQuery do
  subject { described_class.new(
              dataset_id: dataset_id,
              new_query:  new_query) }

  let(:dataset_id) { 226 }
  let(:new_query) { 'select blah from some_table' }

  let(:response) { { "id"=>dataset_id , "result" => { "sql" => new_query } } }

  before do
    allow(subject).to receive(:response).and_return(response)
    allow(subject).to receive(:source_dataset).and_return( { schema: 'client2', sql: 'select fu from dif_table' }.with_indifferent_access)
  end

  describe '#perform' do
    context 'with valid params' do
      specify do
        expect(subject.perform).to eq response
      end
    end

    context 'with invalid params' do
      context 'dataset_id is empty' do
        let(:dataset_id) { nil }

        specify do
          expect { subject.perform }.to raise_error(RuntimeError, "Error: dataset_id integer is required")
        end
      end

      context 'new_query is empty' do
        let(:new_query) { nil }

        specify do
          expect { subject.perform }.to raise_error(RuntimeError, "Error: new_query string is required")
        end
      end

      context 'new_query hard codes schema name' do
        let(:new_query) { 'select fu from client2.dif_table' }

        specify do
          expect { subject.perform }.to raise_error(RuntimeError, 
            "Error: >>WARNING<< The Dataset ID 226 SQL query is hard coded with the schema value and can not be duplicated cleanly. " \
            "Remove all direct embedded schema calls from the Dataset SQL query before continuing.")
        end
      end
    end
  end
end

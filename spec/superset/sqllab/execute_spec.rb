require 'spec_helper'

RSpec.describe Superset::Sqllab::Execute do
  subject { described_class.new(
              database_id: database_id, 
              query: query) }
  
  let(:database_id) { 1 }
  let(:query) { 'select id, category, country from sales order by id asc limit 2' }
  let(:response) {
    { 
      "query_id"=>1111,
      "status"=>"success",
      "data"=> 
      [
        {"id"=>1, "category"=>"A", "country"=>"Australia"},
        {"id"=>2, "category"=>"B", "country"=>"New Zealand"}
      ]
    }
  }

  before do
    allow(subject).to receive(:response).and_return(response)
  end

  describe 'perform' do
    context 'with valid params' do
      it 'returns the new dashboard object' do
        expect(subject.perform).to eq(response["data"])
      end
    end

    context 'with invalid params' do
      context 'when database_id is not an integer' do
        let(:database_id) { 'q' }
        
        it 'raises an error' do
          expect { subject.perform }.to raise_error(Superset::Sqllab::Execute::InvalidParameterError, 
                                                    "database_id integer is required")
        end
      end

      context 'when database_id is not present' do
        let(:database_id) { nil }
        
        it 'raises an error' do
          expect { subject.perform }.to raise_error(Superset::Sqllab::Execute::InvalidParameterError, 
                                                    "database_id integer is required")
        end
      end

      context 'when query is not a string' do
        let(:query) { 1 }
        
        it 'raises an error' do
          expect { subject.perform }.to raise_error(Superset::Sqllab::Execute::InvalidParameterError, 
                                                    "query string is required")
        end
      end

      context 'when query is not present' do
        let(:query) { nil }
        
        it 'raises an error' do
          expect { subject.perform }.to raise_error(Superset::Sqllab::Execute::InvalidParameterError, 
                                                    "query string is required")
        end
      end

    end
  end
end

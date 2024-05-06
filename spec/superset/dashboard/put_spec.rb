require 'spec_helper'

RSpec.describe Superset::Dashboard::Put do
  subject { described_class.new(target_dashboard_id: dashboard_id, params: params) }
  let(:dashboard_id) { 1 }
  let(:params) {{
    "json_metadata" => { 
      "key1" => "value1", 
      "positions" => { "key2" => "value2" }
    }.to_json 
  }}
  let(:response) { { "result" => { "id" => 2, "last_modified_time" => 1708484547.0 } } }

  before do
    allow(subject).to receive(:response).and_return(response)
  end

  describe 'perform' do
    context 'with valid params' do
      it 'returns response' do
        expect(subject.perform).to eq(response)
      end
    end

    context 'with invalid params' do
      context 'when source_dashboard_id is not an integer' do
        let(:dashboard_id) { 'q' }
        
        it 'raises an error' do
          expect { subject.perform }.to raise_error("Error: target_dashboard_id integer is required")
        end
      end

      context 'when source_dashboard_id is not present' do
        let(:dashboard_id) { nil }
        
        it 'raises an error' do
          expect { subject.perform }.to raise_error("Error: target_dashboard_id integer is required")
        end
      end

      context 'when params is not a hash' do
        let(:params) { 'q' }
        
        it 'raises an error' do
          expect { subject.perform }.to raise_error("Error: params hash is required")
        end
      end

      context 'when params is nil' do
        let(:params) { nil }
        
        it 'raises an error' do
          expect { subject.perform }.to raise_error("Error: params hash is required")
        end
      end
    end
  end
end

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

  let(:new_dashboard_id) { 2 }
  let(:new_dashboard_instance) { instance_double("Superset::Dashboard::Get") }

  before do
    allow(subject).to receive(:response).and_return( { "result" => 
      {"id"=>new_dashboard_id, "last_modified_time"=>1708484547.0} }
    )
  end

  describe 'perform' do
    context 'with valid params' do
      before do
        allow(Superset::Dashboard::Get).to receive(:new).with(new_dashboard_id).and_return(new_dashboard_instance)
        allow(new_dashboard_instance).to receive(:perform).and_return(new_dashboard_instance)
      end

      it 'returns the new dashboard object' do
        expect(subject.perform).to be new_dashboard_instance
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

require 'spec_helper'

RSpec.describe Superset::Dashboard::Copy do
  subject { described_class.new(source_dashboard_id: dashboard_id, duplicate_slices: dup_slices) }
  let(:dashboard_id) { 1 }
  let(:dup_slices) { true }

  let(:source_dashboard) do
    OpenStruct.new(
      title: 'My Dashboard',
      json_metadata: { "key1" => "value1" },
      positions: { "key2" => "value2" }
    )
  end

  before do
    allow(subject).to receive(:source_dashboard).and_return(source_dashboard)
    allow(subject).to receive(:response).and_return( { "result" => 
      {"id"=>2, "last_modified_time"=>1708484547.0} }
    )
  end

  describe 'perform' do
    context 'with valid params' do
      it 'returns the new dashboard id' do
        expect(subject.perform).to be_an_instance_of(described_class)
      end
    end

    context 'with invalid params' do
      context 'when source_dashboard_id is not an integer' do
        let(:dashboard_id) { 'q' }
        
        it 'raises an error' do
          expect { subject.perform }.to raise_error("Error: source_dashboard_id integer is required")
        end
      end

      context 'when source_dashboard_id is not present' do
        let(:dashboard_id) { nil }
        
        it 'raises an error' do
          expect { subject.perform }.to raise_error("Error: source_dashboard_id integer is required")
        end
      end

      context 'when source_dashboard_id duplicate_slices not a boolean' do
        let(:dup_slices) { 'q' }
        
        it 'raises an error' do
          expect { subject.perform }.to raise_error("Error: duplicate_slices must be a boolean")
        end
      end
    end
  end

  describe '#params' do
    it 'returns the correct params' do
      expect(subject.params).to eq({
        "css" => "{}",
        "dashboard_title" => "My Dashboard (COPY)",
        "duplicate_slices" => true,
        "json_metadata" => { "key1" => "value1", 
                              "positions" => { "key2" => "value2" } }.to_json
      })
    end
  end
end

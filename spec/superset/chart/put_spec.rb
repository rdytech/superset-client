require 'spec_helper'

RSpec.describe Superset::Chart::Put do
  subject { described_class.new(
              chart_id:  chart_id,
              params: params) }

  let(:chart_id) { 226 }
  let(:params) { { owners: [ 1, 2, 3 ] } }
  let(:response) do
    {
      id: chart_id, 
      result: { owners: [1, 2, 3] }
    }
  end

  before do
    allow(subject).to receive(:response).and_return(response)
  end

  describe '#perform' do
    context 'with valid params' do
      specify do
        expect(subject.perform).to eq response
      end
    end

    context 'with invalid params' do
      context 'chart_id is empty' do
        let(:chart_id) { nil }
        
        specify do
          expect { subject.perform }.to raise_error(RuntimeError, "Error: chart_id integer is required")
        end
      end

      context 'params is empty' do
        let(:params) { nil }
        
        specify do
          expect { subject.perform }.to raise_error(RuntimeError, "Error: params hash is required")
        end
      end 
    end
  end
end

require 'spec_helper'
require 'superset/chart/create'

RSpec.describe Superset::Chart::Create do
  subject { described_class.new(params: params ) }
  let(:params) { { title: 'a chart' } }
  let(:new_chart_id) { 101 }

  let(:response) do
    { 'id' => new_chart_id }
  end

  before do
    allow_any_instance_of(described_class).to receive(:response).and_return(response)
    allow(ENV).to receive(:[]).with(any_args) { ''}
  end

  describe '#perform' do
    it 'returns id of the new chart' do
      expect(subject.perform).to eq(new_chart_id)
    end

    context 'raises an error if params are not provided' do
      let(:params) { nil }

      specify do
        expect { subject.perform }.to raise_error("Error: params hash is required")
      end
    end
  end
end

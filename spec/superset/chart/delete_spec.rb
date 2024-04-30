require 'spec_helper'

RSpec.describe Superset::Chart::Delete do
  subject { described_class.new(chart_id: chart_id) }
  let(:chart_id) { 1 }
  let(:response) { nil }

  before do
    allow(subject).to receive(:response).and_return(response)
  end

  describe '.perform' do
    context 'when chart_id is not present' do
      let(:chart_id) { nil }

      it 'raises an error' do
        expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "chart_id integer is required")
      end
    end

    context 'when chart_id is not an integer' do
      let(:chart_id) { 'string' }

      it 'raises an error' do
        expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "chart_id integer is required")
      end
    end

    context 'when chart_id is an integer' do
      let(:response) { 'response' }

      it 'deletes the chart' do
        expect(subject).to receive(:response)
        subject.perform
      end
    end
  end
end

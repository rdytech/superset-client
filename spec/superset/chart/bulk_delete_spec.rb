require 'spec_helper'

RSpec.describe Superset::Chart::BulkDelete do
  subject { described_class.new(chart_ids: chart_ids) }
  let(:chart_ids) { nil }
  let(:response) { "some response" }

  before do
    allow(subject).to receive(:response).and_return(response)
  end

  describe '.perform' do
    context 'when chart_ids is not present' do
      it 'raises an error' do
        expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "chart_ids array of integers expected")
      end
    end

    context 'when chart_ids contains non integer values' do
      let(:chart_ids) { [1, 'string'] }

      it 'raises an error' do
        expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "chart_ids array must contain Integer only values")
      end
    end

    context 'when chart_ids is an integer' do
      let(:chart_ids) { [1, 2] }

      it 'deletes the charts' do
        expect(subject).to receive(:response)
        subject.perform
      end
    end
  end
end

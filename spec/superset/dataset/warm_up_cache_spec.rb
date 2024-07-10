require 'spec_helper'

RSpec.describe Superset::Dataset::WarmUpCache do
  subject { described_class.new(dashboard_id: dashboard_id) }
  let(:dashboard_id) { 1 }
  let(:response) { nil }

  before do
    allow(subject).to receive(:response).and_return(response)
  end

  describe '.perform' do
    context 'when dashboard_id is not present' do
      let(:dashboard_id) { nil }

      it 'raises an error' do
        expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "dashboard_id must be present and must be an integer")
      end
    end

    context 'when dashboard_id is not an integer' do
      let(:dashboard_id) { 'string' }

      it 'raises an error' do
        expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "dashboard_id must be present and must be an integer")
      end
    end

    context 'when dashboard_id is an integer' do
      let(:response) { 'Dashboard warmed up' }

      it 'warms up the dataset' do
        expect(subject.perform).to eq response
      end
    end
  end
end

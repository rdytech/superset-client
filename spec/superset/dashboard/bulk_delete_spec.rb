require 'spec_helper'

RSpec.describe Superset::Dashboard::BulkDelete do
  subject { described_class.new(dashboard_ids: dashboard_ids) }
  let(:dashboard_ids) { nil }
  let(:response) { "some response" }

  before do
    allow(subject).to receive(:response).and_return(response)
  end

  describe '.perform' do
    context 'when dashboard_ids is not present' do
      it 'raises an error' do
        expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "dashboard_ids array of integers expected")
      end
    end

    context 'when dashboard_ids contains non integer values' do
      let(:dashboard_ids) { [1, 'string'] }

      it 'raises an error' do
        expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "dashboard_ids array must contain Integer only values")
      end
    end

    context 'when dashboard_ids is an integer' do
      let(:dashboard_ids) { [1, 2] }

      it 'deletes the dashboards' do
        expect(subject).to receive(:response)
        subject.perform
      end
    end
  end
end

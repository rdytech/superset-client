require 'spec_helper'

RSpec.describe Superset::Dataset::BulkDelete do
  subject { described_class.new(dataset_ids: dataset_ids) }
  let(:dataset_ids) { nil }
  let(:response) { "some response" }

  before do
    allow(subject).to receive(:response).and_return(response)
  end

  describe '.perform' do
    context 'when dataset_ids is not present' do
      it 'raises an error' do
        expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "dataset_ids array of integers expected")
      end
    end

    context 'when dataset_ids contains non integer values' do
      let(:dataset_ids) { [1, 'string'] }

      it 'raises an error' do
        expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "dataset_ids array must contin Integer only values")
      end
    end

    context 'when dataset_ids is an integer' do
      let(:dataset_ids) { [1, 2] }

      it 'deletes the datasets' do
        expect(subject).to receive(:response)
        subject.perform
      end
    end
  end
end

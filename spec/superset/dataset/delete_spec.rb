require 'spec_helper'

RSpec.describe Superset::Dataset::Delete do
  subject { described_class.new(dataset_id: dataset_id) }
  let(:dataset_id) { 1 }
  let(:response) { nil }

  before do
    allow(subject).to receive(:response).and_return(response)
  end

  describe '.perform' do
    context 'when dataset_id is not present' do
      let(:dataset_id) { nil }

      it 'raises an error' do
        expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "dataset_id integer is required")
      end
    end

    context 'when dataset_id is not an integer' do
      let(:dataset_id) { 'string' }

      it 'raises an error' do
        expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "dataset_id integer is required")
      end
    end

    context 'when dataset_id is an integer' do
      let(:response) { 'response' }

      it 'deletes the dataset' do
        expect(subject).to receive(:response)
        subject.perform
      end
    end
  end
end

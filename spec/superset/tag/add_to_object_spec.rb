require 'spec_helper'

RSpec.describe Superset::Tag::AddToObject do
  subject { described_class.new(object_type_id: object_type_id, object_id: object_id, tags: tags) }
  let(:dashboard_id) { 1 }
  let(:response) { {} }   # not a very helpful response from the api on this endpoint
  

  describe 'perform' do
    context 'with valid params' do
      let(:object_type_id) { 1 }
      let(:object_id) { 1 }
      let(:tags) { ['tag1', 'tag2'] }

      before do
        allow(subject).to receive(:response).and_return(response)
      end

      it 'returns the response' do
        expect(subject.perform).to eq response
      end
    end

    context 'with invalid params' do
      context 'when object_type_id is not an integer' do
        let(:object_type_id) { 'q' }
        let(:object_id) { 1 }
        let(:tags) { ['tag1', 'tag2'] }

        it 'raises an error' do
          expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "object_type_id integer is required")
        end
      end

      context 'when object_type_id is not a known value' do
        let(:object_type_id) { 5 }
        let(:object_id) { 1 }
        let(:tags) { ['tag1', 'tag2'] }

        it 'raises an error' do
          expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "object_type_id is not a known value")
        end
      end

      context 'when object_type_id is not present' do
        let(:object_type_id) { nil }
        let(:object_id) { 1 }
        let(:tags) { ['tag1', 'tag2'] }

        it 'raises an error' do
          expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "object_type_id integer is required")
        end
      end

      context 'when object_id is not an integer' do
        let(:object_type_id) { 1 }
        let(:object_id) { 'q' }
        let(:tags) { ['tag1', 'tag2'] }

        it 'raises an error' do
          expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "object_id integer is required")
        end
      end

      context 'when object_id is not present' do
        let(:object_type_id) { 1 }
        let(:object_id) { nil }
        let(:tags) { ['tag1', 'tag2'] }

        it 'raises an error' do
          expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "object_id integer is required")
        end
      end

      context 'when tags is not an array' do
        let(:object_type_id) { 1 }
        let(:object_id) { 1 }
        let(:tags) { 'q' }

        it 'raises an error' do
          expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "tags array is required")
        end
      end

      context 'when tags array contains non-string values' do
        let(:object_type_id) { 1 }
        let(:object_id) { 1 }
        let(:tags) { [1, 2] }

        it 'raises an error' do
          expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "tags array must contain string only values")
        end
      end
    end
  end
end

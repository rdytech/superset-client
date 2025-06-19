require 'spec_helper'

RSpec.describe Superset::Tag::DeleteFromObject do
  subject { described_class.new(object_type_id: object_type_id, object_id: object_id, tag: tag) }
  let(:dashboard_id) { 1 }
  let(:response) { { "message"=>"OK" } }
  

  describe 'perform' do
    context 'with valid params' do
      let(:object_type_id) { 1 }
      let(:object_id) { 1 }
      let(:tag) { 'tag1' }

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
        let(:tag) { ['tag1', 'tag2'] }

        it 'raises an error' do
          expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "object_type_id integer is required")
        end
      end

      context 'when object_type_id is not a known value' do
        let(:object_type_id) { 5 }
        let(:object_id) { 1 }
        let(:tag) { ['tag1', 'tag2'] }

        it 'raises an error' do
          expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "object_type_id is not a known value")
        end
      end

      context 'when object_type_id is not present' do
        let(:object_type_id) { nil }
        let(:object_id) { 1 }
        let(:tag) { ['tag1', 'tag2'] }

        it 'raises an error' do
          expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "object_type_id integer is required")
        end
      end

      context 'when object_id is not an integer' do
        let(:object_type_id) { 1 }
        let(:object_id) { 'q' }
        let(:tag) { ['tag1', 'tag2'] }

        it 'raises an error' do
          expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "object_id integer is required")
        end
      end

      context 'when object_id is not present' do
        let(:object_type_id) { 1 }
        let(:object_id) { nil }
        let(:tag) { ['tag1', 'tag2'] }

        it 'raises an error' do
          expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "object_id integer is required")
        end
      end

      context 'when tag is not an string' do
        let(:object_type_id) { 1 }
        let(:object_id) { 1 }
        let(:tag) { 101 }

        it 'raises an error' do
          expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "tag string is required")
        end
      end

      context 'when tags array contains non-string values' do
        let(:object_type_id) { 1 }
        let(:object_id) { 1 }
        let(:tag) { nil }

        it 'raises an error' do
          expect { subject.perform }.to raise_error(Superset::Request::InvalidParameterError, "tag string is required")
        end
      end
    end
  end
end

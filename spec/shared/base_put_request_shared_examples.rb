require 'spec_helper'

RSpec.shared_examples :base_put_request_shared_examples do
  describe "#perform" do
    subject { described_class.new(
                object_id: object_id,
                params: params) }

    let(:object_id) { 226 }
    let(:params) { { owners: [ 1, 2, 3 ] } }
    let(:response) do
      {
        id: object_id, 
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
        context 'object_id is empty' do
          let(:object_id) { nil }
          
          specify do
            expect { subject.perform }.to raise_error(RuntimeError, "Error: object_id integer is required")
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
end

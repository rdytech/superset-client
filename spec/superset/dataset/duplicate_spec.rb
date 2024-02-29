require 'spec_helper'

RSpec.describe Superset::Dataset::Duplicate do
  subject { described_class.new(source_dataset_id: source_dataset_id, new_dataset_name: new_dataset_name) }
  let(:source_dataset_id) { 226 }
  let(:new_dataset_name) { 'birth_names (copy)' }
  let(:response) do
    {
      "id"=>232, 
      "result"=>{
        "base_model_id"=>source_dataset_id, 
        "table_name"=>"birth_names (copy)"}}
  end

  before do
    allow(subject).to receive(:response).and_return(response)
    allow(subject).to receive(:new_dataset_name_already_in_use?).and_return(false)
  end

  describe '#perform' do
    context 'with valid params' do
      specify do
        expect(subject.perform).to eq 232
      end
    end

    context 'with invalid params' do
      context 'source_dataset_id is empty' do
        let(:source_dataset_id) { nil }
        
        specify do
          expect { subject.perform }.to raise_error
        end
      end

      context 'new_dataset_name is empty' do
        let(:new_dataset_name) { nil }
        
        specify do
          expect { subject.perform }.to raise_error
        end
      end
 
      context 'source_dataset_id is empty' do
        let(:source_dataset_id) { nil }

        specify do
          expect { subject.perform }.to raise_error
        end
      end
    end
  end

  describe '#params' do
    specify do
      expect(subject.params).to eq({"base_model_id"=>source_dataset_id, "table_name"=>"birth_names (copy)"})
    end
  end
end

require 'spec_helper'

RSpec.describe Superset::Security::Role::Get do
  subject { described_class.new(role_id) }
  let(:role_id) { 99 }
  let(:response) do
    {
      "description_columns"=>{},
      "id"=>9,
      "label_columns"=>{"id"=>"Id", "name"=>"Name"},
      "result"=>{"id"=>9, "name"=>"Schema Access to ACME"},
      "show_columns"=>["id", "name"],
      "show_title"=>"Show Role"
    }.with_indifferent_access
  end

  before do
    allow(subject).to receive(:response).and_return(response)
  end

  describe '#result' do
    it 'returns the response result' do
      expect(subject.result).to eq( [ { "id"=>9, "name"=>"Schema Access to ACME" } ] )
    end
  end

  describe '#id_and_name' do
    specify do
      expect(subject.id_and_name).to eq("9: Schema Access to ACME")
    end
  end
end

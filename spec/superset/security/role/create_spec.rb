require 'spec_helper'

RSpec.describe Superset::Security::Role::Create do
  subject { described_class.new(name: role) }
  let(:role) { 'some-role-name' }
  let(:response) do
    {
      "id"=>19,
      "result"=>
        { "name"=>"test" }
    }
  end


  describe '#result' do
    before { allow(subject).to receive(:response).and_return(response) }

    specify 'returns the name of the new role' do
      expect(subject.result).to eq(response['result'])
    end
  end

  describe '#response' do
    let(:role) { '' }

    specify 'with an empty role name raises an error' do
      expect { subject.result }.to raise_error(Superset::Request::InvalidParameterError)
    end
  end
end

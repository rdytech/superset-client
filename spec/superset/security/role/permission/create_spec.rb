require 'spec_helper'

RSpec.describe Superset::Security::Role::Permission::Create do
  subject { described_class.new(role_id: role_id, permission_view_menu_ids: permission_view_menu_ids) }
  let(:role_id) { 101 }
  let(:permission_view_menu_ids) { 2002 }
  let(:response) { { "result"=>{"permission_view_menu_ids"=>[454]} } }

  describe '#result' do
    before { allow(subject).to receive(:response).and_return(response) }

    specify 'returns the permission_view_menu_ids' do
      expect(subject.result).to eq(response['result'])
    end
  end

  describe '#response' do
    let(:role_id) { '' }

    specify 'with an empty role id raises an error' do
      expect { subject.result }.to raise_error(Superset::Request::InvalidParameterError)
    end
  end

  describe '#response' do
    let(:permission_view_menu_ids) { [] }

    specify 'with an empty permission_view_menu_ids raises an error' do
      expect { subject.result }.to raise_error(Superset::Request::InvalidParameterError)
    end
  end
end

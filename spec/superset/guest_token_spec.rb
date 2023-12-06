require 'spec_helper'

RSpec.describe Superset::GuestToken do
  subject { described_class.new(embedded_dashboard_id: ss_dashboard_id) }
  let(:ss_dashboard_id) { '101' }
  let(:credentials) { { username: 'test', password: 'test' } }

  before do
    allow(subject).to receive(:response_body).and_return({ "token"=> "some-token"})
    allow(subject).to receive(:credentials).and_return(credentials)
  end

  describe '#guest_token' do
    it 'returns the guest token from the response' do
      expect(subject.guest_token).to eq('some-token')
    end
  end

  describe '#params' do
    before do
      allow(subject).to receive(:current_user).and_return(user)
    end

    context 'without a current_user' do
      let(:user) { nil }

      specify do
        expect(subject.params).to eq(
          {
            "resources": [
              {
                "id": ss_dashboard_id,
                "type": "dashboard" }
            ],
            "rls": [],
            "user": { }
          }
        )
      end
    end

    context 'with a current_user' do
      let(:user) { double(id: 101) }
      
      specify 'passes user id and email to superset' do
        expect(subject.params).to eq(
          {
            "resources": [
              {
                "id": ss_dashboard_id,
                "type": "dashboard" }
            ],
            "rls": [],
            "user": { username: "101" }
          }
        )
      end
    end
  end
end

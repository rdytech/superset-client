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

    context 'when invalid rls clause is passed' do
      before { allow(subject).to receive(:rls_clause).and_return(rls_clause) }
      context 'when rls_clause is nil' do
        let(:rls_clause) { nil }
        it 'raises invalid parameter error' do
          expect{ subject.guest_token }.to raise_error(Superset::Request::InvalidParameterError, 'rls_clause should be an array. But it is NilClass')
        end
      end

      context 'when rls_clause is not an array' do
        let(:rls_clause) { { "clause": "publisher = 'Nintendo'" } }
        it 'raises invalid parameter error' do
          expect{ subject.guest_token }.to raise_error(Superset::Request::InvalidParameterError, "rls_clause should be an array. But it is Hash")
        end
      end
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

      specify 'passes user id to superset' do
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

    context 'with rls clause' do
      before { allow(subject).to receive(:rls_clause).and_return(rls_clause) }
      let(:user) { nil }
      let(:rls_clause) { [{ "clause": "publisher = 'Nintendo'" }] }
      specify do
        expect(subject.params).to eq(
          {
            "resources": [
              {
                "id": ss_dashboard_id,
                "type": "dashboard" }
            ],
            "rls": rls_clause,
            "user": { }
          }
        )
      end
    end

    context 'with rls clause as empty array' do
      before { allow(subject).to receive(:rls_clause).and_return(rls_clause) }
      let(:user) { nil }
      let(:rls_clause) { [] }
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
  end
end

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

    # guest_token/ is CSRF-protected (NEP-21211); the POST must carry an
    # X-CSRFToken and a same-origin Referer, like Client writes.
    context 'CSRF handling on the POST' do
      let(:headers) { {} }
      let(:host) { 'https://superset.example.com' }
      let(:connection) { instance_double(Faraday::Connection, headers: headers) }
      let(:csrf_response) { double(env: double(body: { 'result' => 'THE-TOKEN' })) }
      let(:post_response) { double(env: double(body: { 'token' => 'some-token' })) }

      before do
        allow(subject).to receive(:response_body).and_call_original
        allow(subject).to receive(:connection).and_return(connection)
        allow(subject).to receive(:authenticator).and_return(double(superset_host: host, access_token: 'bearer'))
        allow(connection).to receive(:get).with('api/v1/security/csrf_token/').and_return(csrf_response)
        allow(connection).to receive(:post).and_return(post_response)
      end

      it 'fetches a CSRF token and sets X-CSRFToken before the POST' do
        subject.guest_token
        expect(headers['X-CSRFToken']).to eq('THE-TOKEN')
      end

      it 'sets a same-origin Referer before the POST' do
        subject.guest_token
        expect(headers['Referer']).to eq(host)
      end
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
    context "with additional params" do
      before do
        allow(subject).to receive(:additional_params).and_return(additional_params)
      end

      context 'without a current_user' do
        let(:additional_params) { {} }

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
        let(:additional_params) { {embedded_app_current_user_id: 1} }

        specify 'passes user id to superset' do
          expect(subject.params).to eq(
            {
              "resources": [
                {
                  "id": ss_dashboard_id,
                  "type": "dashboard" }
              ],
              "rls": [],
              "user": { username: additional_params[:embedded_app_current_user_id].to_s },
              "embedded_app_current_user_id": additional_params[:embedded_app_current_user_id]
            }
          )
        end
      end
    end

    context 'with rls clause' do
      before { allow(subject).to receive(:rls_clause).and_return(rls_clause) }
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

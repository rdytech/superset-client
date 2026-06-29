require 'spec_helper'

RSpec.describe Superset::Client, type: :service do

  let(:authenticator) { double }
  let(:access_token) { 'some-access-token' }
  let(:host) { 'some-host.com' }

  before do
    allow(Superset::Authenticator).to receive(:new) { authenticator }
    allow(authenticator).to receive(:access_token) { access_token }
    allow(authenticator).to receive(:superset_host) { host }
    allow(subject).to receive(:credentials) { { username: 'api_username', password: 'api_password' } }
  end

  describe "#access_token" do
    it "returns the access token from the authenticator" do
      expect(subject.access_token).to eq(access_token)
    end
  end

  describe "#superset_host" do
    it "returns the superset host from the authenticator" do
      expect(subject.superset_host).to eq(host)
    end
  end

  describe "CSRF token handling (NEP-21211)" do
    let(:headers) { {} }
    let(:connection) { instance_double(Faraday::Connection, headers: headers) }

    before do
      # Any request returns a body carrying a csrf token; the write's own response
      # body is irrelevant to these assertions.
      allow(connection).to receive(:send).and_return(double(status: 200, body: { 'result' => 'THE-TOKEN' }))
      allow(subject).to receive(:connection).and_return(connection)
    end

    %i[post put patch delete].each do |verb|
      it "fetches a CSRF token and sets X-CSRFToken before a #{verb.upcase}" do
        subject.public_send(verb, 'chart/', { 'name' => 'x' })
        expect(headers['X-CSRFToken']).to eq('THE-TOKEN')
      end

      it "sets a same-origin Referer before a #{verb.upcase} (WTF_CSRF_SSL_STRICT)" do
        subject.public_send(verb, 'chart/', { 'name' => 'x' })
        expect(headers['Referer']).to eq(host)
      end
    end

    it "does not set X-CSRFToken or Referer for a GET (reads are never CSRF-checked)" do
      subject.get('chart/')
      expect(headers).not_to have_key('X-CSRFToken')
      expect(headers).not_to have_key('Referer')
    end

    it "fetches the token from the security/csrf_token endpoint" do
      expect(connection).to receive(:send)
        .with(:get, '/api/v1/security/csrf_token/', {})
        .and_return(double(status: 200, body: { 'result' => 'THE-TOKEN' }))
      allow(connection).to receive(:send).with(:post, anything, anything)
        .and_return(double(status: 201, body: {}))
      subject.post('chart/', { 'name' => 'x' })
    end
  end
end

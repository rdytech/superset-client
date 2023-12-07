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
end

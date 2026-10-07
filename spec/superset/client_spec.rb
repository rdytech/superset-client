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

  describe "CSRF token handling" do
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

  # The connection block is only evaluated on the first request, so a middleware
  # constant that no longer resolves surfaces as a runtime NameError rather than a
  # load-time failure. FaradayMiddleware::ParseJson used to sit here and only ever
  # reached the bundle transitively through happi; once happi dropped
  # faraday_middleware, every request through this client raised.
  describe "#connection" do
    let(:handler_classes) { subject.send(:connection).builder.handlers.map(&:klass) }

    it "builds without raising" do
      expect { subject.send(:connection) }.not_to raise_error
    end

    it "parses JSON with Faraday's own response middleware" do
      expect(handler_classes).to include(Faraday::Response::Json)
    end

    it "registers no FaradayMiddleware handler" do
      expect(handler_classes.select { |k| k.name.to_s.start_with?("FaradayMiddleware") }).to be_empty
    end
  end

  describe "#raise_error" do
    let(:logger) { instance_double(::Logger, info: nil, error: nil) }
    let(:response) { double(status: 404, body: body) }

    before { Superset.configure { |config| config.logger = logger } }
    after { Superset.configure { |config| config.logger = nil } }

    context "when the body carries errors" do
      let(:body) { { "errors" => [{ "message" => "Dashboard not found." }] } }

      it "raises the error mapped to the response status" do
        expect { subject.raise_error(response) }.to raise_error(Happi::Error::NotFound)
      end

      it "logs the error rather than printing it to stdout" do
        expect(logger).to receive(:error).with("API Error: #{body['errors']}")

        expect { subject.raise_error(response) }.to raise_error(Happi::Error::NotFound)
      end

      it "writes nothing to stdout" do
        expect { expect { subject.raise_error(response) }.to raise_error(Happi::Error::NotFound) }
          .not_to output.to_stdout
      end
    end

    context "when the body carries no errors key" do
      let(:body) { { "msg" => "Token has expired" } }

      it "falls back to the whole body" do
        expect(logger).to receive(:error).with("API Error: #{body}")

        expect { subject.raise_error(response) }.to raise_error(Happi::Error::NotFound)
      end
    end
  end
end

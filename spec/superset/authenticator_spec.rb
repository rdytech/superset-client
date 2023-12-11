require 'spec_helper'

RSpec.describe Superset::Authenticator do
  subject { described_class.new(credentials) }
  let(:credentials) { { username: 'test', password: 'test' } }

  before do
    allow(ENV).to receive(:[]).with(any_args).and_call_original
    allow(ENV).to receive(:[]).with('SUPERSET_HOST').and_return('http://localhost:8088')
    allow(subject).to receive(:response_body).and_return({
      "access_token"=> "some-access-token",
      "refresh_token"=> "some-refresh-token"
    })
  end

  describe '#initialize' do
    context 'with credentials' do 
      it 'returns an instance of Authenticator' do
        expect(subject).to be_an_instance_of(described_class)
      end
    end

    context 'with no credentials' do
      let(:credentials) { nil }

      it 'raises an error' do
        expect { described_class.new }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.call' do
    before do
      allow_any_instance_of(described_class).to receive(:response_body).and_return({
        "access_token"=> "some-access-token",
        "refresh_token"=> "some-refresh-token"
      })
    end

    it 'returns an instance of Authenticator' do
      expect(described_class.call(credentials)).to eq('some-access-token')
    end
  end

  describe '#access_token' do
    it 'returns the access token' do
      expect(subject.access_token).to eq('some-access-token')
    end
  end

  describe '#refresh_token' do
    it 'returns the refresh token' do
      expect(subject.refresh_token).to eq('some-refresh-token')
    end
  end

  describe '#validate_credential_existance' do
    context 'when a password is not present' do
      let(:credentials) { { username: 'test', password: '' } }

      it 'raises an error' do
        expect { subject.validate_credential_existance }.to raise_error(Superset::Authenticator::CredentialMissingError)
      end
    end

    context 'when a username is not present' do
      let(:credentials) { { username: '', password: 'test' } }

      it 'raises an error' do
        expect { subject.validate_credential_existance }.to raise_error(Superset::Authenticator::CredentialMissingError)
      end
    end
  end

  describe '#superset_host' do
    context 'when SUPERSET_HOST is not set' do
      it 'raises an error' do
        allow(ENV).to receive(:[]).with('SUPERSET_HOST').and_return(nil)

        expect { subject.superset_host }.to raise_error(Superset::Authenticator::CredentialMissingError)
      end
    end
    context 'when SUPERSET_HOST is set' do
      it 'returns the host' do
        expect(subject.superset_host).to eq('http://localhost:8088')
      end
    end
  end
end

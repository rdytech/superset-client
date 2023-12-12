require 'spec_helper'

RSpec.describe Superset::Security::User::Create do
  subject { described_class.new(user_params: user_params) }
  let(:role_ids) { [ 101 ] }
  let(:password) { 'some-password' }
  let(:tenant) { double('tenant', database: 'jobs_r_us')}
  let(:user_params) do
    {
      :active     => true,
      :email      => "teset@acme.com",
      :first_name => "Firstname",
      :last_name  => "Lastname",
      :password   => password,
      :roles      => role_ids,
      :username   => "firstname_lastname"
    }
  end

  before do
    allow(subject).to receive(:current_tenant).and_return(tenant)
    allow(subject).to receive(:password).and_return(password)
  end

  describe '#validate_user_params' do
    context 'with valid params' do
      specify do
        expect { subject.validate_user_params }.not_to raise_error
      end
    end

    context 'with invalid params' do
      context 'when params are empty' do
        let(:user_params) { {} }

        specify do
          expect { subject.validate_user_params }.to raise_error(Superset::Security::User::Create::InvalidParameterError)
        end
      end

      context 'when params are missing' do
        let(:user_params) do
          {
            :active     => true,
            :password   => 'some-password',
            :roles      => role_ids,
            :username   => "firstname_lastnamer"
          }
        end

        specify do
          expect { subject.validate_user_params }.to raise_error(Superset::Security::User::Create::InvalidParameterError)
        end
      end

      context 'when params are empty' do
        let(:password) { '' }

        specify do
          expect { subject.validate_user_params }.to raise_error(Superset::Security::User::Create::InvalidParameterError)
        end
      end

      context 'when role_ids is not an array' do
        let(:role_ids) { '' }

        specify do
          expect { subject.validate_user_params }.to raise_error(Superset::Security::User::Create::InvalidParameterError)
        end
      end
    end
  end

  # NOTE: response does not really test anything but does provide some context
  # for what the response is
  describe '#response' do
    let(:response) { {"id"=>101} }

    context 'with a valid role_id' do
      before { allow(subject).to receive(:response).and_return(response) }

      specify 'returns the id of the new user' do
        expect(subject.response).to eq response
      end
    end
  end
end

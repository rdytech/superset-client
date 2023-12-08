require 'spec_helper'

RSpec.describe Superset::Security::User::Create do
  subject { described_class.new(role_id) }
  let(:role_id) { 101 }
  let(:password) { 'some-password' }
  let(:tenant) { double('tenant', database: 'jobs_r_us')}

  before do
    allow(subject).to receive(:current_tenant).and_return(tenant)
    allow(subject).to receive(:password).and_return(password)
  end

  describe '#params' do
    specify do
      expect(subject.params).to eq({
        :active     => true,
        :email      => "jobready_jobs_r_us_embedded_user@ewp.readytech.io",
        :first_name => "Jobready Application",
        :last_name  => "jobready_jobs_r_us_embedded_user",
        :password   => password,
        :roles      => [ role_id ],
        :username   => "jobready_jobs_r_us_embedded_user"
      })
    end
  end

  describe '#identifier' do
    specify do
      expect(subject.identifier).to eq("jobready_jobs_r_us_embedded_user")
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

    context 'with an invalid role_id' do
      let(:role_id) { '' }

      specify 'raises an error' do
        expect { subject.response }.to raise_error(Superset::Security::User::Create::InvalidParameterError)
      end
    end
  end
end

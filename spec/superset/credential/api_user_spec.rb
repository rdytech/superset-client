require 'spec_helper'
require 'superset/credential/api_user'

RSpec.describe Superset::Credential::ApiUser do
  subject { dummy_class.new }
  let(:dummy_class) { Class.new { include Superset::Credential::ApiUser } }
  let(:api_username) { 'api_username' }
  let(:api_password) { 'api_password' }

  before do 
    allow(ENV).to receive(:[]).with('SUPERSET_API_USERNAME').and_return(api_username)
    allow(ENV).to receive(:[]).with('SUPERSET_API_PASSWORD').and_return(api_password)
  end

  describe '#credentials' do
    it 'returns the api credentials' do
      expect(subject.credentials).to eq(
        { username: api_username, 
          password: api_password,
          provider: 'db',
          refresh: false
        })
    end
  end
end
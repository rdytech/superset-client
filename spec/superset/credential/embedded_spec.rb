require 'spec_helper'
require 'superset/credential/embedded_user'

RSpec.describe Superset::Credential::EmbeddedUser do
  subject { dummy_class.new }
  let(:dummy_class) { Class.new { include Superset::Credential::EmbeddedUser } }
  let(:embedded_username) { 'your_username' }
  let(:embedded_password) { 'your_password' }

  before do 
    allow(ENV).to receive(:[]).with('SUPERSET_EMBEDDED_USERNAME').and_return(embedded_username)
    allow(ENV).to receive(:[]).with('SUPERSET_EMBEDDED_PASSWORD').and_return(embedded_password)
  end

  describe '#credentials' do
    it 'returns the embedded credentials' do
      expect(subject.credentials).to eq(
        { username: 'your_username', 
          password: 'your_password',
          provider: 'db',
          refresh: false
        })
    end
  end
end
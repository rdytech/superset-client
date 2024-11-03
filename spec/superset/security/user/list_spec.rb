require 'spec_helper'

RSpec.describe Superset::Security::User::List do
  subject { described_class.new }
  let(:superset_host) { 'https://test.superset.host.com' }
  let(:result) do
    [{
      active: true,
      email: "ben.barrow@mymail.io",
      first_name: "Ben",
      id: 99,
      last_login: "2023-11-07T01:20:52.690091",
      last_name: "Barrow",
      login_count: 7,
      username: "a76cf-153b47"
    },{
      active: true,
      email: "em.vier@mymail.io",
      first_name: "Em",
      id: 44,
      last_login: "2023-09-12T07:36:07.115849",
      last_name: "Vier",
      login_count: 2,
      username: "fc335-f07df6"
    },{
      active: true,
      email: "raf.zar@mymail.io",
      fail_login_count: 0,
      first_name: "Raf",
      id: 55,
      last_login: "2023-10-27T03:32:44.185404",
      last_name: "Zar",
      login_count: 2,
      username: "e8394-sdf984"
    }]
  end

  let(:default_query_params) { "page:0,page_size:100,order_column:changed_on,order_direction:desc" }

  before do
    allow(subject).to receive(:result).and_return(result)
    allow(subject).to receive(:superset_host).and_return(superset_host)
    allow(subject).to receive(:response).and_return( { 'count': 45 } )
  end

  describe '#query_params' do
    specify 'with defaults' do
      expect(subject.query_params).to eq(default_query_params)
    end

    context 'with email filters' do
      subject { described_class.new(email_contains: 'mymail') }

      specify do
        expect(subject.query_params).to eq("filters:!((col:email,opr:ct,value:mymail)),#{default_query_params}")
      end
    end
  end
end

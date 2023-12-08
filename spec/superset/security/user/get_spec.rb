require 'spec_helper'

RSpec.describe Superset::Security::User::Get do
  subject { described_class.new(user_id) }
  let(:user_id) { 99 }
  let(:response) do
    {
      "description_columns"=>{},
      "id"=>9,
      "label_columns"=> {
        "active"=>"Active", "changed_by.id"=>"Changed By Id", "changed_on"=>"Changed On", "created_by.id"=>"Created By Id", "created_on"=>"Created On",
        "email"=>"Email", "fail_login_count"=>"Fail Login Count", "first_name"=>"First Name", "id"=>"Id", "last_login"=>"Last Login",
        "last_name"=>"Last Name", "login_count"=>"Login Count", "roles.id"=>"Roles Id", "roles.name"=>"Roles Name", "username"=>"Username"},
      "result"=>
       {"active"=>true,
        "changed_by"=>{"id"=>9},
        "changed_on"=>"2023-11-19T23:59:14.960962",
        "created_by"=>nil,
        "created_on"=>"2023-06-21T12:29:02.452271",
        "email"=>"test@readytech.io",
        "fail_login_count"=>0,
        "first_name"=>"Some",
        "id"=>9,
        "last_login"=>"2023-11-21T04:21:24.561309",
        "last_name"=>"User",
        "login_count"=>510,
        "roles"=>
          [{"id"=>3, "name"=>"Role1"},
           {"id"=>6, "name"=>"Role2"},
           {"id"=>19, "name"=>"Role3"}],
        "username"=>"4bf1xxxx-xxxx-xxxx-xxxx-xxxxxxxxe3f5"},
      "show_columns"=>
       ["id", "roles.id", "roles.name", "first_name", "last_name", "username", "active", "email", "last_login", "login_count", "fail_login_count",
        "created_on", "changed_on", "created_by.id", "changed_by.id"],
      "show_title"=>"Show User"
    }.with_indifferent_access
  end

  before do
    allow(subject).to receive(:response).and_return(response)
  end

  describe '#result' do
    it 'returns the response result' do
      expect(subject.result).to eq([response['result']])
    end
  end

  describe '#rows' do
    it 'pulls only the list_attributes out' do
      expect(subject.rows).to eq( [["9", "Some", "User", "test@readytech.io", "510", "2023-11-21T04:21:24.561309"]] )
    end
  end
end

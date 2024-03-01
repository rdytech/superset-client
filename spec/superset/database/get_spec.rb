require 'spec_helper'

RSpec.describe Superset::Database::Get do
  subject { described_class.new(id) }
  let(:id) { 111 }
  let(:result) do
    [{
      "allow_ctas"=>false,
      "allow_cvas"=>false,
      "allow_dml"=>false,
      "allow_file_upload"=>false,
      "allow_run_async"=>false,
      "backend"=>"postgresql",
      "cache_timeout"=>nil,
      "configuration_method"=>"dynamic_form",
      "database_name"=>"Some-Staging-Db",
      "driver"=>"psycopg2",
      "engine_information"=>{"disable_ssh_tunneling"=>false, "supports_file_upload"=>true},
      "expose_in_sqllab"=>true,
      "force_ctas_schema"=>nil,
      "id"=>111,
      "impersonate_user"=>false,
      "is_managed_externally"=>false,
      "uuid"=>"dbc74......06f6"
    }]
  end

  before do
    allow(subject).to receive(:result).and_return(result)
  end

  describe '.call' do
    specify do
      expect_any_instance_of(described_class).to receive(:list)
      described_class.call(id)
    end
  end

  describe '#rows' do
    specify do
      expect(subject.rows).to eq [["111", "Some-Staging-Db", "postgresql", "psycopg2", "true", "", "false"]]
    end
  end
end

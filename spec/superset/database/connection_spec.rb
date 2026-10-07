require 'spec_helper'

RSpec.describe Superset::Database::Connection do
  subject { described_class.new(id) }
  let(:id) { 111 }
  let(:result) do
    {
      "backend" => "postgresql",
      "database_name" => "Acme Client Staging",             # User defined value to reference the database
      "driver" => "psycopg2",
      "id" => 21,
      "parameters" => {
        "database" => "acme_staging",                       # actual database name to connect to
        "host" => "some.host.com",
      }
    }
  end

  before do
    allow(subject).to receive(:result).and_return(result)
  end

  describe '.call' do
    specify do
      expect_any_instance_of(described_class).to receive(:result)
      described_class.call(id)
    end
  end

  describe '#connection_db_name' do
    specify do
      expect(subject.connection_db_name).to eq "acme_staging"
    end
  end
end

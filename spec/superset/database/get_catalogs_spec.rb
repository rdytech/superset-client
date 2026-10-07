require 'spec_helper'

RSpec.describe Superset::Database::GetCatalogs do
  subject { described_class.new(id, **opts) }
  let(:id) { 111 }
  let(:opts) { {} }
  let(:full_catalog_list) do
    [
      "postgres",
      "rdsadmin",
      "template1",
      "pool_1_clients"
    ]
  end

  before do
    allow(subject).to receive(:result).and_return(full_catalog_list)
  end

  describe '.call' do
    specify do
      expect_any_instance_of(described_class).to receive(:catalogs)
      described_class.call(id)
    end
  end

  describe '#catalogs' do
    specify 'by default excludes system catalogs' do
      expect(subject.catalogs).to eq ["pool_1_clients"]
    end

    context 'when include_system_catalogs is true' do
      let(:opts) { { include_system_catalogs: true } }
     
      specify 'can optionally include system catalogs' do
        expect(subject.catalogs).to eq full_catalog_list
      end
    end
  end
end

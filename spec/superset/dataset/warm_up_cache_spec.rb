require 'spec_helper'

RSpec.describe Superset::Dataset::WarmUpCache do
  subject { described_class.new(dashboard_id: dashboard_id, table_name: table_name, db_name: db_name) }
  let(:dashboard_id) { 1 }
  let(:table_name) { "Dataset 101"}
  let(:db_name) { "Client Database 1" }
  before do
    allow(subject).to receive(:response).and_return(response)
  end

  describe '.perform' do
    let(:response) { 'Dataset warmed up' }

    it 'warms up the dataset' do
      expect(subject.perform).to eq response
    end
  end
end

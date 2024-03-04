require 'spec_helper'

RSpec.describe Superset::Database::GetSchemas do
  subject { described_class.new(id) }
  let(:id) { 111 }
  let(:result_schemas) do
    [
      "schema_one",
      "schema_two",
      "schema_three"
    ]
  end

  before do
    allow(subject).to receive(:result).and_return(result_schemas)
    allow(subject).to receive(:schemas).and_return(result_schemas)
  end

  describe '.call' do
    specify do
      expect_any_instance_of(described_class).to receive(:schemas)
      described_class.call(id)
    end
  end

  describe '#schemas' do
    specify do
      expect(subject.schemas).to eq result_schemas
    end
  end
end

require 'spec_helper'

RSpec.describe Superset::Dataset::Refresh do
  subject { described_class.new(id) }
  let(:id) { 1 }
  let(:result) { { "message": "OK" } }

  before do
    allow(subject).to receive(:response).and_return(result)
  end

  describe '.call' do
    specify do
      expect_any_instance_of(described_class).to receive(:perform)
      described_class.call(id)
    end
  end

  describe '#perform' do
    specify do
      expect(subject.perform).to eq result
    end
  end
end

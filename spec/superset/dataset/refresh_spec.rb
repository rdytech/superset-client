require 'spec_helper'

RSpec.describe Superset::Dataset::Refresh do
  subject { described_class.new(id) }
  let(:id) { 1 }
  let(:result) { { "message": "OK" } }
  let(:client) { instance_double(Superset::Client) }

  before do
    allow(subject).to receive(:client).and_return(client)
  end

  describe '.call' do
    specify do
      expect_any_instance_of(described_class).to receive(:perform)
      described_class.call(id)
    end
  end

  describe '#perform' do
    specify do
      expect(client).to receive(:put).with("dataset/#{id}/refresh").and_return(result)
      expect(subject.perform).to eq result
    end
  end

  describe '#response' do
    specify 'memoizes the response' do
      expect(client).to receive(:put).with("dataset/#{id}/refresh").once.and_return(result)
      2.times { subject.response }
    end
  end
end

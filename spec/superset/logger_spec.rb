require 'spec_helper'

RSpec.describe Superset::Logger do
  after { Superset.reset_configuration! }

  let(:configured_logger) { instance_double(::Logger, info: nil, error: nil) }

  before { Superset.configure { |c| c.logger = configured_logger } }

  describe '#info' do
    it 'forwards to Superset.logger' do
      described_class.new.info("hello")
      expect(configured_logger).to have_received(:info).with("hello")
    end
  end

  describe '#error' do
    it 'forwards to Superset.logger' do
      described_class.new.error("boom")
      expect(configured_logger).to have_received(:error).with("boom")
    end
  end

  context 'when no logger is configured' do
    before { Superset.reset_configuration! }

    it 'still returns a working ::Logger via the fallback' do
      expect { described_class.new.info("hello") }.not_to raise_error
    end
  end
end

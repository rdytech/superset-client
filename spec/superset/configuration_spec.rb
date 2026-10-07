require 'spec_helper'

RSpec.describe Superset do
  after { Superset.reset_configuration! }

  describe '.configuration' do
    it 'returns a Superset::Configuration instance' do
      expect(Superset.configuration).to be_a(Superset::Configuration)
    end

    it 'memoizes the configuration' do
      expect(Superset.configuration).to equal(Superset.configuration)
    end
  end

  describe '.configure' do
    it 'yields the configuration for mutation' do
      custom_logger = ::Logger.new(IO::NULL)
      Superset.configure { |c| c.logger = custom_logger }
      expect(Superset.configuration.logger).to equal(custom_logger)
    end
  end

  describe '.logger' do
    context 'when no logger is configured' do
      it 'falls back to a ::Logger writing to log/superset-client.log' do
        expect(Superset.logger).to be_a(::Logger)
      end

      it 'returns the same fallback logger across calls' do
        expect(Superset.logger).to equal(Superset.logger)
      end
    end

    context 'when a logger is configured' do
      let(:custom_logger) { ::Logger.new(IO::NULL) }

      before { Superset.configure { |c| c.logger = custom_logger } }

      it 'returns the configured logger' do
        expect(Superset.logger).to equal(custom_logger)
      end
    end
  end

  describe '.reset_configuration!' do
    it 'clears the configured logger' do
      custom_logger = ::Logger.new(IO::NULL)
      Superset.configure { |c| c.logger = custom_logger }
      Superset.reset_configuration!
      expect(Superset.configuration.logger).to be_nil
    end
  end
end

require 'spec_helper'

RSpec.describe Superset::Dashboard::Delete do
  subject { described_class.new(dashboard_id: dashboard_id) }
  let(:dashboard_id) { 1 }
  let(:response) { nil }

  before do
    allow(subject).to receive(:response).and_return(response)
  end

  describe '.perform' do
    context 'when dashboard_id is not present' do
      let(:dashboard_id) { nil }

      it 'raises an error' do
        expect { subject.perform }.to raise_error(RuntimeError, "Error: dashboard_id integer is required")
      end
    end

    context 'when dashboard_id is not an integer' do
      let(:dashboard_id) { 'string' }

      it 'raises an error' do
        expect { subject.perform }.to raise_error(RuntimeError, "Error: dashboard_id integer is required")
      end
    end

    context 'when dashboard_id is an integer' do
      let(:response) { 'response' }

      context 'when confirm_zero_charts is true' do
        it 'deletes the dashboard after confirm_zero_charts_on_dashboard' do
          expect(subject).to receive(:confirm_zero_charts_on_dashboard)
          expect(subject).to receive(:response)
          subject.perform
        end
      end

      context 'when confirm_zero_charts is false' do
        subject { described_class.new(dashboard_id: dashboard_id, confirm_zero_charts: false) }

        it 'deletes the dashboard and does not confirm_zero_charts_on_dashboard' do
          expect(subject).to_not receive(:confirm_zero_charts_on_dashboard)
          expect(subject).to receive(:response)
          subject.perform
        end
      end
    end
  end
end

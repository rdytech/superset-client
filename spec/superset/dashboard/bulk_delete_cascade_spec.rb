require 'spec_helper'

RSpec.describe Superset::Dashboard::BulkDeleteCascade do
  subject { described_class.new(dashboard_ids: dashboard_ids, dry_run: dry_run) }
  let(:dashboard_ids) { nil }
  let(:dry_run) { true }

  describe '#dry_run' do
    it 'defaults to true when not passed' do
      instance = described_class.new(dashboard_ids: [1])
      expect(instance.dry_run).to eq(true)
    end
  end

  describe '.perform' do
    context 'when dashboard_ids is not present' do
      it 'raises an error' do
        expect { subject.perform }.to raise_error(Superset::Dashboard::BulkDeleteCascade::InvalidParameterError, "dashboard_ids array of integers expected")
      end
    end

    context 'when dashboard_ids contains non integer values' do
      let(:dashboard_ids) { [1, 'string'] }

      it 'raises an error' do
        expect { subject.perform }.to raise_error(Superset::Dashboard::BulkDeleteCascade::InvalidParameterError, "dashboard_ids array must contain Integer only values")
      end
    end

    context 'when dashboard_ids are valid' do
      let(:dashboard_ids) { [1] }
      let(:datasets_list) { double('Datasets::List', ids: [11, 12]) }
      let(:charts_list) { double('Charts::List', chart_ids: [21, 22]) }

      before do
        allow(Superset::Dashboard::Datasets::List).to receive(:new).with(dashboard_id: 1).and_return(datasets_list)
        allow(Superset::Dashboard::Charts::List).to receive(:new).with(1).and_return(charts_list)
      end

      context 'when dry_run is true (default)' do
        let(:dry_run) { true }

        it 'returns true without calling delete services' do
          expect(Superset::Dataset::BulkDelete).not_to receive(:new)
          expect(Superset::Chart::BulkDelete).not_to receive(:new)
          expect(Superset::Dashboard::Delete).not_to receive(:new)

          expect(subject.perform).to eq(true)
        end
      end

      context 'when dry_run is false' do
        let(:dry_run) { false }

        before do
          allow(Superset::Dataset::BulkDelete).to receive(:new).with(dataset_ids: [11, 12]).and_return(double(perform: true))
          allow(Superset::Chart::BulkDelete).to receive(:new).with(chart_ids: [21, 22]).and_return(double(perform: true))
          allow(Superset::Dashboard::Delete).to receive(:new).with(dashboard_id: 1, confirm_zero_charts: true).and_return(double(perform: true))
        end

        it 'bulk deletes related charts, datasets and the dashboard' do
          expect(subject.perform).to eq(true)
        end

        it 'calls Dataset::BulkDelete, Chart::BulkDelete and Dashboard::Delete' do
          subject.perform

          expect(Superset::Dataset::BulkDelete).to have_received(:new).with(dataset_ids: [11, 12])
          expect(Superset::Chart::BulkDelete).to have_received(:new).with(chart_ids: [21, 22])
          expect(Superset::Dashboard::Delete).to have_received(:new).with(dashboard_id: 1, confirm_zero_charts: true)
        end
      end
    end
  end
end

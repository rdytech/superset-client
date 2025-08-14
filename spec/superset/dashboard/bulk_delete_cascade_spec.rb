require 'spec_helper'

RSpec.describe Superset::Dashboard::BulkDeleteCascade do
  subject { described_class.new(dashboard_ids: dashboard_ids) }
  let(:dashboard_ids) { nil }

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

      before do
        allow(Superset::Dashboard::Datasets::List).to receive(:new).with(dashboard_id: 1).and_return(double(datasets_details: {'datasets' => [{ id: 11 }, { id: 12 }] }))
        allow(Superset::Dataset::BulkDelete).to receive(:new).with(dataset_ids: [11,12]).and_return(double(perform: true))

        allow(Superset::Dashboard::Charts::List).to receive(:new).with(1).and_return(double(chart_ids: [21, 22]))
        allow(Superset::Chart::BulkDelete).to receive(:new).with(chart_ids: [21, 22]).and_return(double(perform: true))

        allow(Superset::Dashboard::Delete).to receive(:new).with(dashboard_id: 1, confirm_zero_charts: true).and_return(double(perform: true))
      end

      it 'bulk deletes related charts, datasets and the dashboard' do
        expect(subject.perform).to eq(true)
      end
    end
  end
end

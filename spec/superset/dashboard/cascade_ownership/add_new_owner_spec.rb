require 'spec_helper'

RSpec.describe Superset::Dashboard::CascadeOwnership::AddNewOwner do
  subject { described_class.new(dashboard_id: dashboard_id, user_id: user_id) }

  let(:dashboard_id) { 1 }
  let(:user_id) { 100 }
  let(:existing_dashboard_owner_ids) { [1, 2] }
  let(:chart_ids) { [10, 20] }
  let(:dataset_ids) { [30, 40] }

  let(:dashboard_result) do
    {
      'id' => dashboard_id,
      'owners' => existing_dashboard_owner_ids.map { |id| { 'id' => id, 'first_name' => 'User', 'last_name' => id.to_s } }
    }
  end

  let(:chart_1_owners) { [{ 'id' => 1, 'first_name' => 'User', 'last_name' => '1' }] }
  let(:chart_2_owners) { [{ 'id' => 2, 'first_name' => 'User', 'last_name' => '2' }] }

  let(:dataset_1_owners) { [{ 'id' => 1, 'first_name' => 'User', 'last_name' => '1' }] }
  let(:dataset_2_owners) { [{ 'id' => 2, 'first_name' => 'User', 'last_name' => '2' }] }

  before do
    # Mock Dashboard::Get
    dashboard_get = instance_double(Superset::Dashboard::Get)
    allow(Superset::Dashboard::Get).to receive(:new).with(dashboard_id).and_return(dashboard_get)
    allow(dashboard_get).to receive(:result).and_return(dashboard_result)

    # Mock Dashboard::Put
    dashboard_put = instance_double(Superset::Dashboard::Put)
    allow(Superset::Dashboard::Put).to receive(:new).and_return(dashboard_put)
    allow(dashboard_put).to receive(:perform).and_return({ 'result' => { 'id' => dashboard_id } })

    # Mock Dashboard::Charts::List
    charts_list = instance_double(Superset::Dashboard::Charts::List)
    allow(Superset::Dashboard::Charts::List).to receive(:new).with(dashboard_id).and_return(charts_list)
    allow(charts_list).to receive(:ids).and_return(chart_ids)

    # Mock Chart::Get for each chart
    chart_1_get = instance_double(Superset::Chart::Get)
    chart_2_get = instance_double(Superset::Chart::Get)
    allow(Superset::Chart::Get).to receive(:new).with(10).and_return(chart_1_get)
    allow(Superset::Chart::Get).to receive(:new).with(20).and_return(chart_2_get)
    allow(chart_1_get).to receive(:result).and_return({ 'owners' => chart_1_owners })
    allow(chart_2_get).to receive(:result).and_return({ 'owners' => chart_2_owners })

    # Mock Chart::Put
    chart_put = instance_double(Superset::Chart::Put)
    allow(Superset::Chart::Put).to receive(:new).and_return(chart_put)
    allow(chart_put).to receive(:perform).and_return({ 'result' => { 'id' => 10 } })

    # Mock Dashboard::Datasets::List
    datasets_list = instance_double(Superset::Dashboard::Datasets::List)
    allow(Superset::Dashboard::Datasets::List).to receive(:new).with(dashboard_id: dashboard_id, include_filter_datasets: true).and_return(datasets_list)
    allow(datasets_list).to receive(:ids).and_return(dataset_ids)

    # Mock Dataset::Get for each dataset
    dataset_1_get = instance_double(Superset::Dataset::Get)
    dataset_2_get = instance_double(Superset::Dataset::Get)
    allow(Superset::Dataset::Get).to receive(:new).with(30).and_return(dataset_1_get)
    allow(Superset::Dataset::Get).to receive(:new).with(40).and_return(dataset_2_get)
    allow(dataset_1_get).to receive(:result).and_return({ 'owners' => dataset_1_owners })
    allow(dataset_2_get).to receive(:result).and_return({ 'owners' => dataset_2_owners })

    # Mock Dataset::Put
    dataset_put = instance_double(Superset::Dataset::Put)
    allow(Superset::Dataset::Put).to receive(:new).and_return(dataset_put)
    allow(dataset_put).to receive(:perform).and_return({ 'result' => { 'id' => 30 } })
  end

  describe '#initialize' do
    it 'sets dashboard_id and user_id' do
      expect(subject.dashboard_id).to eq(dashboard_id)
      expect(subject.user_id).to eq(user_id)
    end
  end

  describe '#perform' do
    context 'with valid parameters' do
      it 'adds user to dashboard ownership' do
        expect(Superset::Dashboard::Put).to receive(:new).with(
          target_id: dashboard_id,
          params: { owners: existing_dashboard_owner_ids + [user_id] }
        ).and_return(instance_double(Superset::Dashboard::Put, perform: {}))

        subject.perform
      end

      it 'adds user to all charts ownership' do
        chart_put_instance = instance_double(Superset::Chart::Put, perform: {})
        allow(Superset::Chart::Put).to receive(:new).and_return(chart_put_instance)

        expect(Superset::Chart::Put).to receive(:new).with(
          target_id: 10,
          params: { owners: [1, user_id] }
        )
        expect(Superset::Chart::Put).to receive(:new).with(
          target_id: 20,
          params: { owners: [2, user_id] }
        )

        subject.perform
      end

      it 'adds user to all datasets ownership' do
        dataset_put_instance = instance_double(Superset::Dataset::Put, perform: {})
        allow(Superset::Dataset::Put).to receive(:new).and_return(dataset_put_instance)

        expect(Superset::Dataset::Put).to receive(:new).with(
          target_id: 30,
          params: { owners: [1, user_id] }
        )
        expect(Superset::Dataset::Put).to receive(:new).with(
          target_id: 40,
          params: { owners: [2, user_id] }
        )

        subject.perform
      end

      it 'performs all ownership updates' do
        dashboard_put_instance = instance_double(Superset::Dashboard::Put)
        chart_put_instance = instance_double(Superset::Chart::Put)
        dataset_put_instance = instance_double(Superset::Dataset::Put)

        allow(Superset::Dashboard::Put).to receive(:new).and_return(dashboard_put_instance)
        allow(Superset::Chart::Put).to receive(:new).and_return(chart_put_instance)
        allow(Superset::Dataset::Put).to receive(:new).and_return(dataset_put_instance)

        expect(dashboard_put_instance).to receive(:perform).once
        expect(chart_put_instance).to receive(:perform).twice
        expect(dataset_put_instance).to receive(:perform).twice

        subject.perform
      end
    end

    context 'when user is already a dashboard owner' do
      let(:existing_dashboard_owner_ids) { [1, 2, user_id] }

      it 'does not add user to dashboard ownership again' do
        expect(Superset::Dashboard::Put).not_to receive(:new)
        subject.perform
      end

      it 'still adds user to charts and datasets' do
        chart_put_instance = instance_double(Superset::Chart::Put, perform: {})
        dataset_put_instance = instance_double(Superset::Dataset::Put, perform: {})

        allow(Superset::Chart::Put).to receive(:new).and_return(chart_put_instance)
        allow(Superset::Dataset::Put).to receive(:new).and_return(dataset_put_instance)

        expect(chart_put_instance).to receive(:perform).twice
        expect(dataset_put_instance).to receive(:perform).twice

        subject.perform
      end
    end

    context 'when user is already a chart owner' do
      let(:chart_1_owners) { [{ 'id' => 1 }, { 'id' => user_id }] }

      it 'skips adding user to that chart' do
        chart_put_instance = instance_double(Superset::Chart::Put, perform: {})
        allow(Superset::Chart::Put).to receive(:new).and_return(chart_put_instance)

        # Should only be called for chart 20, not chart 10
        expect(Superset::Chart::Put).to receive(:new).with(
          target_id: 20,
          params: { owners: [2, user_id] }
        ).once

        subject.perform
      end
    end

    context 'when user is already a dataset owner' do
      let(:dataset_1_owners) { [{ 'id' => 1 }, { 'id' => user_id }] }

      it 'skips adding user to that dataset' do
        dataset_put_instance = instance_double(Superset::Dataset::Put, perform: {})
        allow(Superset::Dataset::Put).to receive(:new).and_return(dataset_put_instance)

        # Should only be called for dataset 40, not dataset 30
        expect(Superset::Dataset::Put).to receive(:new).with(
          target_id: 40,
          params: { owners: [2, user_id] }
        ).once

        subject.perform
      end
    end

    context 'with invalid dashboard_id' do
      context 'when dashboard_id is nil' do
        let(:dashboard_id) { nil }

        it 'raises an error' do
          expect { subject.perform }.to raise_error('Error: dashboard_id integer is required')
        end
      end

      context 'when dashboard_id is not an integer' do
        let(:dashboard_id) { 'invalid' }

        it 'raises an error' do
          expect { subject.perform }.to raise_error('Error: dashboard_id integer is required')
        end
      end
    end

    context 'with invalid user_id' do
      context 'when user_id is nil' do
        let(:user_id) { nil }

        it 'raises an error' do
          expect { subject.perform }.to raise_error('Error: user_id integer is required')
        end
      end

      context 'when user_id is not an integer' do
        let(:user_id) { 'invalid' }

        it 'raises an error' do
          expect { subject.perform }.to raise_error('Error: user_id integer is required')
        end
      end
    end

    context 'when dashboard has no charts' do
      let(:chart_ids) { [] }

      it 'does not attempt to update any charts' do
        expect(Superset::Chart::Put).not_to receive(:new)
        subject.perform
      end
    end

    context 'when dashboard has no datasets' do
      let(:dataset_ids) { [] }

      it 'does not attempt to update any datasets' do
        expect(Superset::Dataset::Put).not_to receive(:new)
        subject.perform
      end
    end
  end
end


require 'spec_helper'

RSpec.describe Superset::Dashboard::Embedded::Get, type: :service do
  subject { described_class.new(dashboard_id: dashboard_id) }
  let(:dashboard_id) { 1 }

  describe 'with a dashboard that has embedded settings, ie has a result' do
    let(:allowed_domains) { ['http://test-domain.io/'] }
    let(:uuid) { '631bxxxx-xxxx-xxxx-xxxx-xxxxxxxxx247' }
    let(:response) do
      {
        'result' =>
          {
            "allowed_domains" => allowed_domains,
            "changed_on"      => "2023-10-30T03:06:51.437527",
            "dashboard_id"    => "1",
            "uuid"            => uuid
          }.with_indifferent_access
      }.with_indifferent_access
    end

    before do
      allow(subject).to receive(:response).and_return(response)
      allow(subject).to receive(:title).and_return('1: Test Dashboard')
    end

    describe '#allowed_domains' do
      it 'returns a list of allowed domains' do
        expect(subject.allowed_domains).to eq(allowed_domains)
      end
    end

    describe '#uuid' do
      it 'returns uuid' do
        expect(subject.uuid).to eq(uuid)
      end
    end

    describe '#table' do
      it 'prints a table with the dashboard title and charts' do
        expect(subject.table.to_s).to eq(
          "+------------------------------------------------------------------------------------------------------------+\n" \
          "|                                             1: Test Dashboard                                              |\n" \
          "+-----------+--------------------------------------+----------------------------+----------------------------+\n" \
          "| Dashboard | Uuid                                 | Allowed domains            | Changed on                 |\n" \
          "+-----------+--------------------------------------+----------------------------+----------------------------+\n" \
          "| 1         | 631bxxxx-xxxx-xxxx-xxxx-xxxxxxxxx247 | [\"http://test-domain.io/\"] | 2023-10-30T03:06:51.437527 |\n" \
          "+-----------+--------------------------------------+----------------------------+----------------------------+"
        )
      end
    end
  end

  describe 'with a dashboard that DOES NOT have any embedded settings' do
    before do
      allow(subject).to receive(:title).and_return('1: Test Dashboard')
      allow(subject).to receive(:client).and_raise(Happi::Error::NotFound)
    end

    describe '#response' do
      specify do
        expect(subject.response).to eq({ 'result' => [] })
      end
    end

    describe '#result' do
      specify 'is an empty array' do
        expect(subject.result).to eq([])
      end
    end

    describe '#allowed_domains' do
      it 'returns a list of allowed domains' do
        expect(subject.allowed_domains).to eq(nil)
      end
    end

    describe '#uuid' do
      it 'returns uuid' do
        expect(subject.uuid).to eq(nil)
      end
    end

    describe '#table' do
      it 'prints a table with zero rows' do
        expect(subject.table.to_s).to eq(
          "+-------------------------------------------------+\n" \
          "|                1: Test Dashboard                |\n" \
          "+-----------+------+-----------------+------------+\n" \
          "| Dashboard | Uuid | Allowed domains | Changed on |\n" \
          "+-----------+------+-----------------+------------+\n" \
          "+-------------------------------------------------+"
        )
      end
    end
  end
end

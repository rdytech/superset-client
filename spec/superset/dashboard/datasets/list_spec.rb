require 'spec_helper'

RSpec.describe Superset::Dashboard::Datasets::List do
  subject { described_class.new(dashboard_id) }
  let(:dashboard_id) { 1 }
  let(:result) do
    [
      {
        id: 101,
        datasource_name: 'Acme Forcasts',
        database: { id: 1, name: 'DB1', backend: 'postgres' },
        schema: 'acme'
      },
      {
        id: 102,
        datasource_name: 'video_game_sales',
        database: { id: 2, name: 'examples', backend: 'postgres' },
        schema: 'public'
      }
    ]
  end

  before do
    allow(subject).to receive(:result).and_return(result)
    allow(subject).to receive(:title).and_return('1: Test Dashboard')
  end

  describe '#schemas' do
    context 'when the dashboard has dastasets from multiple schemas' do
      it 'returns a list of schemas' do
        expect(subject.schemas).to eq(['acme', 'public'])
      end

      it 'raises a rollbar if there is more than 1 uniq schema' do
        expect(Rollbar).to receive(:error).with(
          "SUPERSET DASHBOARD ERROR: Dashboard id #{dashboard_id} has multiple dataset schema linked: [\"acme\", \"public\"]")
        subject.schemas
      end
    end

    context 'with a single schema' do
      before do
        allow(subject).to receive(:schemas).and_return(['acme'])
      end

      it 'returns a single schemas' do
        expect(subject.schemas).to eq(['acme'])
      end

      it 'does not raise a rollbar if there is 1 uniq schema' do
        expect(Rollbar).to_not receive(:error)
        subject.schemas
      end
    end
  end

  describe '#table' do
    it 'prints a table with the dashboard title and charts' do

      expect(subject.table.to_s).to eq(
        "+-----+------------------+----------+---------------+------------------+--------+\n" \
        "|                               1: Test Dashboard                               |\n" \
        "+-----+------------------+----------+---------------+------------------+--------+\n" \
        "| Id  | Datasource name  | Database | Database name | Database backend | Schema |\n" \
        "+-----+------------------+----------+---------------+------------------+--------+\n" \
        "| 101 | Acme Forcasts    | 1        | DB1           | postgres         | acme   |\n" \
        "| 102 | video_game_sales | 2        | examples      | postgres         | public |\n" \
        "+-----+------------------+----------+---------------+------------------+--------+"
      )
    end
  end
end

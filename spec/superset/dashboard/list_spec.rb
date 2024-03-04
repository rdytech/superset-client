require 'spec_helper'

RSpec.describe Superset::Dashboard::List do
  subject { described_class.new }
  let(:superset_host) { 'https://test.superset.host.com' }
  let(:result) do
    [
      {
        id: 36,
        dashboard_title: 'Test Embedded 2',
        status: 'published',
        url: '/superset/dashboard/36/'
      },
      {
        id: 15,
        dashboard_title: 'Test Embedded 1',
        status: 'published',
        url: '/superset/dashboard/15/'
      }
    ]
  end

  before do
    allow(subject).to receive(:result).and_return(result)
    allow(subject).to receive(:superset_host).and_return(superset_host)
    allow(subject).to receive(:retrieve_schemas).with(36).and_return( { schemas: ['acme'] } )
    allow(subject).to receive(:retrieve_schemas).with(15).and_return( { schemas: ['coyote'] } )
    allow(subject).to receive(:retrieve_embedded_details).with(36).and_return(
      { allowed_embedded_domains: ["https://test-acme.io/"], uuid: 'some-uuid-for-36' } )
    allow(subject).to receive(:retrieve_embedded_details).with(15).and_return(
      { allowed_embedded_domains: [], uuid: 'some-uuid-for-15' } )
  end

  describe '#all' do
    it 'returns an array of OpenStruct objects with the correct attributes' do
      dashboards = subject.all
      expect(dashboards).to be_an(Array)
      expect(dashboards.length).to eq(result.length)
      expect(dashboards.first).to be_an(OpenStruct)
      expect(dashboards.first.id).to eq(result.first[:id])
      expect(dashboards.first.dashboard_title).to eq(result.first[:dashboard_title])
      expect(dashboards.first.status).to eq(result.first[:status])
      expect(dashboards.first.url).to eq(result.first[:url])
# coming in next commit
#      expect(dashboards.first.schemas).to eq(['acme'])
#      expect(dashboards.first.allowed_embedded_domains).to eq(['https://test-acme.io/'])
#      expect(dashboards.first.uuid).to eq('some-uuid-for-36')
    end
  end

  describe '#list' do
    specify do
      expect(subject.table.to_s).to eq(
        "+----+-----------------+-----------+-------------------------------------------------------+\n" \
        "|                                Superset::Dashboard::List                                 |\n" \
        "+----+-----------------+-----------+-------------------------------------------------------+\n" \
        "| Id | Dashboard title | Status    | Url                                                   |\n" \
        "+----+-----------------+-----------+-------------------------------------------------------+\n" \
        "| 36 | Test Embedded 2 | published | https://test.superset.host.com/superset/dashboard/36/ |\n" \
        "| 15 | Test Embedded 1 | published | https://test.superset.host.com/superset/dashboard/15/ |\n" \
        "+----+-----------------+-----------+-------------------------------------------------------+"
      )
    end
  end
end

require 'spec_helper'

RSpec.describe Superset::Dashboard::Charts::List do
  subject { described_class.new(id) }
  let(:id) { 1 }
  let(:superset_host) { 'https://test.superset.host.com' }
  let(:result) do
    [
      {
        id: 248,
        slice_name: "Chart 1",
        form_data: 
        {
          dashboards: [28],
          datasource: "114__table",
        }
      },
      {
        id: 249,
        slice_name: "Chart 2",
        form_data: 
        {
          dashboards: [28],
          datasource: "114__table",
        }
      }
    ]
  end

  before do
    allow(subject).to receive(:result).and_return(result)
    allow(subject).to receive(:superset_host).and_return(superset_host)
  end

  describe '#rows' do
    specify do
      expect(subject.rows).to match_array(
        [
          [248, "Chart 1", "114__table"],
          [249, "Chart 2", "114__table"]
        ]
      )
    end
  end

  describe '#chart_ids' do
    specify do
      expect(subject.chart_ids).to match_array([248, 249])
    end
  end
end

require 'spec_helper'

RSpec.describe Superset::Tag::List do
  subject { described_class.new }
  let(:superset_host) { 'https://test.superset.host.com' }
  let(:result) do
    [
      {
        "description"=>'Reference for Embedded Dashboards',
        "id"=>1,
        "name"=>"embedded",
      },
      {
        "description"=>'Reference for Template Dashboards',
        "id"=>2,
        "name"=>"template",

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
          ["1", "embedded", "Reference for Embedded Dashboards"],
          ["2", "template", "Reference for Template Dashboards"]
        ]
      )
    end
  end
end

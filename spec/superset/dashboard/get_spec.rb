require 'spec_helper'

RSpec.describe Superset::Dashboard::Get do
  subject { described_class.new(dashboard_id) }
  let(:dashboard_id) { 1 }
  let(:dashboard_title) { 'Test Dashboard' }
  let(:dashboard_charts) { ['Chart 1', 'Chart 2'] }
  let(:dashboard_result) do
    {
      'id' => dashboard_id,
      'dashboard_title' => dashboard_title,
      'published' => true,
      'changed_on_delta_humanized' => '1 day ago',
      'charts' => dashboard_charts,
      'json_metadata' => { 'key1' => 'value1' }.to_json,
      'position_json' => { 'key2' => 'value2' }.to_json,
      'url' => '',

    }
  end

  before do
    allow(subject).to receive(:result).and_return(dashboard_result)
    allow(subject).to receive(:superset_host).and_return('http://superset-host.com')  
  end

  describe '.call' do
    it 'calls the list method with the given id' do
      expect_any_instance_of(Superset::Dashboard::Get).to receive(:list)
      described_class.call(dashboard_id)
    end
  end

  describe '#title' do
    it 'returns the id and title of the dashboard' do
      expect(subject.title).to eq('Test Dashboard')
    end
  end

  describe '#json_metadata' do
    it 'returns the parsed json_metadata' do
      expect(subject.json_metadata).to eq(JSON.parse(dashboard_result['json_metadata']))
    end
  end

  describe '#positions' do
    it 'returns the parsed positions' do
      expect(subject.positions).to eq(JSON.parse(dashboard_result['position_json']))
    end
  end

  describe '#url' do
    it 'returns the url of the dashboard' do
      expect(subject.url).to eq("http://superset-host.com#{dashboard_result['url']}")
    end
  end 
end

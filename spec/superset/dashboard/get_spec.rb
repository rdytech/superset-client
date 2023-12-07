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
      'charts' => dashboard_charts
    }
  end

  before do
    allow(subject).to receive(:result).and_return(dashboard_result)
  end

  describe '.call' do
    it 'calls the list method with the given id' do
      expect_any_instance_of(Superset::Dashboard::Get).to receive(:list)
      described_class.call(dashboard_id)
    end
  end

  describe '#title' do
    it 'returns the id and title of the dashboard' do
      expect(subject.title).to eq('1: Test Dashboard')
    end
  end
end

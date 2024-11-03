require 'spec_helper'

RSpec.describe Superset::Request, type: :service do
  subject { described_class.new }
  let(:client) { subject.client }
  let(:route) { '/test' }
  let(:response) { { 'result' => { 'data': 'values' } } }
  let(:host) { 'https://some-host.com' }

  before do
    allow_any_instance_of(Superset::Request).to receive(:route).and_return(route)
    allow_any_instance_of(Superset::Client).to receive(:get).with(route).and_return(response)
    allow(ENV).to receive(:[]).with('SUPERSET_HOST').and_return(host)
    allow(ENV).to receive(:[]).with('SUPERSET_API_USERNAME').and_return(host)
    allow(ENV).to receive(:[]).with('SUPERSET_API_PASSWORD').and_return(host)
  end

  describe '.call' do
    it 'returns the response' do
      expect(described_class.call).to eq(response)
    end
  end

  describe '#response' do
    it 'returns the response' do
      expect(subject.response).to eq(response)
    end
  end

  describe '#result' do
    it 'returns the responses result' do
      expect(subject.result).to eq(response['result'])
    end
  end

  describe '#superset_host' do
    specify 'returns the client preference' do
      expect(subject.superset_host).to eq(host)
    end
  end

  describe '#query_params' do
    it 'returns the default query params' do
      expect(subject.send(:query_params)).to eq("page:0,page_size:100,order_column:changed_on,order_direction:desc")
    end
  end
end

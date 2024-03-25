require 'spec_helper'

RSpec.describe Superset::Dashboard::Embedded::Put, type: :service do
  subject { described_class.new(dashboard_id: dashboard_id, allowed_domains: allowed_domains) }
  let(:dashboard_id) { 1 }

  describe 'with a dashboard that has embedded settings, ie has a result' do
    let(:allowed_domains) { ['http://test-domain.io/'] }
    let(:uuid) { '631bxxxx-xxxx-xxxx-xxxx-xxxxxxxxx247' }
    let(:response) do
      {
        'result' =>
          {
            "allowed_domains" => allowed_domains,
            "changed_by"=>{"first_name"=>"Jay", "id"=>9, "last_name"=>"Bee", "username"=>"4bf....3f5"},
            "changed_on"      => "2023-10-30T03:06:51.437527",
            "dashboard_id"    => "1",
            "uuid"            => uuid
          }.with_indifferent_access
      }.with_indifferent_access
    end

    context 'with params' do
      before { allow(subject).to receive(:response).and_return(response) }

      context 'that are valid' do
        it 'returns uuid' do
          expect(subject.uuid).to eq(uuid)
        end
      end
    end

    context 'where allowed_domains is not an array' do
      let(:allowed_domains) { 'http://test-domain.io/' }

      before { allow(subject).to receive(:response).and_call_original }

      it 'raises error' do
        expect { subject.response }.to raise_error(Superset::Request::InvalidParameterError, "allowed_domains array is required")
      end
    end

    context 'where allowed_domains is nil' do
      let(:allowed_domains) { nil }

      before { allow(subject).to receive(:response).and_call_original }

      it 'raises error' do
        expect { subject.response }.to raise_error(Superset::Request::InvalidParameterError, "allowed_domains array is required")
      end
    end

    context 'where dashboard_id is nil' do
      let(:dashboard_id) { nil }

      before { allow(subject).to receive(:response).and_call_original }

      it 'raises error' do
        expect { subject.response }.to raise_error(Superset::Request::InvalidParameterError, "dashboard_id integer is required")
      end
    end

    context 'where dashboard_id is not an int' do
      let(:dashboard_id) { 'asdf' }

      before { allow(subject).to receive(:response).and_call_original }

      it 'raises error' do
        expect { subject.response }.to raise_error(Superset::Request::InvalidParameterError, "dashboard_id integer is required")
      end
    end
  end
end

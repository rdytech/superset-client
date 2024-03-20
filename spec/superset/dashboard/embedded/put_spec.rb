require 'spec_helper'

RSpec.describe Superset::Dashboard::Embedded::Put, type: :service do
  subject { described_class.new(dashboard_id: dashboard_id, embedded_domain: allowed_domain) }
  let(:dashboard_id) { 1 }

  describe 'with a dashboard that has embedded settings, ie has a result' do
    let(:allowed_domain) { ['http://test-domain.io/'] }
    let(:uuid) { '631bxxxx-xxxx-xxxx-xxxx-xxxxxxxxx247' }
    let(:response) do
      {
        'result' =>
          {
            "allowed_domains" => allowed_domain,
            "changed_by"=>{"first_name"=>"Jay", "id"=>9, "last_name"=>"Bee", "username"=>"4bf....3f5"},
            "changed_on"      => "2023-10-30T03:06:51.437527",
            "dashboard_id"    => "1",
            "uuid"            => uuid
          }.with_indifferent_access
      }.with_indifferent_access
    end

    before do
      allow(subject).to receive(:response).and_return(response)
    end

    describe '#uuid' do
      it 'returns uuid' do
        expect(subject.uuid).to eq(uuid)
      end
    end
  end
end

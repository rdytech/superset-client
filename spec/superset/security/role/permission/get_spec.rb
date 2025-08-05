require 'spec_helper'

RSpec.describe Superset::Security::Role::Permission::Get do
  subject { described_class.new(role_id) }
  let(:role_id) { 99 }
  let(:response) do
    {
      "result"=>[
        {"id"=>455, "permission_name"=>"schema_access", "view_menu_name"=>"[DB1].[acme]"},
        {"id"=>355, "permission_name"=>"schema_access", "view_menu_name"=>"[DB1].[coyote]"}
      ]
    }.with_indifferent_access
  end

  before do
    allow(subject).to receive(:response).and_return(response)
  end

 describe '#result' do
    it 'returns the response result' do
      expect(subject.result).to eq(response['result'])
    end
  end

  describe '#list' do
    before do
      allow(subject).to receive(:title).and_return("9: DB1 Acme vs Coyote")
    end

    specify do
      expect(subject.table.to_s).to eq(
        "+----------------------------------------+\n" \
        "|         9: DB1 Acme vs Coyote          |\n" \
        "+-----+-----------------+----------------+\n" \
        "| Id  | Permission name | View menu name |\n" \
        "+-----+-----------------+----------------+\n" \
        "| 455 | schema_access   | [DB1].[acme]   |\n" \
        "| 355 | schema_access   | [DB1].[coyote] |\n" \
        "+-----+-----------------+----------------+"
      )
    end
  end
end

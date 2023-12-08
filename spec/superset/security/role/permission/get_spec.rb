require 'spec_helper'

RSpec.describe Superset::Security::Role::Permission::Get do
  subject { described_class.new(role_id) }
  let(:role_id) { 99 }
  let(:response) do
    {
      "result"=>[
        {"id"=>181, "permission_name"=>"menu_access", "view_menu_name"=>"Dashboards"},
        {"id"=>180, "permission_name"=>"menu_access", "view_menu_name"=>"Datasets"},
        {"id"=>455, "permission_name"=>"schema_access", "view_menu_name"=>"[Jobready-Staging].[jobready_stage]"},
        {"id"=>355, "permission_name"=>"schema_access", "view_menu_name"=>"[Jobready-Staging].[jobready_stage_new]"}
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
      allow(subject).to receive(:title).and_return("9: JobReady Staging Tenant only (non TPES)")
    end

    specify do
      expect(subject.table.to_s).to eq(
        "+-----+-----------------+-----------------------------------------+\n" \
        "|           9: JobReady Staging Tenant only (non TPES)            |\n" \
        "+-----+-----------------+-----------------------------------------+\n" \
        "| Id  | Permission name | View menu name                          |\n" \
        "+-----+-----------------+-----------------------------------------+\n" \
        "| 181 | menu_access     | Dashboards                              |\n" \
        "| 180 | menu_access     | Datasets                                |\n" \
        "| 455 | schema_access   | [Jobready-Staging].[jobready_stage]     |\n" \
        "| 355 | schema_access   | [Jobready-Staging].[jobready_stage_new] |\n" \
        "+-----+-----------------+-----------------------------------------+"
      )
    end
  end
end

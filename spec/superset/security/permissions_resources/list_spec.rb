require 'spec_helper'

RSpec.describe Superset::Security::PermissionsResources::List do
  subject { described_class.new }
  let(:response) do
    {
      "count"=>720,
      "description_columns"=>{},
      "ids"=>[1, 2, 3, 4, 5],
      "label_columns"=>{"id"=>"Id", "permission.name"=>"Permission Name", "view_menu.name"=>"View Menu Name"},
      "list_columns"=>["id", "permission.name", "view_menu.name"],
      "list_title"=>"List Permission View",
      "order_columns"=>["id", "permission.name", "view_menu.name"],
      "result"=>
       [{"id"=>1, "permission"=>{"name"=>"can_read"}, "view_menu"=>{"name"=>"SavedQuery"}},
        {"id"=>2, "permission"=>{"name"=>"can_write"}, "view_menu"=>{"name"=>"SavedQuery"}},
        {"id"=>3, "permission"=>{"name"=>"can_read"}, "view_menu"=>{"name"=>"CssTemplate"}},
        {"id"=>4, "permission"=>{"name"=>"can_write"}, "view_menu"=>{"name"=>"CssTemplate"}},
        {"id"=>5, "permission"=>{"name"=>"can_read"}, "view_menu"=>{"name"=>"ReportSchedule"}}]
    }.with_indifferent_access
  end

  before do
    allow(subject).to receive(:response).and_return(response)
  end

  describe '#list' do
    specify do
      expect(subject.table.to_s).to eq(
        "+---------------------------------------------------------+\n" \
        "|     Superset::Security::PermissionsResources::List      |\n" \
        "+----+-----------------------+----------------------------+\n" \
        "| Id | Permission            | View menu                  |\n" \
        "+----+-----------------------+----------------------------+\n" \
        "| 1  | {\"name\"=>\"can_read\"}  | {\"name\"=>\"SavedQuery\"}     |\n" \
        "| 2  | {\"name\"=>\"can_write\"} | {\"name\"=>\"SavedQuery\"}     |\n" \
        "| 3  | {\"name\"=>\"can_read\"}  | {\"name\"=>\"CssTemplate\"}    |\n" \
        "| 4  | {\"name\"=>\"can_write\"} | {\"name\"=>\"CssTemplate\"}    |\n" \
        "| 5  | {\"name\"=>\"can_read\"}  | {\"name\"=>\"ReportSchedule\"} |\n" \
        "+----+-----------------------+----------------------------+"
      )
    end
  end
end

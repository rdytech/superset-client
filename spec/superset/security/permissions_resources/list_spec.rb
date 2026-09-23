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

  describe '#table' do
    specify 'titles the table with the class name' do
      expect(subject.table.title).to eq('Superset::Security::PermissionsResources::List')
    end

    specify 'humanizes list_attributes into headings' do
      expect(subject.table.headings.first.cells.map(&:value)).to eq(%w[Id Permission View\ menu])
    end

    specify 'stringifies each list_attribute into a row' do
      expect(subject.rows).to eq(
        response[:result].map do |permission|
          [permission[:id].to_s, permission[:permission].to_s, permission[:view_menu].to_s]
        end
      )
    end

    specify 'renders' do
      expect { subject.table.to_s }.not_to raise_error
    end
  end
end

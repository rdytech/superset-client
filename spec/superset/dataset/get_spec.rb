require 'spec_helper'

RSpec.describe Superset::Dataset::Get do
  subject { described_class.new(id) }
  let(:id) { 1 }
  let(:result) do
    {
      "always_filter_main_dttm"=>false,
      "cache_timeout"=>nil,
      "changed_by"=>{"first_name"=>"Jonathon", "last_name"=>"B"},
      "changed_on"=>"2023-09-15T03:27:49.854983",
      "changed_on_humanized"=>"5 months ago",
      "name"=>"public.Birth Names Counts",
      "owners"=>[{"first_name"=>"Jonathon", "id"=>9, "last_name"=>"B"}],
      "schema"=>"public",
      "select_star"=>"SELECT *\nFROM public.\"Birth Names Counts\"\nLIMIT 100",
      "sql"=>"-- select * from birth_names;\n\n\nSELECT \n  name,\n  count(*)\nFROM \n  birth_names\nGroup by name\norder by name asc;",
      "table_name"=>"Birth Names Counts",
      "database"=>{"backend"=>"postgresql", "database_name"=>"examples", "id"=>1},
      "uid"=>"83__table",
      "url"=>"/tablemodelview/edit/83"
    }
  end

  before do
    allow(subject).to receive(:result).and_return(result)
  end

  describe '.call' do
    specify do
      expect_any_instance_of(Superset::Dataset::Get).to receive(:list)
      described_class.call(id)
    end
  end

  describe '#rows' do
    specify do
      expect(subject.rows).to eq [["Birth Names Counts", "public", "examples", 1]]
    end
  end

  describe '#to_h' do
    specify do
      expect(subject.to_h).to eq({ title: "Birth Names Counts", schema: "public", database_name: "examples", database_id: 1 })
    end
  end
end

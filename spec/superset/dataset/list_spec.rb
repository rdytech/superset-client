require 'spec_helper'

RSpec.describe Superset::Dataset::List do
  subject { described_class.new }
  let(:superset_host) { 'https://test.superset.host.com' }
  let(:result) do
    [{
      "changed_by"=>nil,
      "changed_by_name"=>"bob",
      "changed_on_delta_humanized"=>"8 months ago",
      "changed_on_utc"=>"2023-06-16T00:39:50.058181+0000",
      "database"=>{"database_name"=>"examples", "id"=>1},
      "datasource_type"=>"table",
      "default_endpoint"=>nil,
      "description"=>nil,
      "explore_url"=>"/explore/?datasource_type=table&datasource_id=2",
      "extra"=>nil,
      "id"=>2,
      "kind"=>"physical",
      "owners"=>[],
      "schema"=>"public",
      "sql"=>nil,
      "table_name"=>"birth_names"
    },
    {
      "changed_by"=>nil,
      "changed_by_name"=>"bob",
      "changed_on_delta_humanized"=>"8 months ago",
      "changed_on_utc"=>"2023-06-16T00:39:50.058181+0000",
      "database"=>{"database_name"=>"examples", "id"=>1},
      "datasource_type"=>"table",
      "default_endpoint"=>nil,
      "description"=>nil,
      "explore_url"=>"/explore/?datasource_type=table&datasource_id=3",
      "extra"=>nil,
      "id"=>3,
      "kind"=>"physical",
      "owners"=>[],
      "schema"=>"public",
      "sql"=>nil,
      "table_name"=>"birth_days"
    }
  ]
  end

  before do
    allow(subject).to receive(:result).and_return(result)
    allow(subject).to receive(:superset_host).and_return(superset_host)
    allow(subject).to receive(:response).and_return( { 'count': 1 } )
  end

  describe '#rows' do
    #before { stub_const("Superset::Request::PAGE_SIZE", "3") }

    specify do
      expect(subject.rows).to eq(
        [
          ["2", "birth_names", "public", "bob"],
          ["3", "birth_days", "public", "bob"]
        ]
      )
    end
  end

  describe '#query_params' do
    specify 'with defaults' do
      expect(subject.query_params).to eq("page:0,page_size:100")
    end

    context 'with title_contains filters' do
      subject { described_class.new(title_contains: 'birth') }

      specify do
        expect(subject.query_params).to eq("filters:!((col:table_name,opr:ct,value:birth)),page:0,page_size:100")
      end
    end

    context 'with title_contains filters' do
      subject { described_class.new(title_equals: 'birth_days') }

      specify do
        expect(subject.query_params).to eq("filters:!((col:table_name,opr:eq,value:birth_days)),page:0,page_size:100")
      end
    end

  end
end

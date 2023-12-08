require 'spec_helper'

RSpec.describe Superset::Security::Role::List do
  subject { described_class.new }
  let(:response) do
    {
      "count"=>3,
      "description_columns"=>{},
      "ids"=>[1, 2, 3],
      "label_columns"=>{"id"=>"Id", "name"=>"Name"},
      "list_columns"=>["id", "name"],
      "list_title"=>"List Role",
      "order_columns"=>["id", "name"],
      "result"=> [
         {"id"=>1, "name"=>"Role1"},
         {"id"=>2, "name"=>"Role2"},
         {"id"=>3, "name"=>"Role3"}
       ]
    }.with_indifferent_access
  end

  before do
    allow(subject).to receive(:response).and_return(response)
    allow(subject).to receive(:superset_host).and_return('some-host.com')
  end

  describe '#list' do
    specify do
      expect(subject.table.to_s).to eq(
        "+----------------+----------------+\n" \
        "| 3 Roles for Host: some-host.com |\n" \
        "+----------------+----------------+\n" \
        "| Id             | Name           |\n" \
        "+----------------+----------------+\n" \
        "| 1              | Role1          |\n" \
        "| 2              | Role2          |\n" \
        "| 3              | Role3          |\n" \
        "+----------------+----------------+"
      )
    end
  end
end

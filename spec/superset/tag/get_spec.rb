require 'spec_helper'

RSpec.describe Superset::Tag::Get do
  subject { described_class.new(tag_id) }
  let(:tag_id) { 1 }
  let(:result) do
    [{
      "changed_by"=>{"first_name"=>"Jon", "last_name"=>"B"},
      "changed_on_delta_humanized"=>"10 minutes ago",
      "created_by"=>
        {
          "active"=>true,
          "changed_on"=>"2024-03-12T05:24:26.594934",
          "created_on"=>"2023-06-21T12:29:02.452271",
          "email"=>"jonb@gm.com",
          "first_name"=>"Jon",
          "id"=>9
        },
      "created_on_delta_humanized"=>"4 months ago",
      "description"=>"Used to reference dashboards that are embedded in an external application",
      "id"=>2,
      "name"=>"embedded",
      "type"=>1
    }]
  end

  before do
    allow(subject).to receive(:result).and_return(result)
  end

  describe '#rows' do
    specify do
      expect(subject.rows).to match_array([["2", "embedded", "1", "Used to reference dashboards that are embedded in an external application"]])
    end
  end 
end

require 'spec_helper'

RSpec.describe Superset::Chart::List do
  subject { described_class.new }
  let(:result) do
    [{
      "cache_timeout"=>nil,
      "certification_details"=>nil,
      "certified_by"=>nil,
      "changed_by"=>{"first_name"=>"James", "last_name"=>"H"},
      "changed_by_name"=>"James H",
      "changed_on_delta_humanized"=>"7 days ago",
      "changed_on_dttm"=>1708640888789.709,
      "changed_on_utc"=>"2024-02-22T22:28:08.789709+0000",
      "created_by"=>{"first_name"=>"Jonathon", "id"=>9, "last_name"=>"B"},
      "created_by_name"=>"Jonathon B",
      "created_on_delta_humanized"=>"10 days ago",
      "dashboards"=>[],
      "datasource_id"=>119,
      "datasource_name_text"=>"schema_one.Staging Placements",
      "datasource_type"=>"table",
      "datasource_url"=>"/explore/?datasource_type=table&datasource_id=119",
      "description"=>nil,
      "description_markeddown"=>"",
      "edit_url"=>"/chart/edit/54672",
      "form_data"=> {},
      "id"=>54672,
      "is_managed_externally"=>false,
      "last_saved_at"=>nil,
      "last_saved_by"=>nil,
      "owners"=>[{"first_name"=>"Jonathon", "id"=>9, "last_name"=>"B"}],
      "params"=> {},
      "slice_name"=>"Top 10 Placement Managed by",
      "slice_url"=>"/explore/?slice_id=54672&form_data=%7B%22slice_id%22%3A%2054672%7D",
      "table"=>{"default_endpoint"=>nil, "table_name"=>"Staging Placements"},
      "tags"=>[{"id"=>1, "name"=>"owner:9", "type"=>3}, {"id"=>28, "name"=>"type:chart", "type"=>2}],
      "thumbnail_url"=>"/api/v1/chart/54672/thumbnail/acb632f4bfb16c9d9ab4d8ccfb262038/",
      "url"=>"/explore/?slice_id=54672",
      "viz_type"=>"table"
    },
    {
      "cache_timeout"=>nil,
      "certification_details"=>nil,
      "certified_by"=>nil,
      "changed_by"=>{"first_name"=>"Jonathon", "last_name"=>"B"},
      "changed_by_name"=>"Jonathon B",
      "changed_on_delta_humanized"=>"8 days ago",
      "changed_on_dttm"=>1708485919444.681,
      "changed_on_utc"=>"2024-02-21T03:25:19.444681+0000",
      "created_by"=>{"first_name"=>"Jonathon", "id"=>9, "last_name"=>"B"},
      "created_by_name"=>"Jonathon B",
      "created_on_delta_humanized"=>"8 days ago",
      "dashboards"=>[{"dashboard_title"=>"Embedded Test 1 (COPY)", "id"=>118}],
      "datasource_id"=>9,
      "datasource_name_text"=>"public.video_game_sales",
      "datasource_type"=>"table",
      "datasource_url"=>"/explore/?datasource_type=table&datasource_id=9",
      "description"=>nil,
      "description_markeddown"=>"",
      "edit_url"=>"/chart/edit/54689",
      "form_data"=> {},
      "id"=>54689,
      "is_managed_externally"=>false,
      "last_saved_at"=>nil,
      "last_saved_by"=>nil,
      "owners"=>[{"first_name"=>"Jonathon", "id"=>9, "last_name"=>"B"}],
      "params"=>{}, 
      "slice_name"=>"Bryan's Test A",
      "slice_url"=>"/explore/?slice_id=54689&form_data=%7B%22slice_id%22%3A%2054689%7D",
      "table"=>{"default_endpoint"=>nil, "table_name"=>"video_game_sales"},
      "tags"=>[{"id"=>28, "name"=>"type:chart", "type"=>2}, {"id"=>1, "name"=>"owner:9", "type"=>3}],
      "thumbnail_url"=>"/api/v1/chart/54689/thumbnail/c8013da344b16e018d061c883bf3900b/",
      "url"=>"/explore/?slice_id=54689",
      "viz_type"=>"dist_bar"
    }]
  end

  before do
    allow(subject).to receive(:result).and_return(result)
    #allow(subject).to receive(:superset_host).and_return(superset_host)
    #allow(subject).to receive(:response).and_return( { 'count': 2 } )
  end

  describe '#rows' do
    specify do
      expect(subject.rows).to eq(
        [
          ["54672", "Top 10 Placement Managed by", "119", "schema_one.Staging Placements", "Jonathon B"], 
          ["54689", "Bryan's Test A", "9", "public.video_game_sales", "Jonathon B"]
        ]
      )
    end
  end

  describe '#rows_with_dashboards' do
    specify do
      expect(subject.rows_with_dashboards).to eq(
        [
          ["54672", "Top 10 Placement Managed by", "[]"],
          ["54689", "Bryan's Test A", "[{\"dashboard_title\"=>\"Embedded Test 1 (COPY)\", \"id\"=>118}]"]
        ]
      )
    end
  end


  describe '#query_params' do
    specify 'with defaults' do
      expect(subject.query_params).to eq("page:0,page_size:100")
    end

    context 'with name_contains filters' do
      subject { described_class.new(name_contains: 'birth') }

      specify do
        expect(subject.query_params).to eq("filters:!((col:slice_name,opr:ct,value:'birth')),page:0,page_size:100")
      end
    end

    context 'with multiple filter set' do
      subject { described_class.new(name_contains: 'birth', dashboard_id_eq: 3) }

      specify do
        expect(subject.query_params).to eq(
          "filters:!(" \
          "(col:slice_name,opr:ct,value:'birth')," \
          "(col:dashboards,opr:rel_m_m,value:3)" \
          "),page:0,page_size:100")
      end
    end
  end
end

require 'spec_helper'

RSpec.describe Superset::Chart::UpdateDataset do
  subject { described_class.new(
              chart_id:  chart_id,
              target_dataset_id: target_dataset_id) }

  let(:chart_id) { 226 }
  let(:target_dataset_id) { 242 }
  let(:chart) do
    {
      "cache_timeout"=>nil,
      "certification_details"=>nil,
      "certified_by"=>nil,
      "changed_on_delta_humanized"=>"14 days ago",
      "dashboards"=>[],
      "description"=>nil,
      "id"=>226,
      "is_managed_externally"=>false,
      "owners"=>[{"first_name"=>"Jonathon", "id"=>9, "last_name"=>"Batson"}],
      "query_context"=>nil,
      "slice_name"=>"JRStg DoB per Year",
      "tags"=>[{"id"=>1, "name"=>"owner:9", "type"=>3}, {"id"=>28, "name"=>"type:chart", "type"=>2}],
      "thumbnail_url"=>"/api/v1/chart/54507/thumbnail/1595a10937091faff0aed5df628a1292/",
      "url"=>"/explore/?slice_id=54507",
      "viz_type"=>"echarts_timeseries_bar",
      "params"=>"{\"datasource\":\"243__table\",\"viz_type\":\"table\",\"slice_id\":54738,\"query_mode\":\"raw\",\"groupby\":[],\"time_grain_sqla\":\"P1D\",\"temporal_columns_lookup\":{\"started_on\":true,\"job_ended_on\":true,\"centrelink_outcome_started_on\":true},\"all_columns\":[\"started_on\",\"job_ended_on\",\"job_title\",\"company_name\"],\"percent_metrics\":[],\"adhoc_filters\":[{\"clause\":\"WHERE\",\"comparator\":\"No filter\",\"expressionType\":\"SIMPLE\",\"operator\":\"TEMPORAL_RANGE\",\"subject\":\"started_on\"}],\"order_by_cols\":[],\"row_limit\":50,\"server_page_length\":10,\"order_desc\":true,\"table_timestamp_format\":\"smart_date\",\"show_cell_bars\":true,\"color_pn\":true,\"extra_form_data\":{},\"dashboards\":[122]}",
      "query_context"=>"{\"datasource\":{\"id\":243,\"type\":\"table\"},\"force\":false,\"queries\":[{\"filters\":[{\"col\":\"started_on\",\"op\":\"TEMPORAL_RANGE\",\"val\":\"No filter\"}],\"extras\":{\"time_grain_sqla\":\"P1D\",\"having\":\"\",\"where\":\"\"},\"applied_time_extras\":{},\"columns\":[\"started_on\",\"job_ended_on\",\"job_title\",\"company_name\"],\"orderby\":[],\"annotation_layers\":[],\"row_limit\":50,\"series_limit\":0,\"order_desc\":true,\"url_params\":{},\"custom_params\":{},\"custom_form_data\":{},\"post_processing\":[]}],\"form_data\":{\"datasource\":\"243__table\",\"viz_type\":\"table\",\"slice_id\":54738,\"query_mode\":\"raw\",\"groupby\":[],\"time_grain_sqla\":\"P1D\",\"temporal_columns_lookup\":{\"started_on\":true,\"job_ended_on\":true,\"centrelink_outcome_started_on\":true},\"all_columns\":[\"started_on\",\"job_ended_on\",\"job_title\",\"company_name\"],\"percent_metrics\":[],\"adhoc_filters\":[{\"clause\":\"WHERE\",\"comparator\":\"No filter\",\"expressionType\":\"SIMPLE\",\"operator\":\"TEMPORAL_RANGE\",\"subject\":\"started_on\"}],\"order_by_cols\":[],\"row_limit\":50,\"server_page_length\":10,\"order_desc\":true,\"table_timestamp_format\":\"smart_date\",\"show_cell_bars\":true,\"color_pn\":true,\"extra_form_data\":{},\"dashboards\":[122],\"force\":false,\"result_format\":\"json\",\"result_type\":\"full\",\"include_time\":false},\"result_format\":\"json\",\"result_type\":\"full\"}",
    }
  end

  let(:response) do
    {
      "id"=>226,
      "result"=>
       {
          "datasource_id"=>242,
          "datasource_type"=>"table",
          "owners"=>[22, 104],
          "params"=>
          "{\"datasource\":\"242__table\",\"viz_type\":\"table\",\"slice_id\":54738,\"query_mode\":\"raw\",\"groupby\":[],\"time_grain_sqla\":\"P1D\",\"temporal_columns_lookup\":{\"started_on\":true,\"job_ended_on\":true,\"centrelink_outcome_started_on\":true},\"all_columns\":[\"started_on\",\"job_ended_on\",\"job_title\",\"company_name\"],\"percent_metrics\":[],\"adhoc_filters\":[{\"clause\":\"WHERE\",\"comparator\":\"No filter\",\"expressionType\":\"SIMPLE\",\"operator\":\"TEMPORAL_RANGE\",\"subject\":\"started_on\"}],\"order_by_cols\":[],\"row_limit\":50,\"server_page_length\":10,\"order_desc\":true,\"table_timestamp_format\":\"smart_date\",\"show_cell_bars\":true,\"color_pn\":true,\"extra_form_data\":{},\"dashboards\":[122]}",
          "query_context"=>
          "{\"datasource\":{\"id\":242,\"type\":\"table\"},\"force\":false,\"queries\":[{\"filters\":[{\"col\":\"started_on\",\"op\":\"TEMPORAL_RANGE\",\"val\":\"No filter\"}],\"extras\":{\"time_grain_sqla\":\"P1D\",\"having\":\"\",\"where\":\"\"},\"applied_time_extras\":{},\"columns\":[\"started_on\",\"job_ended_on\",\"job_title\",\"company_name\"],\"orderby\":[],\"annotation_layers\":[],\"row_limit\":50,\"series_limit\":0,\"order_desc\":true,\"url_params\":{},\"custom_params\":{},\"custom_form_data\":{},\"post_processing\":[]}],\"form_data\":{\"datasource\":\"242__table\",\"viz_type\":\"table\",\"slice_id\":54738,\"query_mode\":\"raw\",\"groupby\":[],\"time_grain_sqla\":\"P1D\",\"temporal_columns_lookup\":{\"started_on\":true,\"job_ended_on\":true,\"centrelink_outcome_started_on\":true},\"all_columns\":[\"started_on\",\"job_ended_on\",\"job_title\",\"company_name\"],\"percent_metrics\":[],\"adhoc_filters\":[{\"clause\":\"WHERE\",\"comparator\":\"No filter\",\"expressionType\":\"SIMPLE\",\"operator\":\"TEMPORAL_RANGE\",\"subject\":\"started_on\"}],\"order_by_cols\":[],\"row_limit\":50,\"server_page_length\":10,\"order_desc\":true,\"table_timestamp_format\":\"smart_date\",\"show_cell_bars\":true,\"color_pn\":true,\"extra_form_data\":{},\"dashboards\":[122],\"force\":false,\"result_format\":\"json\",\"result_type\":\"full\",\"include_time\":false},\"result_format\":\"json\",\"result_type\":\"full\"}",
          "query_context_generation"=>true
        }
      }
  end


  before do
    allow(subject).to receive(:response).and_return(response)
    allow(subject).to receive(:chart).and_return(chart)
  end

  describe '#perform' do
    context 'with valid params' do
      specify do
        expect(subject.perform).to eq "Successfully updated chart 226 to the target dataset 242"
      end
    end

    context 'with invalid params' do
      context 'chart_id is empty' do
        let(:chart_id) { nil }
        
        specify do
          expect { subject.perform }.to raise_error(RuntimeError, "Error: chart_id integer is required")
        end
      end

      context 'target_dataset_id is empty' do
        let(:target_dataset_id) { nil }
        
        specify do
          expect { subject.perform }.to raise_error(RuntimeError, "Error: target_dataset_id integer is required")
        end
      end 
    end
  end

  describe '#params_updated' do
    specify 'set the new datasource_id correctly' do
      expect(subject.params_updated[:datasource_id]).to eq(target_dataset_id)
    end
  end
end

require 'superset/services/dashboard_loader'

RSpec.describe Superset::Services::DashboardLoader do
  let(:loader) { described_class.new(dashboard_export_zip: dashboard_export_zip) }
  let(:dashboard_export_zip) { 'spec/fixtures/dashboard_18_export_20240322.zip' }

  describe '#perform' do
    before { loader.perform }

    it 'populates dashboard_config with each objects filename and content' do
      expect(loader.dashboard_config.keys).to contain_exactly(:dashboards, :datasets, :databases, :charts, :metadata, :tmp_uniq_dashboard_path)
      (loader.dashboard_config.keys - [:tmp_uniq_dashboard_path]).each do |object|
        expect(loader.dashboard_config[object]).to all(include(:filename, :content))
      end
    end

    it 'loads the metadata yaml file' do
      metadata = loader.dashboard_config[:metadata].first
      expect(File.basename(metadata[:filename])).to eq('metadata.yaml')
      expect(metadata[:content].keys).to contain_exactly(:version, :type, :timestamp)
    end

    it 'loads the dashboards yaml' do
      dashboards = loader.dashboard_config[:dashboards]
      expect(dashboards.size).to eq(1)
      expect(File.basename(dashboards.first[:filename])).to eq('Birth_Names_18.yaml')
      expect(dashboards.first[:content].keys).to match_array(
        [ :dashboard_title, :description, :css, :slug, :certified_by, :certification_details, :published,
          :uuid, :position, :metadata, :version])
      expect(dashboards.first[:content][:dashboard_title]).to eq('Birth Names')
    end

    it 'loads the databases yaml' do
      databases = loader.dashboard_config[:databases]
      expect(databases.size).to eq(1)
      expect(File.basename(databases.first[:filename])).to eq('examples.yaml')
      expect(databases.first[:content].keys).to match_array(
        [:allow_ctas, :allow_cvas, :allow_dml, :allow_file_upload, :allow_run_async, :cache_timeout, 
        :database_name, :expose_in_sqllab, :extra, :sqlalchemy_uri, :uuid, :version])
      expect(databases.first[:content][:database_name]).to eq('examples')
    end

    it 'loads the datasets yaml' do
      datasets = loader.dashboard_config[:datasets]
      expect(datasets.size).to eq(1)
      expect(File.basename(datasets.first[:filename])).to eq('birth_names.yaml')
      expect(datasets.first[:content].keys).to match_array([
          :table_name, :main_dttm_col, :description, :default_endpoint, :offset, :cache_timeout, :schema, :sql,
          :params, :template_params, :filter_select_enabled, :fetch_values_predicate, :extra, :normalize_columns, :always_filter_main_dttm,
          :uuid, :metrics, :columns, :version, :database_uuid])
      expect(datasets.first[:content][:table_name]).to eq('birth_names')
    end

    it 'loads the charts yaml' do
      charts = loader.dashboard_config[:charts]
      expect(charts.size).to eq(5)
      expect(charts.map {|c| File.basename(c[:filename]) }).to match_array([
        "Boy_Name_Cloud_53920.yaml",
        "Names_Sorted_by_Num_in_California_53929.yaml",
        "Number_of_Girls_53930.yaml",
        "Pivot_Table_53931.yaml",
        "Top_10_Girl_Name_Share_53921.yaml"])
      expect(charts.first[:content].keys).to match_array([
        :cache_timeout, :certification_details, :certified_by, :dataset_uuid, :description, :params, :query_context, 
        :slice_name, :uuid, :version, :viz_type])
      expect(charts.map{|c| c[:content][:slice_name]}.sort).to match_array(
        ["Boy Name Cloud", "Names Sorted by Num in California", "Number of Girls", "Pivot Table", "Top 10 Girl Name Share"])
    end
  end
end

require 'spec_helper'

RSpec.describe Superset::Dashboard::Export do
  subject { described_class.new(dashboard_id: dashboard_id, destination_path: destination_path) }

  let(:dashboard_id) { 18 }
  let(:destination_path) { './tmp/superset_dashboard_backups/' }
  let(:datestamp) { '20240322' }
  let(:zip_file_name) { 'spec/fixtures/dashboard_18_export_20240322.zip' } # Example fixture zip file

  describe '#perform' do
    let(:response) { double('response') }

    before do
      FileUtils.rm_rf("#{destination_path}#{dashboard_id}") if File.directory?("#{destination_path}#{dashboard_id}")

      allow(subject).to receive(:response).and_return(response)
      allow(subject).to receive(:zip_file_name).and_return(zip_file_name)
      allow(subject).to receive(:save_exported_zip_file)

      allow(subject).to receive(:datestamp).and_return(datestamp)

      @temp_dir = Dir.mktmpdir("superset_dashboard_exports")
      @extracted_files = [
        File.join(@temp_dir, "dashboard_export_#{datestamp}T123456", "metadata.yaml"),
        File.join(@temp_dir, "dashboard_export_#{datestamp}T123456", "dashboards", "Birth_Names_18.yaml"),
        File.join(@temp_dir, "dashboard_export_#{datestamp}T123456", "charts", "Boy_Name_Cloud_53920.yaml"),
        File.join(@temp_dir, "dashboard_export_#{datestamp}T123456", "charts", "Names_Sorted_by_Num_in_California_53929.yaml"),
        File.join(@temp_dir, "dashboard_export_#{datestamp}T123456", "charts", "Number_of_Girls_53930.yaml"),
        File.join(@temp_dir, "dashboard_export_#{datestamp}T123456", "charts", "Pivot_Table_53931.yaml"),
        File.join(@temp_dir, "dashboard_export_#{datestamp}T123456", "charts", "Top_10_Girl_Name_Share_53921.yaml"),
        File.join(@temp_dir, "dashboard_export_#{datestamp}T123456", "databases", "examples.yaml"),
        File.join(@temp_dir, "dashboard_export_#{datestamp}T123456", "datasets", "examples", "video_game_sales.yaml")
      ]

      FileUtils.mkdir_p(File.dirname(@extracted_files.first)) # Creates dashboard_export_20240322T123456
      @extracted_files.each do |file_path|
        FileUtils.mkdir_p(File.dirname(file_path))
        File.write(file_path, "dummy content for #{File.basename(file_path)}")
      end

      allow(subject).to receive(:unzip_file).and_return(@extracted_files)
    end

    after do
      FileUtils.rm_rf(@temp_dir) if Dir.exist?(@temp_dir)
      FileUtils.rm_rf("#{destination_path}#{dashboard_id}") if File.directory?("#{destination_path}#{dashboard_id}")
    end

    it 'unzips into the destination path with versioned filenames' do
      subject.perform

      expected_files = [
        "./tmp/superset_dashboard_backups/18/charts",
        "./tmp/superset_dashboard_backups/18/charts/Boy_Name_Cloud_53920.yaml",
        "./tmp/superset_dashboard_backups/18/charts/Names_Sorted_by_Num_in_California_53929.yaml",
        "./tmp/superset_dashboard_backups/18/charts/Number_of_Girls_53930.yaml",
        "./tmp/superset_dashboard_backups/18/charts/Pivot_Table_53931.yaml",
        "./tmp/superset_dashboard_backups/18/charts/Top_10_Girl_Name_Share_53921.yaml",
        "./tmp/superset_dashboard_backups/18/dashboards",
        "./tmp/superset_dashboard_backups/18/dashboards/Birth_Names_18.yaml",
        "./tmp/superset_dashboard_backups/18/databases",
        "./tmp/superset_dashboard_backups/18/databases/examples.yaml",
        "./tmp/superset_dashboard_backups/18/datasets",
        "./tmp/superset_dashboard_backups/18/datasets/examples",
        "./tmp/superset_dashboard_backups/18/datasets/examples/video_game_sales.yaml",
        "./tmp/superset_dashboard_backups/18/metadata.yaml"
      ]

      actual_files = Dir.glob("#{destination_path}#{dashboard_id}/**/*").sort.map do |path|
        Pathname.new(path).relative_path_from(Pathname.new('.')).to_s
      end

      actual_files = actual_files.map { |path| "./#{path}" }

      expect(actual_files).to match_array(expected_files)
    end
  end
end

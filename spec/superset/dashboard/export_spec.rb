require 'spec_helper'

RSpec.describe Superset::Dashboard::Export do
  subject { described_class.new(dashboard_id: dashboard_id, destination_path: destination_path) }
  let(:dashboard_id) { 18 }
  let(:destination_path) { './tmp/superset_dashboard_backups/' }

  describe '#perform' do
    let(:response) { double('response') }
    let(:zip_file_name) { 'spec/fixtures/dashboard_18_export_20240322.zip' } # example birth names dashboard export fixture

    before do
      allow(subject).to receive(:response).and_return(response)
      allow(subject).to receive(:zip_file_name).and_return(zip_file_name)
      allow(subject).to receive(:save_exported_zip_file)
    end

    it 'unzips into the destination path' do
      subject.perform
      expect(Dir.glob(subject.destination_path + "/**/*").sort).to match_array([
        "./tmp/superset_dashboard_backups/18",
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
        "./tmp/superset_dashboard_backups/18/datasets/examples/birth_names.yaml",
        "./tmp/superset_dashboard_backups/18/metadata.yaml"
      ])
    end
  end
end
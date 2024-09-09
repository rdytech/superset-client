require 'spec_helper'
require 'superset/services/import_dashboard_to_env'

RSpec.describe Superset::Services::ImportDashboardToEnv do
  subject {
    described_class.new(
      dashboard_export_zip_file: dashboard_export_zip_file,
      target_database_yaml:      target_database_yaml,
      target_database_schema:    target_database_schema
    )
  }

  # fixture export zip file database.yaml has database_name: examples, and uuid: a2dc77af-e654-49bb-b321-40f6b559a1ee
  let(:dashboard_export_zip_file) { 'spec/fixtures/dashboard_18_export_20240322.zip' }

  # fixture target_database_yaml has database_name: acme_client, and uuid: 2f4e4aaf-0c44-4845-bc83-de4c4d2ae20f
  let(:target_database_yaml) { 'spec/fixtures/acme_client.yaml' }
  let(:target_database_yaml_data) { YAML.load_file(subject.target_database_yaml) }

  let(:target_database_schema) { 'megacorp' }

  before do
    allow(subject).to receive(:import_new_dashboard_config) { true }
    allow(subject).to receive(:imported_dashboard_details) { { dashboard_id: 1, dashboard_title: 'Test Dashboard' } }
  end

  describe '#perform' do
    it 'creates a new dashboard import zip file' do
      expect(File.exist?(subject.send(:new_zip_file))).to be false
      subject.perform
      expect(File.exist?(subject.send(:new_zip_file))).to be true
    end

    context 'confirming new database yaml file and contents' do
      #let(:expected_new_database_schema)  { 'megacorp' }
      let(:expected_new_database_name)    { 'acme_client' }
      let(:expected_new_database_uuid)    { '2f4e4aaf-0c44-4845-bc83-de4c4d2ae20f' }

      it 'inserts the new target_database_yaml config file in to the dashboard yaml configs' do

        # confirm target database yaml settings
        expect(target_database_yaml_data['database_name']).to eq(expected_new_database_name)
        expect(target_database_yaml_data['uuid']).to eq(expected_new_database_uuid)

        # confirm current database yaml settings in the current export zip file
        current_database_files = subject.extracted_files.select {|f| f.include?('databases') }
        current_database_file_yaml = YAML.load_file(current_database_files.first)
        expect(current_database_file_yaml['database_name']).to eq('examples')
        expect(current_database_file_yaml['uuid']).to eq('a2dc77af-e654-49bb-b321-40f6b559a1ee')

        # get the previous database yaml file and UUID

        subject.perform

        # get all files in the new zip root path
        new_export_files = Dir[File.join(subject.send(:dashboard_export_root_path), '**', '**')]
        new_database_file = new_export_files.select {|f| f.include?('acme_client.yaml') }

        # confirm the new database yaml file exists in the new zip root path
        expect(new_export_files.select {|f| f.include?('examples.yaml') }.any?).to be false
        expect(new_database_file.count).to eq 1
        expect(new_database_file.first.include?('acme_client.yaml')).to be true

        # confirm new database yaml settings
        new_database_file_yaml = YAML.load_file(new_database_file.first)
        expect(new_database_file_yaml['database_name']).to eq(expected_new_database_name)
        expect(new_database_file_yaml['uuid']).to eq(expected_new_database_uuid)
      end
    end

    context 'confirming all dataset yaml files are updated' do
      # wip .. more specs coming
    end
  end
end

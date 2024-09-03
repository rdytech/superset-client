require 'spec_helper'
require 'superset/database/export'

RSpec.describe Superset::Database::Export do
  let(:subject) { described_class.new(database_id: database_id, destination_path: destination_path, remove_dataset_yamls: remove_dataset_yamls) }
  let(:database_id) { 15 }
  let(:destination_path) { '/tmp/some-destination-path/' }
  let(:remove_dataset_yamls) { true }

  describe '#perform' do
    let!(:destination_path_with_db_id) { subject.send(:destination_path_with_db_id) }

    before do
      allow(subject).to receive(:response).and_return(double(body: 'test'))
      allow(subject).to receive(:save_exported_zip_file).and_return(true)
      FileUtils.rm_rf(Dir.glob(destination_path_with_db_id)) # clean up destination path before each test
    end

    context 'with remove_dataset_yamls set to true' do
      before do
        allow(subject).to receive(:zip_file_name) { 'spec/fixtures/database_1_export_20240903.zip' }
      end

      it 'exports the database zip file and copies it to the destination path and removes dataset yamls' do
        subject.perform

        database_files = Dir.glob("#{destination_path_with_db_id}/*/databases/examples.yaml")
        expect(database_files).to eq(["#{destination_path_with_db_id}/database_export_20240903T014207/databases/examples.yaml"])

        dataset_files = Dir.glob("#{destination_path_with_db_id}/database_export_20240903T014207/dataset/*.yaml")
        expect(dataset_files).to be_empty

      end
    end

    context 'with remove_dataset_yamls set to false' do
      let!(:remove_dataset_yamls) { false }

      before do
        allow(subject).to receive(:zip_file_name) { 'spec/fixtures/database_1_export_20240903_with_datasets.zip' }
      end

      it 'exports the database zip file and copies it to the destination path' do
        subject.perform

        database_files = Dir.glob("#{destination_path_with_db_id}/*/databases/examples.yaml")
        expect(database_files).to eq(["#{destination_path_with_db_id}/database_export_20240903T022154/databases/examples.yaml"])

        dataset_files = Dir.glob("#{destination_path_with_db_id}/*/datasets/*.yaml")
        expect(dataset_files).to match_array([
          "/tmp/some-destination-path/15/database_export_20240903T022154/datasets/users.yaml",
          "/tmp/some-destination-path/15/database_export_20240903T022154/datasets/users_channels-uzooNNtSRO.yaml",
          "/tmp/some-destination-path/15/database_export_20240903T022154/datasets/users_channels.yaml"])
      end
    end
  end

  describe '#exported_zip_path' do
    before do
      allow(subject).to receive(:uuid).and_return('66707162-1231-437a-89db-6a7e2e5929bc')
      allow(subject).to receive(:datestamp).and_return('2024-09-03')
    end

    specify do
      expect(subject.exported_zip_path).to eq('/tmp/superset_database_exports/66707162-1231-437a-89db-6a7e2e5929bc/database_15_export_2024-09-03.zip')
    end
  end
end

require 'superset/services/import_dashboard_across_environment'

RSpec.describe Superset::Services::ImportDashboardAcrossEnvironments do
  let(:target_database_yaml_file) { 'spec/fixtures/database-prod-examples.yaml' }
  let(:target_database_schema) { 'acme' }
  let(:dashboard_export_zip) { 'spec/fixtures/dashboard_export_ss_v5.0.0.zip' }

  let(:service) { described_class.new(
    target_database_yaml_file: target_database_yaml_file, 
    target_database_schema:    target_database_schema, 
    dashboard_export_zip:      dashboard_export_zip) }

  def list_zip_contents(zip_file_path)
    Zip::File.open(zip_file_path) do |zip_file|
      zip_file.map(&:name)
    end
  end

  describe '#perform' do
    let(:result_zip) { service.perform }
    let(:test_unziped_path) { '/tmp/test_import_dashboard_across_env/' }

    before do
      # unziping the resulting zip to test_unziped_path for inspection
      service.unzip_file(result_zip, test_unziped_path)
    end

    context 'returns a zip file' do
      specify 'that is of file type zip' do
        expect(File.extname(result_zip)).to eq('.zip')
      end

      specify 'with the same number of files and directories as the source zip' do
        expect(list_zip_contents(result_zip).count).to eq(list_zip_contents(dashboard_export_zip).count)
      end

      specify 'with exactly 1 database yaml matching the contents of the target_database_yaml included' do
        result_zip_database_yamls =  Dir.glob(File.join(test_unziped_path, '**', 'databases', '*.yaml'))
        expect(result_zip_database_yamls.count).to eq(1)
        expect(File.basename(result_zip_database_yamls.first)).to eq(File.basename(target_database_yaml_file))
        expect(YAML.load_file(result_zip_database_yamls.first)).to eq(YAML.load_file(target_database_yaml_file))
      end

      specify 'with dataset yamls updated to include the new target database uuid' do
        result_zip_dataset_yamls =  Dir.glob(File.join(test_unziped_path, '**', 'datasets', '**', '*.yaml'))
        expect(result_zip_dataset_yamls.count).to eq(1)
        config = YAML.load_file(result_zip_dataset_yamls.first)

        expect(config['database_uuid']).to eq(YAML.load_file(target_database_yaml_file)['uuid'])
        expect(config['schema']).to eq(target_database_schema)
        expect(config['catalog']).to eq(nil)
      end
    end
  end

  describe '#validate_params' do
    context 'when all parameters are valid' do
      it 'does not raise any errors' do
        expect { service.send(:validate_params) }.not_to raise_error
      end
    end

    context 'when dashboard_export_zip does not exist' do
      let(:dashboard_export_zip) { 'non-existant-filename.zip' }

      it 'raises an error' do
        expect { service.send(:validate_params) }.to raise_error(RuntimeError, "Dashboard Export Zip file does not exist")
      end
    end

    context 'when dashboard_export_zip is not a zip file' do
      let(:dashboard_export_zip) { 'spec/fixtures/database-prod-examples.yaml' }

      it 'raises an error' do
        expect { service.send(:validate_params) }.to raise_error(RuntimeError, "Dashboard Export Zip file is not a zip file")
      end
    end

    context 'when target_database_yaml_file does not exist' do
      let(:target_database_yaml_file) { 'non-existant-filename.zip' }

      it 'raises an error' do
        expect { service.send(:validate_params) }.to raise_error(RuntimeError, "Target Database YAML file does not exist")
      end
    end

    context 'when multiple database configs exist in zip file' do
      let(:dashboard_export_zip) { 'spec/fixtures/dashboard_export_with_multiple_databases.zip' }

      it 'raises an error' do
        expect { service.send(:validate_params) }.to raise_error(RuntimeError, "Currently this class handles boards with single Database configs only. Multiple Database configs exist in zip file.")
      end
    end

    context 'when target_database_schema is blank' do
      let(:target_database_schema) { '' }

      it 'raises an error' do
        expect { service.send(:validate_params) }.to raise_error(RuntimeError, "Target Database Schema cannot be blank")
      end
    end
  end
end

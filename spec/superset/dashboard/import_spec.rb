require 'spec_helper'
require 'superset/dashboard/import'

RSpec.describe Superset::Dashboard::Import do
  describe '#perform' do
    context 'when the source zip file exists' do
      let(:subject) { described_class.new(source_zip_file: source_zip_file, overwrite: overwrite) }
      let(:source_zip_file) { 'spec/fixtures/dashboard_18_export_20240322.zip' }
      let(:overwrite) { true }

      let(:response) { { "result": "true" } }

      before { allow(subject).to receive(:response).and_return(response) }

      describe '#response' do
        context 'with valid parameters' do
          before do
            allow(Superset::Database::List).to receive(:new).
              with(uuid_equals: "a2dc77af-e654-49bb-b321-40f6b559a1ee").
              and_return(double(result: ['some data']))
          end

          specify 'returns response' do
            expect(subject.perform).to eq(response)
          end
        end

        context 'with invalid parameters' do

          context 'when source zip file is nil' do
            let(:source_zip_file) { nil }

            specify 'raises error' do
              expect { subject.perform }.to raise_error(ArgumentError, 'source_zip_file is required')
            end
          end

          context 'when source file does not exist' do
            let(:source_zip_file) { './test.zip' }

            specify 'raises error' do
              expect { subject.perform }.to raise_error(ArgumentError, 'source_zip_file does not exist')
            end
          end

          context 'when overwrite is not a boolean' do
            let(:overwrite) { 'blah' }

            specify 'raises error' do
              expect { subject.perform }.to raise_error(ArgumentError, 'overwrite must be a boolean')
            end
          end

          context 'when source_zip_file is not a zip extension' do
            let(:source_zip_file) { 'spec/fixtures/database-prod-examples.yaml' }

            specify 'raises error' do
              expect { subject.perform }.to raise_error(ArgumentError, 'source_zip_file is not a zip file')
            end
          end

          context 'when zip_database_config_not_found_in_superset is not present' do
            before do
              allow(Superset::Database::List).to receive(:new).
                with(uuid_equals: "a2dc77af-e654-49bb-b321-40f6b559a1ee").
                and_return(double(result: []))
            end

            specify 'raises error' do
              expect { subject.perform }.to raise_error(ArgumentError, "zip target database does not exist: [{:uuid=>\"a2dc77af-e654-49bb-b321-40f6b559a1ee\", :name=>\"examples\"}]")
            end
          end
        end
      end
    end
  end
end

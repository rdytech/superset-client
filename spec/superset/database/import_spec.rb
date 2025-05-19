# frozen_string_literal: true

require "spec_helper"
require "superset/database/import"
require "zip"

RSpec.describe Superset::Database::Import do
  describe "#perform" do
    context "when the source is a directory" do
      let(:subject) { described_class.new(source: source, overwrite: overwrite) }
      let(:source) do
        root_dir = File.expand_path("#{__dir__}/../../..")
        tmp_dir = "#{root_dir}/tmp"
        FileUtils.mkdir_p(tmp_dir)

        # Create a directory structure from the test zip file
        Zip::File.open("#{root_dir}/spec/fixtures/database_1_export_20240903.zip") do |zip_file|
          zip_file.each do |f|
            fpath = File.join(tmp_dir, f.name)
            FileUtils.mkdir_p(File.dirname(fpath))
            zip_file.extract(f, fpath) unless File.exist?(fpath)
          end
        end
        "#{tmp_dir}/database_export_20240903T014207"
      end
      let(:overwrite) { true }
      let(:response) { { "result": "true" } }

      before do
        allow(subject).to receive(:response).and_return(response)
        # Mock the database configuration with a valid database UUID
        database_config = {
          databases: [
            {
              content: {
                uuid: "a2dc77af-e654-49bb-b321-40f6b559a1ee",
                database_name: "examples"
              }
            }
          ]
        }
        allow(subject).to receive(:database_config).and_return(database_config)
      end

      describe "#response" do
        context "with valid parameters" do
          before do
            allow(Superset::Database::List).to receive(:new)
              .with(uuid_equals: "a2dc77af-e654-49bb-b321-40f6b559a1ee")
              .and_return(double(result: ["some data"]))
          end

          specify "returns response" do
            expect(subject.perform).to eq(response)
          end
        end

        context "when source file does not exist" do
          let(:source) { "./nonexistent_dir" }

          specify "raises error" do
            expect { subject.perform }.to raise_error(ArgumentError, "source does not exist")
          end
        end
      end
    end

    context "when the source zip file exists" do
      let(:subject) { described_class.new(source: source, overwrite: overwrite) }
      let(:source) { "spec/fixtures/database_1_export_20240903.zip" }
      let(:overwrite) { true }
      let(:response) { { "result": "true" } }

      before do
        allow(subject).to receive(:response).and_return(response)
        # Mock the database configuration with a valid database UUID
        database_config = {
          databases: [
            {
              content: {
                uuid: "a2dc77af-e654-49bb-b321-40f6b559a1ee",
                database_name: "examples"
              }
            }
          ]
        }
        allow(subject).to receive(:database_config).and_return(database_config)
      end

      describe "#response" do
        context "with valid parameters" do
          before do
            allow(Superset::Database::List).to receive(:new)
              .with(uuid_equals: "a2dc77af-e654-49bb-b321-40f6b559a1ee")
              .and_return(double(result: ["some data"]))
          end

          specify "returns response" do
            expect(subject.perform).to eq(response)
          end
        end

        context "with invalid parameters" do
          context "when source zip file is nil" do
            let(:source) { nil }

            specify "raises error" do
              expect { subject.perform }.to raise_error(ArgumentError, "source is required")
            end
          end

          context "when source file does not exist" do
            let(:source) { "./nonexistent.zip" }

            specify "raises error" do
              expect { subject.perform }.to raise_error(ArgumentError, "source does not exist")
            end
          end

          context "when overwrite is not a boolean" do
            let(:overwrite) { "not_a_boolean" }

            specify "raises error" do
              expect { subject.perform }.to raise_error(ArgumentError, "overwrite must be a boolean")
            end
          end

          context "when source is not a zip extension or directory" do
            let(:source) { "spec/fixtures/database-prod-examples.yaml" }

            specify "raises error" do
              expect { subject.perform }.to raise_error(ArgumentError, "source is not a zip file or directory")
            end
          end
        end
      end
    end
  end

  describe "#source_zip_file" do
    let(:subject) { described_class.new(source: source, overwrite: true) }

    context "when source is already a zip file" do
      let(:source) { "spec/fixtures/database_1_export_20240903.zip" }

      before do
        allow(File).to receive(:extname).with(source).and_return(".zip")
      end

      it "returns the source path unchanged" do
        expect(subject.send(:source_zip_file)).to eq(source)
      end
    end

    context "when source is a directory" do
      let(:source) { "spec/fixtures/database_export_20240903" }
      let(:new_zip_file) { "#{source}/database_import.zip" }
      let(:database_config) do
        {
          databases: [
            {
              content: {
                database_name: "examples"
              }
            }
          ]
        }
      end

      before do
        allow(File).to receive(:extname).with(source).and_return("")
        allow(File).to receive(:directory?).with(source).and_return(true)
        allow(subject).to receive(:database_config).and_return(database_config)
        allow(subject).to receive(:new_zip_file).and_return(new_zip_file)

        # Mock Zip::File.open to prevent actual zip creation
        zip_file_double = double("Zip::File")
        allow(Zip::File).to receive(:open).with(new_zip_file, Zip::File::CREATE).and_yield(zip_file_double)
        allow(zip_file_double).to receive(:add)

        # Mock Dir[] to return a list of files
        allow(Dir).to receive(:[]).with(File.join(source, "**", "**")).and_return(
          ["#{source}/file1.yaml", "#{source}/subdirectory/file2.yaml"]
        )

        # Mock File.file? to simulate real files
        allow(File).to receive(:file?).and_return(true)
      end

      it "creates a zip file and returns its path" do
        expect(Zip::File).to receive(:open).with(new_zip_file, Zip::File::CREATE)
        expect(subject.send(:source_zip_file)).to eq(new_zip_file)
      end

      it "adds directory content to the zip file" do
        zip_file_double = double("Zip::File")
        expect(Zip::File).to receive(:open).with(new_zip_file, Zip::File::CREATE).and_yield(zip_file_double)
        expect(zip_file_double).to receive(:add).with(
          "database_export_20240903/file1.yaml", "#{source}/file1.yaml"
        )
        expect(zip_file_double).to receive(:add).with(
          "database_export_20240903/subdirectory/file2.yaml", "#{source}/subdirectory/file2.yaml"
        )

        subject.send(:source_zip_file)
      end
    end
  end

  describe "#new_zip_file" do
    let(:subject) { described_class.new(source: source, overwrite: true) }
    let(:source) { "spec/fixtures/database_export_20240903" }

    context "when database config has databases" do
      let(:database_config) do
        {
          databases: [
            {
              content: {
                database_name: "test_database"
              }
            }
          ]
        }
      end

      before do
        allow(subject).to receive(:database_config).and_return(database_config)
      end

      it "creates a zip file path using the source directory" do
        expected_path = "#{source}/database_import.zip"
        expect(subject.send(:new_zip_file)).to eq(expected_path)
      end
    end
  end

  describe "#payload" do
    let(:subject) { described_class.new(source: source, overwrite: overwrite) }
    let(:source) { "spec/fixtures/database_1_export_20240903.zip" }
    let(:overwrite) { true }

    before do
      allow(subject).to receive(:source_zip_file).and_return(source)
      allow(Faraday::UploadIO).to receive(:new).with(source, "application/zip").and_return("mock_upload_io")
    end

    it "includes formData and overwrite parameters" do
      expect(subject.send(:payload)).to include(
        formData: "mock_upload_io",
        overwrite: "true",
        passwords: "{}"
      )
    end
  end

  describe "#route" do
    let(:subject) { described_class.new(source: "spec/fixtures/database_1_export_20240903.zip", overwrite: true) }

    it "returns the correct API endpoint" do
      expect(subject.send(:route)).to eq("database/import/")
    end
  end
end

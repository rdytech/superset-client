# frozen_string_literal: true

require "spec_helper"
require "superset/dashboard/import"
require "zip"

RSpec.describe Superset::Dashboard::Import do
  describe "#perform" do
    context "when the source is a directory" do
      let(:subject) { described_class.new(source: source, overwrite: overwrite) }
      let(:source) do
        root_dir = File.expand_path("#{__dir__}/../../..")
        tmp_dir = "#{root_dir}/tmp"
        FileUtils.mkdir_p(tmp_dir)

        Zip::File.open("#{root_dir}/spec/fixtures/dashboard_18_export_20240322.zip") do |zip_file|
          zip_file.each do |f|
            fpath = File.join(tmp_dir, f.name)
            FileUtils.mkdir_p(File.dirname(fpath))
            zip_file.extract(f, fpath) unless File.exist?(fpath)
          end
        end
        "#{tmp_dir}/dashboard_export_20240321T214117"
      end
      let(:overwrite) { true }

      let(:response) { { "result": "true" } }

      before { allow(subject).to receive(:response).and_return(response) }

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
          let(:source) { "./test" }

          specify "raises error" do
            expect { subject.perform }.to raise_error(ArgumentError, "source does not exist")
          end
        end

        context "when database_config_not_found_in_superset is not present" do
          before do
            allow(Superset::Database::List).to receive(:new)
              .with(uuid_equals: "a2dc77af-e654-49bb-b321-40f6b559a1ee")
              .and_return(double(result: []))
          end

          specify "raises error" do
            expect do
              subject.perform
            end.to raise_error(ArgumentError,
                               "target database does not exist: [{:uuid=>\"a2dc77af-e654-49bb-b321-40f6b559a1ee\", :name=>\"examples\"}]")
          end
        end
      end
    end
    context "when the source zip file exists" do
      let(:subject) { described_class.new(source: source, overwrite: overwrite) }
      let(:source) { "spec/fixtures/dashboard_18_export_20240322.zip" }
      let(:overwrite) { true }

      let(:response) { { "result": "true" } }

      before { allow(subject).to receive(:response).and_return(response) }

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
            let(:source) { "./test.zip" }

            specify "raises error" do
              expect { subject.perform }.to raise_error(ArgumentError, "source does not exist")
            end
          end

          context "when overwrite is not a boolean" do
            let(:overwrite) { "blah" }

            specify "raises error" do
              expect { subject.perform }.to raise_error(ArgumentError, "overwrite must be a boolean")
            end
          end

          context "when source is not a zip extension" do
            let(:source) { "spec/fixtures/database-prod-examples.yaml" }

            specify "raises error" do
              expect { subject.perform }.to raise_error(ArgumentError, "source is not a zip file or directory")
            end
          end

          context "when database_config_not_found_in_superset is not present" do
            before do
              allow(Superset::Database::List).to receive(:new)
                .with(uuid_equals: "a2dc77af-e654-49bb-b321-40f6b559a1ee")
                .and_return(double(result: []))
            end

            specify "raises error" do
              expect do
                subject.perform
              end.to raise_error(ArgumentError,
                                 "target database does not exist: [{:uuid=>\"a2dc77af-e654-49bb-b321-40f6b559a1ee\", :name=>\"examples\"}]")
            end
          end
        end
      end
    end
  end

  describe "#source_zip_file" do
    let(:subject) { described_class.new(source: source, overwrite: true) }

    context "when source is already a zip file" do
      let(:source) { "spec/fixtures/dashboard_18_export_20240322.zip" }

      before do
        allow(File).to receive(:extname).with(source).and_return(".zip")
      end

      it "returns the source path unchanged" do
        expect(subject.send(:source_zip_file)).to eq(source)
      end
    end

    context "when source is a directory" do
      let(:source) { "spec/fixtures/dashboard_export_20240321T214117" }
      let(:new_zip_file) { "#{source}/dashboard_import.zip" }
      let(:dashboard_config) do
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
        allow(subject).to receive(:dashboard_config).and_return(dashboard_config)
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
          "dashboard_import_#{subject.send(:timestamp)}/file1.yaml", "#{source}/file1.yaml"
        )
        expect(zip_file_double).to receive(:add).with(
          "dashboard_import_#{subject.send(:timestamp)}/subdirectory/file2.yaml", "#{source}/subdirectory/file2.yaml"
        )

        subject.send(:source_zip_file)
      end
    end

    context "integration between source_zip_file and new_zip_file methods" do
      let(:source) { "spec/fixtures/dashboard_export_20240321T214117" }
      let(:dashboard_config) do
        {
          databases: [
            {
              content: {
                database_name: "custom_database"
              }
            }
          ]
        }
      end

      before do
        allow(File).to receive(:extname).with(source).and_return("")
        allow(File).to receive(:directory?).with(source).and_return(true)
        allow(subject).to receive(:dashboard_config).and_return(dashboard_config)

        # Skip actual zip creation
        zip_file_double = double("Zip::File")
        allow(Zip::File).to receive(:open).and_yield(zip_file_double)
        allow(zip_file_double).to receive(:add)
        allow(Dir).to receive(:[]).and_return([])
      end

      it "creates a zip file in the source directory" do
        expected_path = "#{source}/dashboard_import_#{subject.send(:timestamp)}.zip"
        expect(subject.send(:source_zip_file)).to eq(expected_path)
      end
    end

    context "when source is neither a zip file nor a directory" do
      let(:source) { "spec/fixtures/some_invalid_file.txt" }

      before do
        allow(File).to receive(:extname).with(source).and_return(".txt")
        allow(File).to receive(:directory?).with(source).and_return(false)
        allow(File).to receive(:exist?).with(source).and_return(true)
      end

      it "raises an error during validation" do
        expect { subject.perform }.to raise_error(ArgumentError, "source is not a zip file or directory")
      end
    end
  end

  describe "#new_zip_file" do
    let(:subject) { described_class.new(source: source, overwrite: true) }
    let(:source) { "spec/fixtures/dashboard_export_20240321T214117" }

    context "when dashboard config has databases" do
      let(:dashboard_config) do
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
        allow(subject).to receive(:dashboard_config).and_return(dashboard_config)
      end

      it "creates a zip file path using the source directory" do
        expected_path = "#{source}/dashboard_import_#{subject.send(:timestamp)}.zip"
        expect(subject.send(:new_zip_file)).to eq(expected_path)
      end
    end
  end
end

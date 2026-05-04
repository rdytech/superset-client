# frozen_string_literal: true

require "spec_helper"
require "superset/database/upload_csv"

RSpec.describe Superset::Database::UploadCsv do
  let(:valid_file) { "spec/fixtures/sample.csv" }
  let(:subject) do
    described_class.new(database_id: 1, file: valid_file, table_name: "my_table")
  end

  before do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(valid_file).and_return(true)
  end

  describe "#perform" do
    let(:response) { { "message" => "OK" } }

    before { allow(subject).to receive(:response).and_return(response) }

    context "with valid required params" do
      it "returns the response" do
        expect(subject.perform).to eq(response)
      end
    end

    context "when database_id is nil" do
      let(:subject) { described_class.new(database_id: nil, file: valid_file, table_name: "my_table") }

      it "raises ArgumentError" do
        expect { subject.perform }.to raise_error(ArgumentError, "database_id is required")
      end
    end

    context "when file is nil" do
      let(:subject) { described_class.new(database_id: 1, file: nil, table_name: "my_table") }

      it "raises ArgumentError" do
        expect { subject.perform }.to raise_error(ArgumentError, "file is required")
      end
    end

    context "when file does not exist" do
      let(:subject) { described_class.new(database_id: 1, file: "/nonexistent/file.csv", table_name: "my_table") }

      it "raises ArgumentError" do
        expect { subject.perform }.to raise_error(ArgumentError, "file does not exist")
      end
    end

    context "when table_name is nil" do
      let(:subject) { described_class.new(database_id: 1, file: valid_file, table_name: nil) }

      it "raises ArgumentError" do
        expect { subject.perform }.to raise_error(ArgumentError, "table_name is required")
      end
    end

    context "when table_name is blank" do
      let(:subject) { described_class.new(database_id: 1, file: valid_file, table_name: "  ") }

      it "raises ArgumentError" do
        expect { subject.perform }.to raise_error(ArgumentError, "table_name is required")
      end
    end

    context "when already_exists is an invalid value" do
      let(:subject) do
        described_class.new(database_id: 1, file: valid_file, table_name: "my_table", already_exists: "overwrite")
      end

      it "raises ArgumentError" do
        expect { subject.perform }.to raise_error(ArgumentError, "already_exists must be one of: fail, replace, append")
      end
    end

    context "when already_exists is a valid value" do
      %w[fail replace append].each do |value|
        it "accepts '#{value}'" do
          s = described_class.new(database_id: 1, file: valid_file, table_name: "my_table", already_exists: value)
          allow(s).to receive(:response).and_return(response)
          expect { s.perform }.not_to raise_error
        end
      end
    end
  end

  describe "#payload" do
    before do
      allow(Faraday::UploadIO).to receive(:new).with(valid_file, "text/csv").and_return("UPLOAD_IO")
    end

    context "with only required params" do
      it "includes file, table_name, and type only" do
        payload = subject.send(:payload)
        expect(payload.keys).to match_array([:file, :table_name, :type])
        expect(payload[:type]).to eq("csv")
        expect(payload[:table_name]).to eq("my_table")
      end

      it "excludes all optional params" do
        payload = subject.send(:payload)
        expect(payload).not_to have_key(:already_exists)
        expect(payload).not_to have_key(:schema)
        expect(payload).not_to have_key(:delimiter)
      end
    end

    context "with optional params provided" do
      let(:subject) do
        described_class.new(
          database_id: 1,
          file: valid_file,
          table_name: "my_table",
          already_exists: "replace",
          schema: "public",
          delimiter: ",",
          column_data_types: { "user_id" => "int" },
          dataframe_index: false,
          skip_blank_lines: true,
          header_row: 0,
          skip_rows: 2
        )
      end

      it "includes provided optional params" do
        payload = subject.send(:payload)
        expect(payload[:already_exists]).to eq("replace")
        expect(payload[:schema]).to eq("public")
        expect(payload[:delimiter]).to eq(",")
      end

      it "serializes column_data_types to JSON" do
        expect(subject.send(:payload)[:column_data_types]).to eq('{"user_id":"int"}')
      end

      it "stringifies boolean params" do
        payload = subject.send(:payload)
        expect(payload[:dataframe_index]).to eq("false")
        expect(payload[:skip_blank_lines]).to eq("true")
      end

      it "includes integer params" do
        payload = subject.send(:payload)
        expect(payload[:header_row]).to eq(0)
        expect(payload[:skip_rows]).to eq(2)
      end
    end
  end

  describe "#route" do
    it "returns the correct route" do
      expect(subject.send(:route)).to eq("database/1/upload/")
    end
  end

  describe "#result" do
    before { allow(subject).to receive(:response).and_return({ "message" => "OK" }) }

    it "returns the message from the response" do
      expect(subject.result).to eq("OK")
    end
  end
end

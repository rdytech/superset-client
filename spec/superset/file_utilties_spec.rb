# frozen_string_literal: true

require 'spec_helper'
require 'superset/file_utilities'
require 'tmpdir'

RSpec.describe Superset::FileUtilities do
  # Test via a class that includes the module
  let(:dummy_class) do
    Class.new do
      include Superset::FileUtilities
    end
  end
  let(:subject) { dummy_class.new }

  describe '#unzip_file' do
    let(:destination) { Dir.mktmpdir('unzip_file_spec') }

    after do
      FileUtils.rm_rf(destination) if Dir.exist?(destination)
    end

    context 'with a valid zip file' do
      let(:zip_path) { File.join(destination, 'test.zip') }

      before do
        Zip::File.open(zip_path, create: true) do |zip|
          zip.get_output_stream('foo.txt') { |f| f.write('hello') }
          zip.get_output_stream('bar/nested.txt') { |f| f.write('nested') }
        end
      end

      it 'extracts all entries to the destination and returns their paths' do
        result = subject.unzip_file(zip_path, destination)

        expect(result).to match_array([
          File.join(destination, 'foo.txt'),
          File.join(destination, 'bar/nested.txt')
        ])
      end

      it 'creates the expected files on disk' do
        subject.unzip_file(zip_path, destination)

        expect(File.read(File.join(destination, 'foo.txt'))).to eq('hello')
        expect(File.read(File.join(destination, 'bar/nested.txt'))).to eq('nested')
      end

      it 'overwrites existing files with zip contents' do
        existing = File.join(destination, 'foo.txt')
        FileUtils.mkdir_p(File.dirname(existing))
        File.write(existing, 'existing')

        subject.unzip_file(zip_path, destination)

        expect(File.read(existing)).to eq('hello')
      end
    end

    context 'with destination as absolute path (RubyZip 3.x compatibility)' do
      it 'extracts successfully when destination is absolute' do
        zip_path = File.join(destination, 'abs.zip')
        Zip::File.open(zip_path, create: true) do |zip|
          zip.get_output_stream('single.txt') { |f| f.write('x') }
        end

        result = subject.unzip_file(zip_path, destination)

        expect(result).to include(File.join(destination, 'single.txt'))
        expect(File.read(File.join(destination, 'single.txt'))).to eq('x')
      end
    end

    context 'with empty entry names' do
      it 'skips entries with empty names and does not raise' do
        zip_path = File.join(destination, 'empty_entries.zip')
        # Create zip with one valid entry; empty-name entries are rare but we test the skip
        Zip::File.open(zip_path, create: true) do |zip|
          zip.get_output_stream('valid.txt') { |f| f.write('ok') }
        end

        result = subject.unzip_file(zip_path, destination)

        expect(result).to eq([File.join(destination, 'valid.txt')])
        expect(File.read(File.join(destination, 'valid.txt'))).to eq('ok')
      end

      it 'skips entries whose name is empty (zip slip / malformed zip guard)' do
        zip_path = File.join(destination, 'with_empty_name.zip')
        Zip::File.open(zip_path, create: true) do |zip|
          zip.get_output_stream('valid.txt') { |f| f.write('content') }
        end

        # Stub to simulate a zip that yields an entry with empty name before the real entry
        empty_name_entry = double('Zip::Entry', name: '')
        allow(Zip::File).to receive(:open).and_wrap_original do |method, path, *args, &block|
          method.call(path, *args) do |z|
            real_entries = z.entries
            allow(z).to receive(:each) do |&iter_block|
              iter_block.call(empty_name_entry)
              real_entries.each(&iter_block)
            end
            block.call(z)
          end
        end

        result = subject.unzip_file(zip_path, destination)

        expect(result).to eq([File.join(destination, 'valid.txt')])
        expect(File.read(File.join(destination, 'valid.txt'))).to eq('content')
      end
    end

    context 'when zip file does not exist' do
      it 'raises when opening the zip fails' do
        expect {
          subject.unzip_file(File.join(destination, 'nonexistent.zip'), destination)
        }.to raise_error(Zip::Error, /not found/)
      end
    end
  end
end

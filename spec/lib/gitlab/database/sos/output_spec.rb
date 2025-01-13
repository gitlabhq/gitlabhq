# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Sos::Output, feature_category: :database do
  let(:temp_directory) { Dir.mktmpdir }
  let(:zip_path) { File.join(temp_directory, 'test.zip') }
  let(:directory_path) { File.join(temp_directory, 'test_directory') }

  after do
    FileUtils.remove_entry(temp_directory)
  end

  describe '#writing' do
    it 'yields an output object and ensures finish is called' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:finish)
      end

      described_class.writing(zip_path, mode: :zip) do |output|
        expect(output).to be_a(described_class)
      end
    end
  end

  describe '#initialize' do
    it 'raises an error for invalid mode' do
      expect { described_class.new(zip_path, mode: :invalid) }
        .to raise_error(RuntimeError, "mode must be one of :zip, :directory")
    end
  end

  describe '#write_file' do
    let(:relative_path) { 'test/file.txt' }
    let(:content) { 'PG Settings' }

    it 'writes content to a file in zip mode' do
      described_class.writing(zip_path, mode: :zip) do |output|
        output.write_file(relative_path) { |f| f.write(content) }
      end

      Zip::File.open(zip_path) do |zip_file|
        expect(zip_file.read(relative_path)).to eq(content)
      end
    end

    it 'writes content to a file in directory mode' do
      described_class.writing(directory_path, mode: :directory) do |output|
        output.write_file(relative_path) { |f| f.write(content) }
      end

      expect(File.read(File.join(directory_path, relative_path))).to eq(content)
    end
  end
end

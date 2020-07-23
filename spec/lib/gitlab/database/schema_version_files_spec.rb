# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaVersionFiles do
  describe '.touch_all' do
    let(:versions) { %w[2020123 2020456 2020890] }

    it 'creates a file containing a checksum for each version given' do
      Dir.mktmpdir do |tmpdir|
        schema_dirpath = Pathname.new(tmpdir).join("test")
        FileUtils.mkdir_p(schema_dirpath)

        old_version_filepath = schema_dirpath.join("2020001")
        FileUtils.touch(old_version_filepath)

        expect(File.exist?(old_version_filepath)).to be(true)

        allow(described_class).to receive(:schema_dirpath).and_return(schema_dirpath)

        described_class.touch_all(versions)

        expect(File.exist?(old_version_filepath)).to be(false)
        versions.each do |version|
          version_filepath = schema_dirpath.join(version)
          expect(File.exist?(version_filepath)).to be(true)

          hashed_value = Digest::SHA256.hexdigest(version)
          expect(File.read(version_filepath)).to eq(hashed_value)
        end
      end
    end
  end

  describe '.load_all' do
    let(:connection) { double('connection') }

    before do
      allow(described_class).to receive(:connection).and_return(connection)
      allow(described_class).to receive(:find_version_filenames).and_return(filenames)
    end

    context 'when there are no version files' do
      let(:filenames) { [] }

      it 'does nothing' do
        expect(connection).not_to receive(:quote_string)
        expect(connection).not_to receive(:execute)

        described_class.load_all
      end
    end

    context 'when there are version files' do
      let(:filenames) { %w[123 456 789] }

      it 'inserts the missing versions into schema_migrations' do
        filenames.each do |filename|
          expect(connection).to receive(:quote_string).with(filename).and_return(filename)
        end

        expect(connection).to receive(:execute).with(<<~SQL)
          INSERT INTO schema_migrations (version)
          VALUES ('123'),('456'),('789')
          ON CONFLICT DO NOTHING
        SQL

        described_class.load_all
      end
    end
  end
end

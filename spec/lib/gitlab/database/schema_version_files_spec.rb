# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaVersionFiles do
  describe '.touch_all' do
    let(:version1) { '20200123' }
    let(:version2) { '20200410' }
    let(:version3) { '20200602' }
    let(:version4) { '20200809' }
    let(:relative_schema_directory) { 'db/schema_migrations' }
    let(:relative_migrate_directory) { 'db/migrate' }
    let(:relative_post_migrate_directory) { 'db/post_migrate' }

    it 'creates a file containing a checksum for each version with a matching migration' do
      Dir.mktmpdir do |tmpdir|
        schema_directory = Pathname.new(tmpdir).join(relative_schema_directory)
        migrate_directory = Pathname.new(tmpdir).join(relative_migrate_directory)
        post_migrate_directory = Pathname.new(tmpdir).join(relative_post_migrate_directory)

        FileUtils.mkdir_p(migrate_directory)
        FileUtils.mkdir_p(post_migrate_directory)
        FileUtils.mkdir_p(schema_directory)

        migration1_filepath = migrate_directory.join("#{version1}_migration.rb")
        FileUtils.touch(migration1_filepath)

        migration2_filepath = post_migrate_directory.join("#{version2}_post_migration.rb")
        FileUtils.touch(migration2_filepath)

        old_version_filepath = schema_directory.join('20200101')
        FileUtils.touch(old_version_filepath)

        expect(File.exist?(old_version_filepath)).to be(true)

        allow(described_class).to receive(:schema_directory).and_return(schema_directory)
        allow(described_class).to receive(:migration_directories).and_return([migrate_directory, post_migrate_directory])

        described_class.touch_all([version1, version2, version3, version4])

        expect(File.exist?(old_version_filepath)).to be(false)
        [version1, version2].each do |version|
          version_filepath = schema_directory.join(version)
          expect(File.exist?(version_filepath)).to be(true)

          hashed_value = Digest::SHA256.hexdigest(version)
          expect(File.read(version_filepath)).to eq(hashed_value)
        end

        [version3, version4].each do |version|
          version_filepath = schema_directory.join(version)
          expect(File.exist?(version_filepath)).to be(false)
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

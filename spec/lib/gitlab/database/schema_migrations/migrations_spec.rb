# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaMigrations::Migrations do
  let(:connection) { ApplicationRecord.connection }
  let(:context) { Gitlab::Database::SchemaMigrations::Context.new(connection) }

  let(:migrations) { described_class.new(context) }

  describe '#touch_all' do
    let(:version1) { '20200123' }
    let(:version2) { '20200410' }
    let(:version3) { '20200602' }
    let(:version4) { '20200809' }

    let(:relative_schema_directory) { 'db/schema_migrations' }

    it 'creates a file containing a checksum for each version with a matching migration' do
      Dir.mktmpdir do |tmpdir|
        schema_directory = Pathname.new(tmpdir).join(relative_schema_directory)
        FileUtils.mkdir_p(schema_directory)

        old_version_filepath = schema_directory.join('20200101')
        FileUtils.touch(old_version_filepath)

        expect(File.exist?(old_version_filepath)).to be(true)

        allow(context).to receive(:schema_directory).and_return(schema_directory)
        allow(context).to receive(:versions_to_create).and_return([version1, version2])

        migrations.touch_all

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

  describe '#load_all' do
    before do
      allow(migrations).to receive(:version_filenames).and_return(filenames)
    end

    context 'when there are no version files' do
      let(:filenames) { [] }

      it 'does nothing' do
        expect(connection).not_to receive(:quote_string)
        expect(connection).not_to receive(:execute)

        migrations.load_all
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

        migrations.load_all
      end
    end
  end
end

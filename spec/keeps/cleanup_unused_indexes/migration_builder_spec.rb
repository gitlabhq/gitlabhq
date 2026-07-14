# frozen_string_literal: true

require 'spec_helper'
require './keeps/cleanup_unused_indexes/migration_builder'

RSpec.describe Keeps::CleanupUnusedIndexes::MigrationBuilder, feature_category: :database do
  let(:migration_file) { 'db/post_migrate/20260601000000_remove_unused_index_index_users_on_foo.rb' }
  let(:generator) { instance_double(::PostDeploymentMigration::PostDeploymentMigrationGenerator) }
  let(:file_helper) { instance_double(::Keeps::Helpers::FileHelper) }

  let(:ctx) do
    {
      name: 'index_users_on_foo',
      tablename: 'users',
      columns: [:foo]
    }
  end

  subject(:builder) { described_class.new }

  before do
    allow(::PostDeploymentMigration::PostDeploymentMigrationGenerator)
      .to receive(:new).and_return(generator)
    allow(generator).to receive_messages(
      invoke_all: [migration_file],
      migration_number: '20260601000000'
    )
    allow(::Keeps::Helpers::FileHelper).to receive(:new).with(migration_file).and_return(file_helper)
    allow(file_helper).to receive(:replace_method_content)
    allow(::Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(a_string_matching(%r{db/schema_migrations/}), 'w').and_yield(StringIO.new)
  end

  describe '#build' do
    it 'returns a Result with the migration file, number, and digest path', :aggregate_failures do
      result = builder.build(ctx)

      expect(result.migration_file).to eq(migration_file)
      expect(result.migration_number).to eq('20260601000000')
      expect(result.digest_file).to eq('db/schema_migrations/20260601000000')
    end

    it 'rewrites the generated stub with remove_concurrent_index_by_name' do
      builder.build(ctx)

      expect(file_helper).to have_received(:replace_method_content)
        .with(:change, a_string_matching(/remove_concurrent_index_by_name\(TABLE_NAME, INDEX_NAME\)/),
          strip_comments_from_file: true)
    end

    it 're-adds the index with add_concurrent_index in the down block' do
      builder.build(ctx)

      expect(file_helper).to have_received(:replace_method_content).with(
        :change,
        a_string_matching(/add_concurrent_index\(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME\)/),
        strip_comments_from_file: true
      )
    end

    it 'runs rubocop autocorrect on the new migration' do
      builder.build(ctx)

      expect(::Gitlab::Housekeeper::Shell).to have_received(:rubocop_autocorrect).with(migration_file)
    end

    it 'writes the schema_migrations digest file' do
      digest_io = StringIO.new
      allow(File).to receive(:open)
        .with('db/schema_migrations/20260601000000', 'w').and_yield(digest_io)

      builder.build(ctx)

      expect(digest_io.string).to eq(Digest::SHA256.hexdigest('20260601000000'))
    end
  end

  describe 'unique migration name (private)' do
    it 'returns the base name when short enough' do
      expect(builder.send(:unique_migration_name_for, 'foo')).to eq('remove_unused_index_foo')
    end

    it 'truncates and appends a SHA suffix for long names', :aggregate_failures do
      long_name = "index_#{'x' * 100}"
      result = builder.send(:unique_migration_name_for, long_name)

      expect(result.length).to be <= 100
      expect(result).to match(/_[0-9a-f]{8}\z/)
    end
  end
end

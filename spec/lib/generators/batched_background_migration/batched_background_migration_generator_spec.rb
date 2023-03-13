# frozen_string_literal: true

require 'spec_helper'
require 'rails/generators/testing/behaviour'
require 'rails/generators/testing/assertions'

RSpec.describe BatchedBackgroundMigration::BatchedBackgroundMigrationGenerator, feature_category: :database do
  include Rails::Generators::Testing::Behaviour
  include Rails::Generators::Testing::Assertions
  include FileUtils

  tests described_class
  destination File.expand_path('tmp', __dir__)

  before do
    prepare_destination
  end

  after do
    rm_rf(destination_root)
  end

  context 'with valid arguments' do
    let(:expected_migration_file) { load_expected_file('queue_my_batched_migration.txt') }
    let(:expected_migration_spec_file) { load_expected_file('queue_my_batched_migration_spec.txt') }
    let(:expected_migration_job_file) { load_expected_file('my_batched_migration.txt') }
    let(:expected_migration_job_spec_file) { load_expected_file('my_batched_migration_spec_matcher.txt') }
    let(:expected_migration_dictionary) { load_expected_file('my_batched_migration_dictionary_matcher.txt') }

    it 'generates expected files' do
      run_generator %w[my_batched_migration --table_name=projects --column_name=id --feature_category=database]

      assert_migration('db/post_migrate/queue_my_batched_migration.rb') do |migration_file|
        expect(migration_file).to eq(expected_migration_file)
      end

      assert_migration('spec/migrations/queue_my_batched_migration_spec.rb') do |migration_spec_file|
        expect(migration_spec_file).to eq(expected_migration_spec_file)
      end

      assert_file('lib/gitlab/background_migration/my_batched_migration.rb') do |migration_job_file|
        expect(migration_job_file).to eq(expected_migration_job_file)
      end

      assert_file('spec/lib/gitlab/background_migration/my_batched_migration_spec.rb') do |migration_job_spec_file|
        # Regex is used to match the dynamic schema: <version> in the specs
        expect(migration_job_spec_file).to match(/#{expected_migration_job_spec_file}/)
      end

      assert_file('db/docs/batched_background_migrations/my_batched_migration.yml') do |migration_dictionary|
        # Regex is used to match the dynamically generated 'milestone' in the dictionary
        expect(migration_dictionary).to match(/#{expected_migration_dictionary}/)
      end
    end
  end

  context 'without required arguments' do
    it 'throws table_name is required error' do
      expect do
        run_generator %w[my_batched_migration]
      end.to raise_error(ArgumentError, 'table_name is required')
    end

    it 'throws column_name is required error' do
      expect do
        run_generator %w[my_batched_migration --table_name=projects]
      end.to raise_error(ArgumentError, 'column_name is required')
    end

    it 'throws feature_category is required error' do
      expect do
        run_generator %w[my_batched_migration --table_name=projects --column_name=id]
      end.to raise_error(ArgumentError, 'feature_category is required')
    end
  end

  private

  def load_expected_file(file_name)
    File.read(File.expand_path("expected_files/#{file_name}", __dir__))
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'rails/generators/testing/assertions'

if ::Gitlab.next_rails?
  require 'rails/generators/testing/behavior'
else
  require 'rails/generators/testing/behaviour'
end

RSpec.describe BatchedBackgroundMigration::BatchedBackgroundMigrationGenerator, feature_category: :database do
  include Rails::Generators::Testing::Behaviour
  include Rails::Generators::Testing::Assertions
  include FileUtils

  tests described_class
  destination File.expand_path('tmp', __dir__)

  before do
    prepare_destination
    allow(Gitlab).to receive(:current_milestone).and_return('16.6')
  end

  after do
    rm_rf(destination_root)
  end

  shared_examples "generates files common to both types of migrations" do |migration_job_file, migration_file,
    migration_spec_file, migration_dictionary_file|
    let(:expected_migration_job_file) { load_expected_file(migration_job_file) }
    let(:expected_migration_file) { load_expected_file(migration_file) }
    let(:expected_migration_spec_file) { load_expected_file(migration_spec_file) }
    let(:expected_migration_dictionary) { load_expected_file(migration_dictionary_file) }

    it 'generates expected common files' do
      assert_file('lib/gitlab/background_migration/my_batched_migration.rb') do |migration_job_file|
        expect(migration_job_file).to eq(expected_migration_job_file)
      end

      assert_migration('db/post_migrate/queue_my_batched_migration.rb') do |migration_file|
        expect(migration_file).to eq(expected_migration_file.gsub('<migration_version>', fetch_migration_version))
      end

      assert_migration('spec/migrations/queue_my_batched_migration_spec.rb') do |migration_spec_file|
        expect(migration_spec_file).to eq(expected_migration_spec_file)
      end

      assert_file('db/docs/batched_background_migrations/my_batched_migration.yml') do |migration_dictionary|
        # Regex is used to match the dynamically generated 'milestone' in the dictionary
        expect(migration_dictionary).to match(/#{expected_migration_dictionary}/)
      end
    end
  end

  context 'when generating EE-only batched background migration' do
    before do
      run_generator %w[my_batched_migration --table_name=projects --column_name=id --feature_category=database
        --ee-only]
    end

    let(:expected_ee_migration_job_file) { load_expected_file('ee_my_batched_migration.txt') }
    let(:expected_migration_job_spec_file) { load_expected_file('my_batched_migration_spec.txt') }

    include_examples "generates files common to both types of migrations",
      'foss_my_batched_migration.txt',
      'queue_my_batched_migration.txt',
      'queue_my_batched_migration_spec.txt',
      'my_batched_migration_dictionary_matcher.txt'

    it 'generates expected files' do
      assert_file('ee/lib/ee/gitlab/background_migration/my_batched_migration.rb') do |migration_job_file|
        expect(migration_job_file).to eq(expected_ee_migration_job_file)
      end

      migration_job_spec_file = 'ee/spec/lib/ee/gitlab/background_migration/my_batched_migration_spec.rb'
      assert_file(migration_job_spec_file) do |spec_file|
        expect(spec_file).to match(/#{expected_migration_job_spec_file}/)
      end
    end
  end

  context 'when generating FOSS batched background migration' do
    before do
      run_generator %w[my_batched_migration --table_name=projects --column_name=id --feature_category=database]
    end

    let(:expected_migration_job_spec_file) { load_expected_file('my_batched_migration_spec.txt') }

    include_examples "generates files common to both types of migrations",
      'my_batched_migration.txt',
      'queue_my_batched_migration.txt',
      'queue_my_batched_migration_spec.txt',
      'my_batched_migration_dictionary_matcher.txt'

    it 'generates expected files' do
      assert_file('spec/lib/gitlab/background_migration/my_batched_migration_spec.rb') do |migration_job_spec_file|
        expect(migration_job_spec_file).to eq(expected_migration_job_spec_file)
      end
    end
  end

  private

  def load_expected_file(file_name)
    File.read(File.expand_path("expected_files/#{file_name}", __dir__))
  end

  def fetch_migration_version
    @migration_version ||= migration_file_name('db/post_migrate/queue_my_batched_migration.rb')
      .match(%r{post_migrate/([0-9]+)_queue_my_batched_migration.rb})[1]
  end
end

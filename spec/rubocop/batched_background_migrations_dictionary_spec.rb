# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../rubocop/batched_background_migrations_dictionary'

RSpec.describe RuboCop::BatchedBackgroundMigrationsDictionary, feature_category: :database do
  let(:bbm_dictionary_file_name) { "#{described_class::DICTIONARY_BASE_DIR}/test_migration.yml" }
  let(:migration_version) { 20230307160250 }
  let(:finalized_by_version) { 20230307160255 }
  let(:introduced_by_url) { 'https://test_url' }
  let(:finalize_after) { '202312011212' }

  let(:bbm_dictionary_data) do
    {
      migration_job_name: 'TestMigration',
      feature_category: :database,
      introduced_by_url: introduced_by_url,
      milestone: 16.5,
      queued_migration_version: migration_version,
      finalized_by: finalized_by_version,
      finalize_after: finalize_after
    }
  end

  before do
    File.open(bbm_dictionary_file_name, 'w') do |file|
      file.write(bbm_dictionary_data.stringify_keys.to_yaml)
    end
  end

  after do
    FileUtils.rm(bbm_dictionary_file_name)
  end

  subject(:batched_background_migration) { described_class.new(migration_version) }

  describe '#finalized_by' do
    it 'returns the finalized_by version of the bbm with given version',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/456913' do
      expect(batched_background_migration.finalized_by).to eq(finalized_by_version.to_s)
    end

    it 'returns nothing for non-existing bbm dictionary' do
      expect(described_class.new('random').finalized_by).to be_nil
    end
  end

  describe '#introduced_by_url' do
    it 'returns the introduced_by_url of the bbm with given version',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/456912' do
      expect(batched_background_migration.introduced_by_url).to eq(introduced_by_url)
    end

    it 'returns nothing for non-existing bbm dictionary' do
      expect(described_class.new('random').introduced_by_url).to be_nil
    end
  end

  describe '#finalize_after' do
    it 'returns the finalize_after timestamp of the bbm with given version',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/456914' do
      expect(batched_background_migration.finalize_after).to eq(finalize_after)
    end

    it 'returns nothing for non-existing bbm dictionary' do
      expect(described_class.new('random').finalize_after).to be_nil
    end
  end

  describe '.checksum' do
    let(:dictionary_data) { { c: "d", a: "b" } }

    it 'returns a checksum of the dictionary_data' do
      allow(described_class).to receive(:dictionary_data).and_return(dictionary_data)

      expect(described_class.checksum).to eq(Digest::SHA256.hexdigest(dictionary_data.to_s))
    end
  end
end

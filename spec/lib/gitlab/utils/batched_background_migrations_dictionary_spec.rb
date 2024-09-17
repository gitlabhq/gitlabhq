# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Utils::BatchedBackgroundMigrationsDictionary, feature_category: :database do
  let(:bbm_dictionary_file_name) { "#{described_class::DICTIONARY_BASE_DIR}/test_migration.yml" }
  let(:migration_version) { 20230307160250 }
  let(:finalized_by) { '20230307160255' }
  let(:introduced_by_url) { 'https://test_url' }
  let(:milestone) { '16.5' }
  let(:migration_job_name) { 'TestMigration' }

  let(:bbm_dictionary_data) do
    {
      migration_job_name: migration_job_name,
      feature_category: :database,
      introduced_by_url: introduced_by_url,
      milestone: milestone,
      queued_migration_version: migration_version,
      finalized_by: finalized_by
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

  describe '.entry' do
    it 'returns a single dictionary entry for the given migration job' do
      entry = described_class.entry('TestMigration')
      expect(entry.migration_job_name).to eq('TestMigration')
      expect(entry.finalized_by.to_s).to eq(finalized_by)
    end
  end

  shared_examples 'safely returns bbm attribute' do |attribute|
    it 'returns the attr of the bbm' do
      expect(batched_background_migration.public_send(attribute)).to eq(public_send(attribute))
    end

    it 'returns nothing for non-existing bbm dictionary' do
      expect(described_class.new('random').public_send(attribute)).to be_nil
    end
  end

  describe '#introduced_by_url' do
    it_behaves_like 'safely returns bbm attribute', :introduced_by_url
  end

  describe '#milestone' do
    it_behaves_like 'safely returns bbm attribute', :milestone
  end

  describe '#migration_job_name' do
    it_behaves_like 'safely returns bbm attribute', :migration_job_name
  end

  describe '.checksum' do
    let(:entries) { { c: "d", a: "b" } }

    it 'returns a checksum of the entries' do
      allow(described_class).to receive(:entries).and_return(entries)

      expect(described_class.checksum(skip_memoization: true)).to eq(Digest::SHA256.hexdigest(entries.to_s))
    end
  end
end

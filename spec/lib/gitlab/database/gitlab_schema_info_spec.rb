# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::GitlabSchemaInfo, feature_category: :cell do
  describe '.new' do
    it 'does ensure that name is always symbol' do
      schema_info = described_class.new(name: 'gitlab_main')
      expect(schema_info.name).to eq(:gitlab_main)
    end

    it 'does raise error when using invalid argument' do
      expect { described_class.new(invalid: 'aa') }.to raise_error ArgumentError, /unknown keywords: invalid/
    end
  end

  describe '.load_file' do
    it 'does load YAML file and has file_path specified' do
      file_path = Rails.root.join('db/gitlab_schemas/gitlab_main.yaml')
      schema_info = described_class.load_file(file_path)

      expect(schema_info).not_to be_nil
      expect(schema_info.file_path).to eq(file_path)
    end

    it 'loads YAML file and converts allow_cross_* to hashes' do
      file_path = Rails.root.join('db/gitlab_schemas/gitlab_main.yaml')
      schema_info = described_class.load_file(file_path)

      expect(schema_info.allow_cross_joins).to be_a(Hash)
      expect(schema_info.allow_cross_joins.keys).to include(:gitlab_shared)
    end
  end

  describe '#allow_cross_joins?' do
    it 'returns true when all table schemas are allowed' do
      schema_info = described_class.new(
        name: 'gitlab_main',
        allow_cross_joins: ['gitlab_shared']
      )

      table_schemas = [:gitlab_main, :gitlab_shared]
      all_tables = %w[users postgres_sequences]

      expect(schema_info.allow_cross_joins?(table_schemas, all_tables)).to be(true)
    end

    it 'returns false when denied schemas exist' do
      schema_info = described_class.new(
        name: 'gitlab_main',
        allow_cross_joins: ['gitlab_shared']
      )

      table_schemas = [:gitlab_main, :gitlab_ci]
      all_tables = %w[users ci_table]

      expect(schema_info.allow_cross_joins?(table_schemas, all_tables)).to be(false)
    end

    it 'returns true when only current schema is used' do
      schema_info = described_class.new(
        name: 'gitlab_main',
        allow_cross_joins: []
      )

      table_schemas = [:gitlab_main]
      all_tables = ['users']

      expect(schema_info.allow_cross_joins?(table_schemas, all_tables)).to be(true)
    end
  end

  describe '#allow_cross_transactions?' do
    it 'returns true when all table schemas are allowed' do
      schema_info = described_class.new(
        name: 'gitlab_main',
        allow_cross_transactions: ['gitlab_internal']
      )

      table_schemas = [:gitlab_main, :gitlab_internal]
      all_tables = %w[users schema_migrations]

      expect(schema_info.allow_cross_transactions?(table_schemas, all_tables)).to be(true)
    end

    it 'returns false when denied schemas exist' do
      schema_info = described_class.new(
        name: 'gitlab_main',
        allow_cross_transactions: ['gitlab_internal']
      )

      table_schemas = [:gitlab_main, :gitlab_ci]
      all_tables = %w[users ci_pipeline]

      expect(schema_info.allow_cross_transactions?(table_schemas, all_tables)).to be(false)
    end

    it 'returns true when only current schema is used' do
      schema_info = described_class.new(
        name: 'gitlab_main',
        allow_cross_transactions: []
      )

      table_schemas = [:gitlab_main]
      all_tables = ['users']

      expect(schema_info.allow_cross_transactions?(table_schemas, all_tables)).to be(true)
    end
  end

  describe '#allow_cross_foreign_keys?' do
    it 'returns true when all table schemas are allowed' do
      schema_info = described_class.new(
        name: 'gitlab_main',
        allow_cross_foreign_keys: ['gitlab_main_org']
      )

      table_schemas = [:gitlab_main, :gitlab_main_org]
      all_tables = %w[users namespaces]

      expect(schema_info.allow_cross_foreign_keys?(table_schemas, all_tables)).to be(true)
    end

    it 'returns false when denied schemas exist' do
      schema_info = described_class.new(
        name: 'gitlab_main',
        allow_cross_foreign_keys: ['gitlab_main_org']
      )

      table_schemas = [:gitlab_main, :gitlab_ci]
      all_tables = %w[users ci_pipeline]

      expect(schema_info.allow_cross_foreign_keys?(table_schemas, all_tables)).to be(false)
    end

    it 'returns true when only current schema is used' do
      schema_info = described_class.new(
        name: 'gitlab_main',
        allow_cross_foreign_keys: []
      )

      table_schemas = [:gitlab_main]
      all_tables = ['users']

      expect(schema_info.allow_cross_foreign_keys?(table_schemas, all_tables)).to be(true)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillEnvironmentTiers,
  :migration, schema: 20230616082958, feature_category: :continuous_delivery do
  let!(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let!(:project) { table(:projects).create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }

  let(:migration) do
    described_class.new(
      start_id: 1, end_id: 1000,
      batch_table: :environments, batch_column: :id,
      sub_batch_size: 10, pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    let!(:production) { table(:environments).create!(name: 'production', slug: 'production', project_id: project.id) }
    let!(:staging) { table(:environments).create!(name: 'staging', slug: 'staging', project_id: project.id) }
    let!(:testing) { table(:environments).create!(name: 'testing', slug: 'testing', project_id: project.id) }

    let!(:development) do
      table(:environments).create!(name: 'development', slug: 'development', project_id: project.id)
    end

    let!(:other) { table(:environments).create!(name: 'other', slug: 'other', project_id: project.id) }

    it 'backfill tiers for all environments in range' do
      expect(production.tier).to be_nil
      expect(staging.tier).to be_nil
      expect(testing.tier).to be_nil
      expect(development.tier).to be_nil
      expect(other.tier).to be_nil

      migration.perform

      expect(production.reload.tier).to eq(described_class::PRODUCTION_TIER)
      expect(staging.reload.tier).to eq(described_class::STAGING_TIER)
      expect(testing.reload.tier).to eq(described_class::TESTING_TIER)
      expect(development.reload.tier).to eq(described_class::DEVELOPMENT_TIER)
      expect(other.reload.tier).to eq(described_class::OTHER_TIER)
    end
  end

  # Equivalent to spec/models/environment_spec.rb#guess_tier
  describe 'same behavior with guess tier' do
    using RSpec::Parameterized::TableSyntax

    let(:environment) { table(:environments).create!(name: name, slug: name, project_id: project.id) }

    where(:name, :tier) do
      'review/feature'     | described_class::DEVELOPMENT_TIER
      'review/product'     | described_class::DEVELOPMENT_TIER
      'DEV'                | described_class::DEVELOPMENT_TIER
      'development'        | described_class::DEVELOPMENT_TIER
      'trunk'              | described_class::DEVELOPMENT_TIER
      'dev'                | described_class::DEVELOPMENT_TIER
      'review/app'         | described_class::DEVELOPMENT_TIER
      'PRODUCTION'         | described_class::PRODUCTION_TIER
      'prod'               | described_class::PRODUCTION_TIER
      'prod-east-2'        | described_class::PRODUCTION_TIER
      'us-prod-east'       | described_class::PRODUCTION_TIER
      'fe-production'      | described_class::PRODUCTION_TIER
      'test'               | described_class::TESTING_TIER
      'TEST'               | described_class::TESTING_TIER
      'testing'            | described_class::TESTING_TIER
      'testing-prd'        | described_class::TESTING_TIER
      'acceptance-testing' | described_class::TESTING_TIER
      'production-test'    | described_class::TESTING_TIER
      'test-production'    | described_class::TESTING_TIER
      'QC'                 | described_class::TESTING_TIER
      'qa-env-2'           | described_class::TESTING_TIER
      'gstg'               | described_class::STAGING_TIER
      'staging'            | described_class::STAGING_TIER
      'stage'              | described_class::STAGING_TIER
      'Model'              | described_class::STAGING_TIER
      'MODL'               | described_class::STAGING_TIER
      'Pre-production'     | described_class::STAGING_TIER
      'pre'                | described_class::STAGING_TIER
      'Demo'               | described_class::STAGING_TIER
      'staging'            | described_class::STAGING_TIER
      'pre-prod'           | described_class::STAGING_TIER
      'blue-kit-stage'     | described_class::STAGING_TIER
      'nonprod'            | described_class::STAGING_TIER
      'nonlive'            | described_class::STAGING_TIER
      'non-prod'           | described_class::STAGING_TIER
      'non-live'           | described_class::STAGING_TIER
      'gprd'               | described_class::PRODUCTION_TIER
      'gprd-cny'           | described_class::PRODUCTION_TIER
      'production'         | described_class::PRODUCTION_TIER
      'Production'         | described_class::PRODUCTION_TIER
      'PRODUCTION'         | described_class::PRODUCTION_TIER
      'Production/eu'      | described_class::PRODUCTION_TIER
      'production/eu'      | described_class::PRODUCTION_TIER
      'PRODUCTION/EU'      | described_class::PRODUCTION_TIER
      'productioneu'       | described_class::PRODUCTION_TIER
      'store-produce'      | described_class::PRODUCTION_TIER
      'unproductive'       | described_class::PRODUCTION_TIER
      'production/www.gitlab.com' | described_class::PRODUCTION_TIER
      'prod'               | described_class::PRODUCTION_TIER
      'PROD'               | described_class::PRODUCTION_TIER
      'Live'               | described_class::PRODUCTION_TIER
      'canary'             | described_class::OTHER_TIER
      'other'              | described_class::OTHER_TIER
      'EXP'                | described_class::OTHER_TIER
      'something-else'     | described_class::OTHER_TIER
    end

    with_them do
      it 'backfill tiers for all environments in range' do
        expect(environment.tier).to be_nil

        migration.perform

        expect(environment.reload.tier).to eq(tier)
      end
    end
  end
end

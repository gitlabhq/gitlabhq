# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::MigrationSupport::CiFinishedBuildsConsistencyHelper, feature_category: :fleet_visibility do
  describe '.backfill_in_progress?' do
    subject(:backfill_in_progress?) { described_class.backfill_in_progress? }

    before do
      Rails.cache.delete(described_class::CACHE_KEY)
    end

    context 'when migration does not exist' do
      it { is_expected.to be false }
    end

    context 'when migration exists' do
      let!(:migration) do
        Gitlab::Database::SharedModel.using_connection(Ci::ApplicationRecord.connection) do
          create(
            :batched_background_migration,
            *migration_traits,
            job_class_name: described_class::MIGRATION_NAME,
            table_name: :p_ci_builds,
            column_name: :id,
            gitlab_schema: :gitlab_ci
          )
        end
      end

      using RSpec::Parameterized::TableSyntax

      where(:migration_state, :expected_result) do
        :active     | true
        :paused     | true
        :finalizing | true
        :finished   | false
        :finalized  | false
        :failed     | true
      end

      with_them do
        let(:migration_traits) { [migration_state] }

        it { is_expected.to eq(expected_result) }
      end
    end

    context 'when result is cached' do
      let!(:migration) do
        Gitlab::Database::SharedModel.using_connection(Ci::ApplicationRecord.connection) do
          create(
            :batched_background_migration,
            :active,
            job_class_name: described_class::MIGRATION_NAME,
            table_name: :p_ci_builds,
            column_name: :id,
            gitlab_schema: :gitlab_ci
          )
        end
      end

      it 'caches the result' do
        expect(Rails.cache).to receive(:fetch)
          .with(described_class::CACHE_KEY, expires_in: described_class::CACHE_TTL)
          .and_call_original

        described_class.backfill_in_progress?
      end
    end
  end
end

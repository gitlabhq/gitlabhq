# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe IncreaseGitlabComConcurrentRelationBatchExportLimit, feature_category: :database do
  let(:application_settings_table) { table(:application_settings) }

  let!(:application_settings) { application_settings_table.create! }

  context 'when Gitlab.com? is false' do
    before do
      allow(Gitlab).to receive(:com?).and_return(false)
    end

    it 'does not change the rate limit concurrent_relation_batch_export_limit' do
      disable_migrations_output do
        reversible_migration do |migration|
          migration.before -> {
            expect(application_settings.reload.rate_limits).not_to have_key('concurrent_relation_batch_export_limit')
          }

          migration.after -> {
            expect(application_settings.reload.rate_limits).not_to have_key('concurrent_relation_batch_export_limit')
          }
        end
      end
    end
  end

  context 'when Gitlab.com? is true' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    it 'sets the rate_limits concurrent_relation_batch_export_limit to 10k' do
      disable_migrations_output do
        reversible_migration do |migration|
          migration.before -> {
            expect(application_settings.reload.rate_limits).not_to have_key('concurrent_relation_batch_export_limit')
          }

          migration.after -> {
            expect(application_settings.reload.rate_limits['concurrent_relation_batch_export_limit']).to eq(10_000)
          }
        end
      end
    end

    context 'when there is no application setting' do
      let!(:application_settings) { nil }

      it 'does not fail' do
        disable_migrations_output do
          expect { migrate! }.not_to raise_exception
        end
      end
    end
  end
end

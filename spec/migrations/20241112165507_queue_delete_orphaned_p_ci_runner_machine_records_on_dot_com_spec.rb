# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueDeleteOrphanedPCiRunnerMachineRecordsOnDotCom, migration: :gitlab_ci, feature_category: :fleet_visibility do
  let!(:batched_migration) { described_class::MIGRATION }

  before do
    allow(Gitlab).to receive(:com_except_jh?).and_return(gitlab_com_except_jh?)
  end

  context 'when it is not on GitLab.com' do
    let(:gitlab_com_except_jh?) { false }

    it 'does not schedule a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }
      end
    end
  end

  context 'when it is on GitLab.com' do
    let(:gitlab_com_except_jh?) { true }

    it 'schedules a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }
      end
    end
  end
end

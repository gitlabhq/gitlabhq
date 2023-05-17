# frozen_string_literal: true

require "spec_helper"

require_migration!

RSpec.describe ScheduleIndexToProjectAuthorizationsOnProjectUserAccessLevel, feature_category: :security_policy_management do
  let(:async_index) { Gitlab::Database::AsyncIndexes::PostgresAsyncIndex }
  let(:index_name) { described_class::INDEX_NAME }

  it "schedules the index" do
    reversible_migration do |migration|
      migration.before -> do
        expect(async_index.where(name: index_name).count).to be(0)
      end

      migration.after -> do
        expect(async_index.where(name: index_name).count).to be(1)
      end
    end
  end
end

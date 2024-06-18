# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillUserAchievementsNamespaceId,
  feature_category: :user_profile,
  schema: 20240604073801 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :user_achievements }
    let(:backfill_column) { :namespace_id }
    let(:backfill_via_table) { :achievements }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :achievement_id }
  end
end

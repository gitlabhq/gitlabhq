# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RecommendReviewersAssignSelfHostedMigration,
  migration: :gitlab_main_cell_setting,
  feature_category: :ai_abstraction_layer,
  migration_version: 20261001080749 do
  let(:migration) { described_class.new }
  let(:feature_settings) { table(:ai_feature_settings) }
  let(:self_hosted_model) do
    table(:ai_self_hosted_models).create!(name: 'Test Model', model: 'test-model', endpoint: 'https://example.com')
  end

  def create_source_setting
    feature_settings.create!(
      feature: described_class::SOURCE_FEATURE, provider: 2, ai_self_hosted_model_id: self_hosted_model.id
    )
  end

  describe '#up' do
    it 'copies the duo_agent_platform setting to recommend_reviewers_assign' do
      create_source_setting

      migration.up

      expect(feature_settings.find_by(feature: described_class::TARGET_FEATURE)).to have_attributes(
        provider: 2,
        ai_self_hosted_model_id: self_hosted_model.id
      )
    end

    context 'when a recommend_reviewers_assign setting already exists' do
      let!(:existing_target) { feature_settings.create!(feature: described_class::TARGET_FEATURE, provider: 0) }

      it 'keeps the existing setting' do
        create_source_setting

        migration.up

        expect(existing_target.reload).to have_attributes(provider: 0, ai_self_hosted_model_id: nil)
      end
    end

    context 'when no duo_agent_platform setting exists' do
      it 'does not create a setting' do
        expect { migration.up }.not_to change { feature_settings.count }
      end
    end
  end

  describe '#down' do
    it 'deletes only the recommend_reviewers_assign setting' do
      create_source_setting

      migration.up
      migration.down

      expect(feature_settings.pluck(:feature)).to contain_exactly(described_class::SOURCE_FEATURE)
    end
  end
end

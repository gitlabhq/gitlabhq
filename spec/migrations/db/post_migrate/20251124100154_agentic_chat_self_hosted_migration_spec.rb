# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AgenticChatSelfHostedMigration, migration: :gitlab_main_cell_setting, feature_category: :ai_abstraction_layer, migration_version: 20251124100154 do
  let(:migration) { described_class.new }
  let(:feature_settings) { table(:ai_feature_settings) }
  let(:self_hosted_models) { table(:ai_self_hosted_models) }

  describe '#up' do
    context 'when a record with feature=16 exists' do
      let!(:self_hosted_model) do
        self_hosted_models.create!(
          name: 'Test Model',
          model: 'test-model',
          endpoint: 'https://example.com'
        )
      end

      let!(:source_record) do
        feature_settings.create!(
          feature: described_class::SOURCE_FEATURE,
          provider: 2, # self_hosted
          ai_self_hosted_model_id: self_hosted_model.id,
          created_at: 1.day.ago,
          updated_at: 1.hour.ago
        )
      end

      it 'creates a new record with feature=17' do
        expect { migration.up }.to change { feature_settings.count }.by(1)
      end

      it 'copies all attributes except feature and timestamps' do
        migration.up

        new_record = feature_settings.find_by(feature: described_class::TARGET_FEATURE)
        expect(new_record).to be_present
        expect(new_record).to have_attributes(
          feature: described_class::TARGET_FEATURE,
          provider: source_record.provider,
          ai_self_hosted_model_id: source_record.ai_self_hosted_model_id
        )
        expect(new_record.created_at).to be_present
        expect(new_record.updated_at).to be_present
        expect(new_record.created_at).not_to eq(source_record.created_at)
        expect(new_record.updated_at).not_to eq(source_record.updated_at)
      end

      it 'does not modify the source record' do
        source_record.reload
        original_created_at = source_record.created_at
        original_updated_at = source_record.updated_at

        migration.up

        source_record.reload
        expect(source_record.created_at).to eq(original_created_at)
        expect(source_record.updated_at).to eq(original_updated_at)
        expect(source_record.feature).to eq(described_class::SOURCE_FEATURE)
      end

      context 'when target record already exists' do
        let!(:existing_target) do
          feature_settings.create!(
            feature: described_class::TARGET_FEATURE,
            provider: 0, # disabled
            ai_self_hosted_model_id: nil
          )
        end

        it 'does not create a duplicate record' do
          expect { migration.up }.not_to change { feature_settings.count }
        end

        it 'does not modify the existing target record' do
          original_provider = existing_target.provider
          original_model_id = existing_target.ai_self_hosted_model_id

          migration.up

          existing_target.reload
          expect(existing_target.provider).to eq(original_provider)
          expect(existing_target.ai_self_hosted_model_id).to eq(original_model_id)
        end
      end
    end

    context 'when no record with feature=16 exists' do
      it 'does not create any records' do
        expect { migration.up }.not_to change { feature_settings.count }
      end

      it 'does not raise an error' do
        expect { migration.up }.not_to raise_error
      end
    end

    context 'when source record has different provider values' do
      let!(:self_hosted_model) do
        self_hosted_models.create!(
          name: 'Test Model',
          model: 'test-model',
          endpoint: 'https://example.com'
        )
      end

      [0, 1, 2, 3].each do |provider_value|
        context "with provider=#{provider_value}" do
          let!(:source_record) do
            feature_settings.create!(
              feature: described_class::SOURCE_FEATURE,
              provider: provider_value,
              ai_self_hosted_model_id: provider_value == 2 ? self_hosted_model.id : nil
            )
          end

          it 'copies the provider value correctly' do
            migration.up

            new_record = feature_settings.find_by(feature: described_class::TARGET_FEATURE)
            expect(new_record.provider).to eq(provider_value)
          end
        end
      end
    end
  end

  describe '#down' do
    let!(:self_hosted_model) do
      self_hosted_models.create!(
        name: 'Test Model',
        model: 'test-model',
        endpoint: 'https://example.com'
      )
    end

    let!(:source_record) do
      feature_settings.create!(
        feature: described_class::SOURCE_FEATURE,
        provider: 2,
        ai_self_hosted_model_id: self_hosted_model.id
      )
    end

    let!(:target_record) do
      feature_settings.create!(
        feature: described_class::TARGET_FEATURE,
        provider: 2,
        ai_self_hosted_model_id: self_hosted_model.id
      )
    end

    it 'deletes the record with feature=17' do
      expect { migration.down }.to change { feature_settings.count }.by(-1)
      expect(feature_settings.exists?(feature: described_class::TARGET_FEATURE)).to be(false)
    end

    it 'does not delete the source record' do
      migration.down
      expect(feature_settings.exists?(feature: described_class::SOURCE_FEATURE)).to be(true)
    end

    context 'when target record does not exist' do
      before do
        target_record.destroy!
      end

      it 'does not raise an error' do
        expect { migration.down }.not_to raise_error
      end
    end
  end
end

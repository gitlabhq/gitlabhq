# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AgenticChatSelfManagedMigration, migration: :gitlab_main_cell_setting, feature_category: :ai_abstraction_layer, migration_version: 20251124110051 do
  let(:migration) { described_class.new }
  let(:instance_feature_settings) { table(:instance_model_selection_feature_settings) }

  describe '#up' do
    context 'when a record with feature=16 exists' do
      let!(:source_record) do
        instance_feature_settings.create!(
          feature: described_class::SOURCE_FEATURE,
          offered_model_ref: 'claude-3-7-sonnet-20250219',
          offered_model_name: 'Claude Sonnet 3.7',
          created_at: 1.day.ago,
          updated_at: 1.hour.ago
        )
      end

      it 'creates a new record with feature=17' do
        expect { migration.up }.to change { instance_feature_settings.count }.by(1)
      end

      it 'copies all attributes except feature and timestamps' do
        migration.up

        new_record = instance_feature_settings.find_by(feature: described_class::TARGET_FEATURE)
        expect(new_record).to be_present
        expect(new_record).to have_attributes(
          feature: described_class::TARGET_FEATURE,
          offered_model_ref: source_record.offered_model_ref,
          offered_model_name: source_record.offered_model_name
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
          instance_feature_settings.create!(
            feature: described_class::TARGET_FEATURE,
            offered_model_ref: 'different-model',
            offered_model_name: 'Different Model'
          )
        end

        it 'does not create a duplicate record' do
          expect { migration.up }.not_to change { instance_feature_settings.count }
        end

        it 'does not modify the existing target record' do
          original_ref = existing_target.offered_model_ref
          original_name = existing_target.offered_model_name

          migration.up

          existing_target.reload
          expect(existing_target.offered_model_ref).to eq(original_ref)
          expect(existing_target.offered_model_name).to eq(original_name)
        end
      end
    end

    context 'when no record with feature=16 exists' do
      it 'does not create any records' do
        expect { migration.up }.not_to change { instance_feature_settings.count }
      end

      it 'does not raise an error' do
        expect { migration.up }.not_to raise_error
      end
    end

    context 'when source record has nil values' do
      let!(:source_record) do
        instance_feature_settings.create!(
          feature: described_class::SOURCE_FEATURE,
          offered_model_ref: nil,
          offered_model_name: nil
        )
      end

      it 'copies nil values correctly' do
        migration.up

        new_record = instance_feature_settings.find_by(feature: described_class::TARGET_FEATURE)
        expect(new_record).to be_present
        expect(new_record.offered_model_ref).to be_nil
        expect(new_record.offered_model_name).to be_nil
      end
    end

    context 'when source record has empty string values' do
      let!(:source_record) do
        instance_feature_settings.create!(
          feature: described_class::SOURCE_FEATURE,
          offered_model_ref: '',
          offered_model_name: ''
        )
      end

      it 'copies empty string values correctly' do
        migration.up

        new_record = instance_feature_settings.find_by(feature: described_class::TARGET_FEATURE)
        expect(new_record).to be_present
        expect(new_record.offered_model_ref).to eq('')
        expect(new_record.offered_model_name).to eq('')
      end
    end
  end

  describe '#down' do
    let!(:source_record) do
      instance_feature_settings.create!(
        feature: described_class::SOURCE_FEATURE,
        offered_model_ref: 'claude-3-7-sonnet-20250219',
        offered_model_name: 'Claude Sonnet 3.7'
      )
    end

    let!(:target_record) do
      instance_feature_settings.create!(
        feature: described_class::TARGET_FEATURE,
        offered_model_ref: 'claude-3-7-sonnet-20250219',
        offered_model_name: 'Claude Sonnet 3.7'
      )
    end

    it 'deletes the record with feature=17' do
      expect { migration.down }.to change { instance_feature_settings.count }.by(-1)
      expect(instance_feature_settings.exists?(feature: described_class::TARGET_FEATURE)).to be(false)
    end

    it 'does not delete the source record' do
      migration.down
      expect(instance_feature_settings.exists?(feature: described_class::SOURCE_FEATURE)).to be(true)
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

# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AgenticChatDotComMigration, migration: :gitlab_main_org, feature_category: :ai_abstraction_layer, migration_version: 20251124111705 do
  let(:migration) { described_class.new }
  let(:namespace_feature_settings) { table(:ai_namespace_feature_settings) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }
  let!(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  describe '#up' do
    context 'when records with feature=16 exist' do
      let!(:namespace1) do
        namespaces.create!(name: 'namespace1', path: 'namespace1', type: 'Group', organization_id: organization.id)
      end

      let!(:namespace2) do
        namespaces.create!(name: 'namespace2', path: 'namespace2', type: 'Group', organization_id: organization.id)
      end

      let!(:namespace3) do
        namespaces.create!(name: 'namespace3', path: 'namespace3', type: 'Group', organization_id: organization.id)
      end

      let!(:source_record1) do
        namespace_feature_settings.create!(
          namespace_id: namespace1.id,
          feature: described_class::SOURCE_FEATURE,
          offered_model_ref: 'claude-3-7-sonnet-20250219',
          offered_model_name: 'Claude Sonnet 3.7',
          created_at: 1.day.ago,
          updated_at: 1.hour.ago
        )
      end

      let!(:source_record2) do
        namespace_feature_settings.create!(
          namespace_id: namespace2.id,
          feature: described_class::SOURCE_FEATURE,
          offered_model_ref: 'claude_sonnet_3_5',
          offered_model_name: 'Claude Sonnet 3.5',
          created_at: 2.days.ago,
          updated_at: 2.hours.ago
        )
      end

      let!(:source_record3) do
        namespace_feature_settings.create!(
          namespace_id: namespace3.id,
          feature: described_class::SOURCE_FEATURE,
          offered_model_ref: nil,
          offered_model_name: nil
        )
      end

      it 'creates new records with feature=17 for each namespace' do
        expect { migration.up }.to change { namespace_feature_settings.count }.by(3)
      end

      it 'copies all attributes except feature and timestamps' do
        migration.up

        new_record1 = namespace_feature_settings.find_by(namespace_id: namespace1.id,
          feature: described_class::TARGET_FEATURE)
        expect(new_record1).to be_present
        expect(new_record1).to have_attributes(
          namespace_id: namespace1.id,
          feature: described_class::TARGET_FEATURE,
          offered_model_ref: source_record1.offered_model_ref,
          offered_model_name: source_record1.offered_model_name
        )
        expect(new_record1.created_at).to be_present
        expect(new_record1.updated_at).to be_present
        expect(new_record1.created_at).not_to eq(source_record1.created_at)
        expect(new_record1.updated_at).not_to eq(source_record1.updated_at)

        new_record2 = namespace_feature_settings.find_by(namespace_id: namespace2.id,
          feature: described_class::TARGET_FEATURE)
        expect(new_record2).to be_present
        expect(new_record2.offered_model_ref).to eq(source_record2.offered_model_ref)
        expect(new_record2.offered_model_name).to eq(source_record2.offered_model_name)

        new_record3 = namespace_feature_settings.find_by(namespace_id: namespace3.id,
          feature: described_class::TARGET_FEATURE)
        expect(new_record3).to be_present
        expect(new_record3.offered_model_ref).to be_nil
        expect(new_record3.offered_model_name).to be_nil
      end

      it 'does not modify the source records' do
        source_record1.reload
        original_created_at = source_record1.created_at
        original_updated_at = source_record1.updated_at

        migration.up

        source_record1.reload
        expect(source_record1.created_at).to eq(original_created_at)
        expect(source_record1.updated_at).to eq(original_updated_at)
        expect(source_record1.feature).to eq(described_class::SOURCE_FEATURE)
      end

      context 'when target record already exists for a namespace' do
        let!(:existing_target) do
          namespace_feature_settings.create!(
            namespace_id: namespace1.id,
            feature: described_class::TARGET_FEATURE,
            offered_model_ref: 'different-model',
            offered_model_name: 'Different Model'
          )
        end

        it 'does not create a duplicate record for that namespace' do
          expect { migration.up }.to change { namespace_feature_settings.count }.by(2) # Only namespace2 and namespace3
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

      context 'when processing more than BATCH_SIZE records' do
        before do
          # Stub BATCH_SIZE to a smaller number for testing
          stub_const("#{described_class}::BATCH_SIZE", 5)

          # Create enough records to require multiple batches (8 records = 2 batches of 5)
          (4..11).each do |i|
            namespace = namespaces.create!(name: "namespace#{i}", path: "namespace#{i}", type: 'Group',
              organization_id: organization.id)
            namespace_feature_settings.create!(
              namespace_id: namespace.id,
              feature: described_class::SOURCE_FEATURE,
              offered_model_ref: "model-ref-#{i}",
              offered_model_name: "Model Name #{i}"
            )
          end
        end

        it 'processes all records across multiple batches' do
          source_count = namespace_feature_settings.where(feature: described_class::SOURCE_FEATURE).count
          expect { migration.up }.to change {
            namespace_feature_settings.where(feature: described_class::TARGET_FEATURE).count
          }.by(source_count)
        end
      end

      context 'when records with other feature values exist' do
        let!(:other_feature_record) do
          namespace_feature_settings.create!(
            namespace_id: namespace1.id,
            feature: 0, # different feature
            offered_model_ref: 'other-model',
            offered_model_name: 'Other Model'
          )
        end

        it 'does not process records with other feature values' do
          migration.up
          # Should only create records for feature=16, not feature=0
          expect(namespace_feature_settings.where(feature: 0).count).to eq(1)
        end
      end
    end

    context 'when no records with feature=16 exist' do
      it 'does not create any records' do
        expect { migration.up }.not_to change { namespace_feature_settings.count }
      end

      it 'does not raise an error' do
        expect { migration.up }.not_to raise_error
      end
    end

    context 'when source records have empty string values' do
      let!(:namespace) do
        namespaces.create!(name: 'namespace', path: 'namespace', type: 'Group', organization_id: organization.id)
      end

      let!(:source_record) do
        namespace_feature_settings.create!(
          namespace_id: namespace.id,
          feature: described_class::SOURCE_FEATURE,
          offered_model_ref: '',
          offered_model_name: ''
        )
      end

      it 'copies empty string values correctly' do
        migration.up

        new_record = namespace_feature_settings.find_by(namespace_id: namespace.id,
          feature: described_class::TARGET_FEATURE)
        expect(new_record).to be_present
        expect(new_record.offered_model_ref).to eq('')
        expect(new_record.offered_model_name).to eq('')
      end
    end
  end

  describe '#down' do
    let!(:namespace1) do
      namespaces.create!(name: 'namespace1', path: 'namespace1', type: 'Group', organization_id: organization.id)
    end

    let!(:namespace2) do
      namespaces.create!(name: 'namespace2', path: 'namespace2', type: 'Group', organization_id: organization.id)
    end

    let!(:source_record1) do
      namespace_feature_settings.create!(
        namespace_id: namespace1.id,
        feature: described_class::SOURCE_FEATURE,
        offered_model_ref: 'claude-3-7-sonnet-20250219',
        offered_model_name: 'Claude Sonnet 3.7'
      )
    end

    let!(:target_record1) do
      namespace_feature_settings.create!(
        namespace_id: namespace1.id,
        feature: described_class::TARGET_FEATURE,
        offered_model_ref: 'claude-3-7-sonnet-20250219',
        offered_model_name: 'Claude Sonnet 3.7'
      )
    end

    let!(:target_record2) do
      namespace_feature_settings.create!(
        namespace_id: namespace2.id,
        feature: described_class::TARGET_FEATURE,
        offered_model_ref: 'claude_sonnet_3_5',
        offered_model_name: 'Claude Sonnet 3.5'
      )
    end

    it 'deletes all records with feature=17' do
      expect { migration.down }.to change { namespace_feature_settings.count }.by(-2)
      expect(namespace_feature_settings.exists?(feature: described_class::TARGET_FEATURE)).to be(false)
    end

    it 'does not delete the source records' do
      migration.down
      expect(namespace_feature_settings.exists?(namespace_id: namespace1.id,
        feature: described_class::SOURCE_FEATURE)).to be(true)
    end

    context 'when no target records exist' do
      before do
        target_record1.destroy!
        target_record2.destroy!
      end

      it 'does not raise an error' do
        expect { migration.down }.not_to raise_error
      end
    end
  end
end

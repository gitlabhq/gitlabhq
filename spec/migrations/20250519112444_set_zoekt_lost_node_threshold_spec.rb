# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SetZoektLostNodeThreshold, feature_category: :global_search do
  let(:migration) { described_class.new }
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    context 'when zoekt_auto_delete_lost_nodes is set to false' do
      before do
        application_settings.create!(zoekt_settings: { zoekt_auto_delete_lost_nodes: false })
      end

      it 'sets zoekt_lost_node_threshold to 0' do
        expect { migration.up }.to change {
          application_settings.first.zoekt_settings
        }.from(
          { 'zoekt_auto_delete_lost_nodes' => false }
        ).to(
          { 'zoekt_auto_delete_lost_nodes' => false, 'zoekt_lost_node_threshold' => '0' }
        )
      end
    end

    context 'when zoekt_auto_delete_lost_nodes is not set to false' do
      before do
        application_settings.create!(zoekt_settings: { zoekt_auto_delete_lost_nodes: true })
      end

      it 'does not modify the settings' do
        expect { migration.up }.not_to change { application_settings.first.zoekt_settings }
      end
    end

    context 'when zoekt_auto_delete_lost_nodes is not present' do
      before do
        application_settings.create!(zoekt_settings: { zoekt_indexing_enabled: true })
      end

      it 'does not modify the settings' do
        expect { migration.up }.not_to change { application_settings.first.zoekt_settings }
      end
    end
  end

  describe '#down' do
    context 'when zoekt_lost_node_threshold is set to 0' do
      before do
        application_settings.create!(zoekt_settings: { zoekt_lost_node_threshold: '0' })
      end

      it 'sets zoekt_auto_delete_lost_nodes to false and removes zoekt_lost_node_threshold' do
        migration.down

        # Verify the field was removed and auto_delete was set to false
        updated_settings = application_settings.first.reload
        expect(updated_settings.zoekt_settings).to eq({ 'zoekt_auto_delete_lost_nodes' => false })
        expect(updated_settings.zoekt_settings).not_to have_key('zoekt_lost_node_threshold')
      end
    end

    context 'when zoekt_lost_node_threshold is set to 12h' do
      before do
        application_settings.create!(zoekt_settings: { zoekt_lost_node_threshold: '12h' })
      end

      it 'sets zoekt_auto_delete_lost_nodes to true and removes zoekt_lost_node_threshold' do
        migration.down

        # Verify the field was removed and auto_delete was set to true
        updated_settings = application_settings.first.reload
        expect(updated_settings.zoekt_settings).to eq({ 'zoekt_auto_delete_lost_nodes' => true })
        expect(updated_settings.zoekt_settings).not_to have_key('zoekt_lost_node_threshold')
      end
    end

    context 'when zoekt_lost_node_threshold is set to a non-default value' do
      before do
        application_settings.create!(zoekt_settings: { zoekt_lost_node_threshold: '24h' })
      end

      it 'sets zoekt_auto_delete_lost_nodes to true and removes zoekt_lost_node_threshold' do
        migration.down

        # Verify the field was removed and auto_delete was set to true
        updated_settings = application_settings.first.reload
        expect(updated_settings.zoekt_settings).to eq({ 'zoekt_auto_delete_lost_nodes' => true })
        expect(updated_settings.zoekt_settings).not_to have_key('zoekt_lost_node_threshold')
      end
    end

    context 'when zoekt_lost_node_threshold is not present' do
      before do
        application_settings.create!(zoekt_settings: { zoekt_indexing_enabled: true })
      end

      it 'does not modify the settings' do
        original_settings = application_settings.first.zoekt_settings.dup

        migration.down

        updated_settings = application_settings.first.reload.zoekt_settings
        expect(updated_settings).to eq(original_settings)
      end
    end
  end
end

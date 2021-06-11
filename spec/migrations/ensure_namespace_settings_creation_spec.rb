# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EnsureNamespaceSettingsCreation do
  context 'when there are namespaces without namespace settings' do
    let(:namespaces) { table(:namespaces) }
    let(:namespace_settings) { table(:namespace_settings) }
    let!(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
    let!(:namespace_2) { namespaces.create!(name: 'gitlab', path: 'gitlab-org2') }

    it 'migrates namespaces without namespace_settings' do
      stub_const("#{described_class.name}::BATCH_SIZE", 2)

      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(described_class::MIGRATION)
            .to be_scheduled_delayed_migration(2.minutes.to_i, namespace.id, namespace_2.id)
        end
      end
    end

    it 'schedules migrations in batches' do
      stub_const("#{described_class.name}::BATCH_SIZE", 2)

      namespace_3 = namespaces.create!(name: 'gitlab', path: 'gitlab-org3')
      namespace_4 = namespaces.create!(name: 'gitlab', path: 'gitlab-org4')

      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(described_class::MIGRATION)
            .to be_scheduled_delayed_migration(2.minutes.to_i, namespace.id, namespace_2.id)
          expect(described_class::MIGRATION)
            .to be_scheduled_delayed_migration(4.minutes.to_i, namespace_3.id, namespace_4.id)
        end
      end
    end
  end
end

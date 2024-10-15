# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe LockDuoFeaturesEnabledUpdate, feature_category: :ai_abstraction_layer do
  let(:namespaces) { table(:namespaces) }
  let(:namespace_settings) { table(:namespace_settings) }

  before do
    namespaces.create!(name: 'test', path: 'test')

    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:add_concurrent_index).and_return(true)
    end
    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:remove_concurrent_index).and_return(true)
    end
    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:update_column_in_batches).and_yield(namespace_settings)
    end
  end

  it 'correctly updates lock_duo_features_enabled' do
    namespace = namespaces.first
    namespace_settings.create!(
      namespace_id: namespace.id,
      duo_features_enabled: true,
      lock_duo_features_enabled: true
    )

    expect(namespace_settings.where(duo_features_enabled: true, lock_duo_features_enabled: true).count).to eq(1)

    migrate!

    expect(namespace_settings.where(duo_features_enabled: true, lock_duo_features_enabled: false).count).to eq(1)
    expect(namespace_settings.where(duo_features_enabled: true, lock_duo_features_enabled: true).count).to eq(0)
  end

  it 'does not update records where duo_features_enabled is false' do
    namespace = namespaces.first
    namespace_settings.create!(
      namespace_id: namespace.id,
      duo_features_enabled: false,
      lock_duo_features_enabled: true
    )

    expect(namespace_settings.where(duo_features_enabled: false, lock_duo_features_enabled: true).count).to eq(1)

    migrate!

    expect(namespace_settings.where(duo_features_enabled: false, lock_duo_features_enabled: true).count).to eq(1)
  end

  it 'does not update records where lock_duo_features_enabled is already false' do
    namespace = namespaces.first
    namespace_settings.create!(
      namespace_id: namespace.id,
      duo_features_enabled: true,
      lock_duo_features_enabled: false
    )

    expect(namespace_settings.where(duo_features_enabled: true, lock_duo_features_enabled: false).count).to eq(1)

    migrate!

    expect(namespace_settings.where(duo_features_enabled: true, lock_duo_features_enabled: false).count).to eq(1)
  end

  it 'handles multiple records correctly' do
    namespace1 = namespaces.create!(name: 'test1', path: 'test1')
    namespace2 = namespaces.create!(name: 'test2', path: 'test2')

    namespace_settings.create!(
      namespace_id: namespace1.id,
      duo_features_enabled: true,
      lock_duo_features_enabled: true
    )
    namespace_settings.create!(
      namespace_id: namespace2.id,
      duo_features_enabled: true,
      lock_duo_features_enabled: true
    )

    expect(namespace_settings.where(duo_features_enabled: true, lock_duo_features_enabled: true).count).to eq(2)

    migrate!

    expect(namespace_settings.where(duo_features_enabled: true, lock_duo_features_enabled: false).count).to eq(2)
    expect(namespace_settings.where(duo_features_enabled: true, lock_duo_features_enabled: true).count).to eq(0)
  end

  describe '#down' do
    it 'does not modify any records' do
      namespace = namespaces.first
      namespace_settings.create!(
        namespace_id: namespace.id,
        duo_features_enabled: true,
        lock_duo_features_enabled: false
      )

      expect do
        described_class.new.down
      end.not_to change { namespace_settings.first }
    end
  end
end

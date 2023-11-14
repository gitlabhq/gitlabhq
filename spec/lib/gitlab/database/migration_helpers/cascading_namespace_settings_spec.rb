# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings do
  let(:migration) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  describe '#add_cascading_namespace_setting' do
    it 'creates the required columns', :aggregate_failures do
      expect(migration).to receive(:add_column).with(:namespace_settings, :some_setting, :integer, null: true, default: nil)
      expect(migration).to receive(:add_column).with(:namespace_settings, :lock_some_setting, :boolean, null: false, default: false)

      expect(migration).to receive(:add_column).with(:application_settings, :some_setting, :integer, null: false, default: 5)
      expect(migration).to receive(:add_column).with(:application_settings, :lock_some_setting, :boolean, null: false, default: false)

      migration.add_cascading_namespace_setting(:some_setting, :integer, null: false, default: 5)
    end

    context 'when columns already exist' do
      before do
        migration.add_column(:namespace_settings, :cascading_setting, :integer)
        migration.add_column(:application_settings, :lock_cascading_setting, :boolean)
      end

      it 'raises an error when some columns already exist' do
        expect do
          migration.add_cascading_namespace_setting(:cascading_setting, :integer)
        end.to raise_error %r{Existing columns: namespace_settings.cascading_setting, application_settings.lock_cascading_setting}
      end
    end
  end

  describe '#remove_cascading_namespace_setting' do
    before do
      allow(migration).to receive(:column_exists?).and_return(true)
    end

    it 'removes the columns', :aggregate_failures do
      expect(migration).to receive(:remove_column).with(:namespace_settings, :some_setting)
      expect(migration).to receive(:remove_column).with(:namespace_settings, :lock_some_setting)

      expect(migration).to receive(:remove_column).with(:application_settings, :some_setting)
      expect(migration).to receive(:remove_column).with(:application_settings, :lock_some_setting)

      migration.remove_cascading_namespace_setting(:some_setting)
    end
  end
end

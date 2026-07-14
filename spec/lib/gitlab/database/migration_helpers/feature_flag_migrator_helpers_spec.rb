# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::FeatureFlagMigratorHelpers, feature_category: :database do
  include Database::TableSchemaHelpers
  include Database::TriggerHelpers
  include MigrationsHelpers

  let(:feature_flag_name) { 'test_feature_flag' }
  let_it_be(:application_settings) { table(:application_settings) }
  let_it_be(:features) { table(:features) }
  let_it_be(:feature_gates) { table(:feature_gates) }

  let(:model) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  before do
    allow(model).to receive(:puts)
  end

  shared_examples 'raises an error' do |argument_error_message|
    it 'raises an ArgumentError' do
      expect { subject }.to raise_error(ArgumentError, argument_error_message)
    end
  end

  describe '#up_migrate_to_setting' do
    using RSpec::Parameterized::TableSyntax

    let(:setting_name) { :invisible_captcha_enabled }
    let(:default_enabled) { false }

    subject(:up_migrate_to_setting) do
      model.up_migrate_to_setting(feature_flag_name:, setting_name:, default_enabled:)
    end

    where(:default_enabled, :feature_flag_setting, :expected_application_setting) do
      true  | nil   | true
      true  | true  | true
      true  | false | false
      false | nil   | false
      false | true  | true
      false | false | false
    end

    with_them do
      before do
        application_settings.create!

        features.create!(key: feature_flag_name) unless feature_flag_setting.nil?

        feature_gates.create!(feature_key: feature_flag_name, key: 'boolean', value: 'true') if feature_flag_setting
      end

      it 'sets the expected value in the application settings column' do
        up_migrate_to_setting

        expect(application_settings.last.send(setting_name)).to eq(expected_application_setting)
      end
    end

    context 'when feature_flag_name is nil' do
      let(:feature_flag_name) { nil }

      it_behaves_like 'raises an error', 'feature_flag_name, setting_name, and default_enabled are required'
    end

    context 'when setting_name is nil' do
      let(:setting_name) { nil }

      it_behaves_like 'raises an error', 'feature_flag_name, setting_name, and default_enabled are required'
    end

    context 'when default_enabled is nil' do
      let(:default_enabled) { nil }

      it_behaves_like 'raises an error', 'feature_flag_name, setting_name, and default_enabled are required'
    end

    context 'when default_enabled is not a boolean value' do
      let(:default_enabled) { 1 }

      it_behaves_like 'raises an error', 'default_enabled must be a boolean'
    end
  end

  describe '#down_migrate_to_setting' do
    using RSpec::Parameterized::TableSyntax

    let(:default_enabled) { false }
    let(:setting_name) { :invisible_captcha_enabled }

    subject(:down_migrate_to_setting) do
      model.down_migrate_to_setting(setting_name:, default_enabled:)
    end

    where(:default_enabled, :application_setting, :expected_application_setting) do
      true | true | true
      true | false | true
      false | true | false
      false | false | false
    end

    with_them do
      before do
        application_settings.create!(setting_name => application_setting)
      end

      it 'sets the expected value in the application settings column' do
        down_migrate_to_setting

        expect(application_settings.last.send(setting_name)).to eq(expected_application_setting)
      end
    end

    context 'when setting_name is nil' do
      let(:setting_name) { nil }

      it_behaves_like 'raises an error', 'setting_name and default_enabled are required'
    end

    context 'when default_enabled is nil' do
      let(:default_enabled) { nil }

      it_behaves_like 'raises an error', 'setting_name and default_enabled are required'
    end

    context 'when default_enabled is not a boolean value' do
      let(:default_enabled) { 1 }

      it_behaves_like 'raises an error', 'default_enabled must be a boolean'
    end
  end

  describe '#up_migrate_to_jsonb_setting' do
    using RSpec::Parameterized::TableSyntax

    let(:default_enabled) { true }
    let(:jsonb_column_name) { :clickhouse }
    let(:setting_name) { :use_clickhouse_for_analytics }

    subject(:up_migrate_to_jsonb_setting) do
      model.up_migrate_to_jsonb_setting(feature_flag_name:, setting_name:,
        jsonb_column_name:, default_enabled:)
    end

    where(:default_enabled, :feature_flag_setting, :expected_application_setting) do
      true | nil | true
      true | true | true
      true | false | false
      false | nil | false
      false | true | true
      false | false | false
    end

    with_them do
      before do
        application_settings.create!

        features.create!(key: feature_flag_name) unless feature_flag_setting.nil?

        feature_gates.create!(feature_key: feature_flag_name, key: 'boolean', value: 'true') if feature_flag_setting
      end

      it 'sets the expected value in the application settings jsonb column' do
        up_migrate_to_jsonb_setting

        jsonb_column = application_settings.last.send(jsonb_column_name).with_indifferent_access
        expect(jsonb_column[setting_name]).to eq(expected_application_setting)
      end
    end

    context 'when feature_flag_name is nil' do
      let(:feature_flag_name) { nil }

      it_behaves_like 'raises an error',
        'feature_flag_name, jsonb_column_name, setting_name, and default_enabled are required'
    end

    context 'when setting_name is nil' do
      let(:setting_name) { nil }

      it_behaves_like 'raises an error',
        'feature_flag_name, jsonb_column_name, setting_name, and default_enabled are required'
    end

    context 'when jsonb_column_name is nil' do
      let(:jsonb_column_name) { nil }

      it_behaves_like 'raises an error',
        'feature_flag_name, jsonb_column_name, setting_name, and default_enabled are required'
    end

    context 'when default_enabled is nil' do
      let(:default_enabled) { nil }

      it_behaves_like 'raises an error',
        'feature_flag_name, jsonb_column_name, setting_name, and default_enabled are required'
    end

    context 'when default_enabled is not a boolean value' do
      let(:default_enabled) { 1 }

      it_behaves_like 'raises an error', 'default_enabled must be a boolean'
    end
  end

  describe '#down_migrate_to_jsonb_setting' do
    using RSpec::Parameterized::TableSyntax

    let(:jsonb_column_name) { :clickhouse }
    let(:feature_flag_setting) { true }
    let(:setting_name) { :use_clickhouse_for_analytics }

    subject(:down_migrate_to_jsonb_setting) do
      model.down_migrate_to_jsonb_setting(setting_name:, jsonb_column_name:)
    end

    where(:default_enabled, :application_setting) do
      true | true
      true | false
      false | true
      false | false
    end

    with_them do
      before do
        application_settings.create!
        features.create!(key: feature_flag_name)
        feature_gates.create!(feature_key: feature_flag_name, key: 'boolean', value: 'true')
      end

      it 'sets the expected value in the application settings jsonb column' do
        model.up_migrate_to_jsonb_setting(feature_flag_name:, setting_name:,
          jsonb_column_name:, default_enabled:)
        jsonb_column = application_settings.last.send(jsonb_column_name).with_indifferent_access
        expect(jsonb_column[setting_name]).to eq(feature_flag_setting)

        down_migrate_to_jsonb_setting
        jsonb_column = application_settings.last.send(jsonb_column_name).with_indifferent_access
        expect(jsonb_column[setting_name]).to be_nil
      end
    end

    context 'when setting_name is nil' do
      let(:setting_name) { nil }

      it_behaves_like 'raises an error', 'setting_name and jsonb_column_name are required'
    end

    context 'when jsonb_column_name is nil' do
      let(:jsonb_column_name) { nil }

      it_behaves_like 'raises an error', 'setting_name and jsonb_column_name are required'
    end
  end
end

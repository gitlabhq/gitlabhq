# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateMaxTotalYamlSizeBytesValue, feature_category: :pipeline_composition do
  let(:application_setting) { table(:application_settings) }

  describe '#up' do
    it 'updates the default value from 1MB to 2MB' do
      application_setting.create!(max_yaml_size_bytes: 1.megabyte)

      migrate!

      expect(application_setting.first.max_yaml_size_bytes).to eq(2.megabytes)
    end

    it 'increases non-default value by 20%' do
      custom_value = 5.megabytes
      application_setting.create!(max_yaml_size_bytes: custom_value)

      migrate!

      expect(application_setting.first.max_yaml_size_bytes).to eq((custom_value * 1.2).to_i)
    end

    it 'does not change values that are already 2MB' do
      application_setting.create!(max_yaml_size_bytes: 2.megabytes)

      migrate!

      expect(application_setting.first.max_yaml_size_bytes).to eq(2.megabytes)
    end

    it 'sets the value to max integer when 20% increase exceeds max int' do
      max_int = 2147483647
      custom_value = (max_int / 1.2).to_i + 1
      application_setting.create!(max_yaml_size_bytes: custom_value)

      migrate!

      expect(application_setting.first.max_yaml_size_bytes).to eq(max_int)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateCiMaxTotalYamlSizeBytesNewDefaultValue, feature_category: :pipeline_composition do
  let(:application_setting) { table(:application_settings) }

  describe '#up' do
    it 'updates ci_max_total_yaml_size_bytes to max_yaml_size_bytes * ci_max_includes' do
      application_setting.create!(max_yaml_size_bytes: 2.megabytes, ci_max_includes: 50)

      migrate!

      expect(application_setting.first.ci_max_total_yaml_size_bytes).to eq(100.megabytes)
    end

    it 'caps ci_max_total_yaml_size_bytes at 2147483647 bytes' do
      application_setting.create!(max_yaml_size_bytes: 50.megabytes, ci_max_includes: 100)

      migrate!

      expect(application_setting.first.ci_max_total_yaml_size_bytes).to eq(2147483647)
    end
  end
end

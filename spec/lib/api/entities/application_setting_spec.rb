# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::ApplicationSetting do
  let_it_be(:application_setting, reload: true) { create(:application_setting) }

  subject(:output) { described_class.new(application_setting).as_json }

  context 'housekeeping_bitmaps_enabled usage is deprecated and always enabled' do
    before do
      application_setting.housekeeping_bitmaps_enabled = housekeeping_bitmaps_enabled
    end

    context 'when housekeeping_bitmaps_enabled db column is false' do
      let(:housekeeping_bitmaps_enabled) { false }

      it 'returns true' do
        expect(subject[:housekeeping_bitmaps_enabled]).to eq(true)
      end
    end

    context 'when housekeeping_bitmaps_enabled db column is true' do
      let(:housekeeping_bitmaps_enabled) { false }

      it 'returns true' do
        expect(subject[:housekeeping_bitmaps_enabled]).to eq(true)
      end
    end
  end

  context 'for container registry migration-related fields' do
    it 'returns the static value assigned' do
      {
        container_registry_import_max_tags_count: 0,
        container_registry_import_max_retries: 0,
        container_registry_import_start_max_retries: 0,
        container_registry_import_max_step_duration: 0,
        container_registry_pre_import_tags_rate: 0,
        container_registry_pre_import_timeout: 0,
        container_registry_import_timeout: 0,
        container_registry_import_target_plan: '',
        container_registry_import_created_before: ''
      }.each do |field, value|
        expect(subject[field]).to eq(value)
      end
    end
  end
end

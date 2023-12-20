# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ApplicationSettingFetcher, feature_category: :cell do
  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')

    described_class.clear_in_memory_application_settings!
  end

  describe '.clear_in_memory_application_settings!' do
    subject(:clear_in_memory_application_settings!) { described_class.clear_in_memory_application_settings! }

    before do
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'true')

      described_class.current_application_settings
    end

    it 'will re-initialize settings' do
      expect(ApplicationSetting).to receive(:build_from_defaults).and_call_original

      clear_in_memory_application_settings!
      described_class.current_application_settings
    end
  end

  describe '.current_application_settings' do
    subject(:current_application_settings) { described_class.current_application_settings }

    context 'when ENV["IN_MEMORY_APPLICATION_SETTINGS"] is true' do
      before do
        stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'true')
      end

      it 'returns an in-memory ApplicationSetting object' do
        expect(ApplicationSetting).not_to receive(:current)
        expect(ApplicationSetting).to receive(:build_from_defaults).and_call_original

        expect(current_application_settings).to be_a(ApplicationSetting)
        expect(current_application_settings).not_to be_persisted
      end
    end

    context 'when ENV["IN_MEMORY_APPLICATION_SETTINGS"] is false' do
      context 'and an error is raised' do
        before do
          allow(ApplicationSetting).to receive(:cached).and_raise(StandardError)
        end

        it 'returns nil' do
          expect(current_application_settings).to be_nil
        end
      end

      context 'and settings in cache' do
        it 'fetches the settings from cache' do
          expect(::ApplicationSetting).to receive(:cached).and_call_original

          expect(ActiveRecord::QueryRecorder.new { described_class.current_application_settings }.count).to eq(0)
        end
      end
    end
  end
end

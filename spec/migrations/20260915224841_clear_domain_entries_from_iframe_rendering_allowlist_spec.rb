# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ClearDomainEntriesFromIframeRenderingAllowlist,
  migration: :gitlab_main,
  feature_category: :markdown do
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    it 'clears a configured allowlist' do
      setting = application_settings.create!(iframe_rendering_allowlist: %w[www.youtube.com].to_yaml)

      migrate!

      expect(setting.reload.iframe_rendering_allowlist).to be_nil
    end

    it 'leaves an unset allowlist untouched' do
      setting = application_settings.create!

      migrate!

      expect(setting.reload.iframe_rendering_allowlist).to be_nil
    end
  end
end

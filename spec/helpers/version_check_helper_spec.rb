require 'spec_helper'

describe VersionCheckHelper do
  describe '#version_status_badge' do
    it 'returns nil if not dev environment and not enabled' do
      stub_rails_env('development')
      allow(Gitlab::CurrentSettings.current_application_settings).to receive(:version_check_enabled) { false }

      expect(helper.version_status_badge).to be(nil)
    end

    context 'when production and enabled' do
      before do
        stub_rails_env('production')
        allow(Gitlab::CurrentSettings.current_application_settings).to receive(:version_check_enabled) { true }
        allow(VersionCheck).to receive(:url) { 'https://version.host.com/check.svg?gitlab_info=xxx' }
      end

      it 'returns an image tag' do
        expect(helper.version_status_badge).to start_with('<img')
      end

      it 'has a js prefixed css class' do
        expect(helper.version_status_badge)
          .to match(/class="js-version-status-badge lazy"/)
      end

      it 'has a VersionCheck url as the src' do
        expect(helper.version_status_badge)
          .to include(%{src="https://version.host.com/check.svg?gitlab_info=xxx"})
      end
    end
  end
end

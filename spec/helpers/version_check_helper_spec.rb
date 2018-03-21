require 'spec_helper'

describe VersionCheckHelper do
  describe '#version_status_badge' do
    it 'should return nil if not dev environment and not enabled' do
      allow(Rails.env).to receive(:production?) { false }
      allow(Gitlab::CurrentSettings.current_application_settings).to receive(:version_check_enabled) { false }

      expect(helper.version_status_badge).to be(nil)
    end

    context 'when production and enabled' do
      before do
        allow(Rails.env).to receive(:production?) { true }
        allow(Gitlab::CurrentSettings.current_application_settings).to receive(:version_check_enabled) { true }
        allow_any_instance_of(VersionCheck).to receive(:url) { 'https://version.host.com/check.svg?gitlab_info=xxx' }

        @image_tag = helper.version_status_badge
      end

      it 'should return an image tag' do
        expect(@image_tag).to match(/^<img/)
      end

      it 'should have a js prefixed css class' do
        expect(@image_tag).to match(/class="js-version-status-badge lazy"/)
      end

      it 'should have a VersionCheck url as the src' do
        expect(@image_tag).to match(%r{src="https://version\.host\.com/check\.svg\?gitlab_info=xxx"})
      end
    end
  end
end

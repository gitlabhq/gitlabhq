# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CurrentSettings, feature_category: :shared do
  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  shared_context 'with settings in cache' do
    before do
      2.times { described_class.current_application_settings } # warm the cache
    end
  end

  describe '.expire_current_application_settings', :use_clean_rails_memory_store_caching, :request_store do
    include_context 'with settings in cache'

    it 'expires the cache' do
      described_class.expire_current_application_settings

      expect(ActiveRecord::QueryRecorder.new { described_class.current_application_settings }.count).not_to eq(0)
    end
  end

  describe '.signup_limited?' do
    subject { described_class.signup_limited? }

    context 'when there are allowed domains' do
      before do
        stub_application_setting(domain_allowlist: ['www.gitlab.com'])
      end

      it { is_expected.to be_truthy }
    end

    context 'when there are email restrictions' do
      before do
        stub_application_setting(email_restrictions_enabled: true)
      end

      it { is_expected.to be_truthy }
    end

    context 'when the admin has to approve signups' do
      before do
        stub_application_setting(require_admin_approval_after_user_signup: true)
      end

      it { is_expected.to be_truthy }
    end

    context 'when new users are set to external' do
      before do
        stub_application_setting(user_default_external: true)
      end

      it { is_expected.to be_truthy }
    end

    context 'when there are no restrictions' do
      before do
        stub_application_setting(domain_allowlist: [], email_restrictions_enabled: false, require_admin_approval_after_user_signup: false, user_default_external: false)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '.signup_disabled?' do
    subject { described_class.signup_disabled? }

    context 'when signup is enabled' do
      before do
        stub_application_setting(signup_enabled: true)
      end

      it { is_expected.to be_falsey }
    end

    context 'when signup is disabled' do
      before do
        stub_application_setting(signup_enabled: false)
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#current_application_settings', :use_clean_rails_memory_store_caching do
    let_it_be(:organization_settings) { create(:organization_setting, restricted_visibility_levels: [Gitlab::VisibilityLevel::INTERNAL]) }

    it 'allows keys to be called directly' do
      described_class.update!(home_page_url: 'http://mydomain.com', signup_enabled: false)

      expect(described_class.home_page_url).to eq('http://mydomain.com')
      expect(described_class.signup_enabled?).to be_falsey
      expect(described_class.signup_enabled).to be_falsey
      expect(described_class.metrics_sample_interval).to be(15)
    end

    context 'when key is in ApplicationSettingFetcher' do
      it 'retrieves settings using ApplicationSettingFetcher' do
        expect(Gitlab::ApplicationSettingFetcher).to receive(:current_application_settings).and_call_original

        described_class.home_page_url
      end
    end

    context 'when key is in OrganizationSetting' do
      before do
        allow(Gitlab::ApplicationSettingFetcher).to receive(:current_application_settings).and_return(nil)
      end

      context 'and the current organization is known' do
        before do
          ::Current.organization = organization_settings.organization
        end

        it 'retrieves settings using OrganizationSetting' do
          expect(described_class.restricted_visibility_levels).to eq(organization_settings.restricted_visibility_levels)
        end
      end

      context 'and the current organization is unknown' do
        before do
          allow(Organizations::OrganizationSetting).to receive(:for).and_return(nil)
        end

        it 'raises NoMethodError' do
          expect { described_class.foo }.to raise_error(NoMethodError)
        end
      end
    end

    context 'when key is in both sources' do
      it 'for test purposes, ensure the values are different' do
        expect(
          Gitlab::ApplicationSettingFetcher.current_application_settings.restricted_visibility_levels
        ).not_to eq(organization_settings.restricted_visibility_levels)
      end

      it 'prefers ApplicationSettingFetcher' do
        expect(described_class.restricted_visibility_levels).to eq(
          Gitlab::ApplicationSettingFetcher.current_application_settings.restricted_visibility_levels
        )
      end
    end

    context 'when key is in neither' do
      context 'and the current organization is known', :with_current_organization do
        it 'raises NoMethodError' do
          expect { described_class.foo }.to raise_error(NoMethodError)
        end
      end

      context 'and the current organization is unknown' do
        it 'raises NoMethodError' do
          expect { described_class.foo }.to raise_error(NoMethodError)
        end
      end
    end
  end

  describe '#current_application_settings?' do
    subject(:settings_set) { described_class.current_application_settings? }

    before do
      # unstub, it is stubbed in spec/spec_helper.rb
      allow(described_class).to receive(:current_application_settings?).and_call_original
    end

    context 'when settings are cached in RequestStore' do
      before do
        allow(Gitlab::SafeRequestStore).to receive(:exist?).with(:current_application_settings).and_return(true)
      end

      it 'returns true' do
        expect(settings_set).to be(true)
      end
    end

    context 'when ApplicationSettingFetcher.current_application_settings? returns true' do
      before do
        allow(Gitlab::ApplicationSettingFetcher).to receive(:current_application_settings?).and_return(true)
      end

      it 'returns true' do
        expect(settings_set).to be(true)
      end
    end

    context 'when not cached and not in ApplicationSettingFetcher' do
      it 'returns false' do
        expect(settings_set).to be(false)
      end
    end
  end
end

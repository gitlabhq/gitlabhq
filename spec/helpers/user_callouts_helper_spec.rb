# frozen_string_literal: true

require "spec_helper"

RSpec.describe UserCalloutsHelper do
  let_it_be(:user) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '.show_gke_cluster_integration_callout?' do
    let_it_be(:project) { create(:project) }

    subject { helper.show_gke_cluster_integration_callout?(project) }

    context 'when user can create a cluster' do
      before do
        allow(helper).to receive(:can?).with(anything, :create_cluster, anything)
          .and_return(true)
      end

      context 'when user has not dismissed' do
        before do
          allow(helper).to receive(:user_dismissed?).and_return(false)
        end

        context 'when active_nav_link is in the operations section' do
          before do
            allow(helper).to receive(:active_nav_link?).and_return(true)
          end

          it { is_expected.to be true }
        end

        context 'when active_nav_link is not in the operations section' do
          before do
            allow(helper).to receive(:active_nav_link?).and_return(false)
          end

          it { is_expected.to be false }
        end
      end

      context 'when user dismissed' do
        before do
          allow(helper).to receive(:user_dismissed?).and_return(true)
        end

        it { is_expected.to be false }
      end
    end

    context 'when user can not create a cluster' do
      before do
        allow(helper).to receive(:can?).with(anything, :create_cluster, anything)
          .and_return(false)
      end

      it { is_expected.to be false }
    end
  end

  describe '.show_service_templates_deprecated_callout?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:admin) { create(:user, :admin) }
    let_it_be(:non_admin) { create(:user) }

    subject { helper.show_service_templates_deprecated_callout? }

    where(:self_managed, :is_admin_user, :has_active_service_template, :callout_dismissed, :should_show_callout) do
      true  | true  | true  | false | true
      true  | true  | true  | true  | false
      true  | false | true  | false | false
      false | true  | true  | false | false
      true  | true  | false | false | false
    end

    with_them do
      before do
        allow(::Gitlab).to receive(:com?).and_return(!self_managed)
        allow(helper).to receive(:current_user).and_return(is_admin_user ? admin : non_admin)
        allow(helper).to receive(:user_dismissed?).with(described_class::SERVICE_TEMPLATES_DEPRECATED_CALLOUT) { callout_dismissed }
        create(:service, :template, type: 'MattermostService', active: has_active_service_template)
      end

      it { is_expected.to be should_show_callout }
    end
  end

  describe '.show_customize_homepage_banner?' do
    subject { helper.show_customize_homepage_banner? }

    context 'when user has not dismissed' do
      before do
        allow(helper).to receive(:user_dismissed?).with(described_class::CUSTOMIZE_HOMEPAGE) { false }
      end

      context 'when user is on the default dashboard' do
        it { is_expected.to be true }
      end

      context 'when user is not on the default dashboard' do
        before do
          user.dashboard = 'stars'
        end

        it { is_expected.to be false }
      end
    end

    context 'when user dismissed' do
      before do
        allow(helper).to receive(:user_dismissed?).with(described_class::CUSTOMIZE_HOMEPAGE) { true }
      end

      it { is_expected.to be false }
    end
  end

  describe '.render_flash_user_callout' do
    it 'renders the flash_user_callout partial' do
      expect(helper).to receive(:render)
        .with(/flash_user_callout/, flash_type: :warning, message: 'foo', feature_name: 'bar')

      helper.render_flash_user_callout(:warning, 'foo', 'bar')
    end
  end

  describe '.show_feature_flags_new_version?' do
    subject { helper.show_feature_flags_new_version? }

    let(:user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'when the feature flags new version info has not been dismissed' do
      it { is_expected.to be_truthy }
    end

    context 'when the feature flags new version has been dismissed' do
      before do
        create(:user_callout, user: user, feature_name: described_class::FEATURE_FLAGS_NEW_VERSION)
      end

      it { is_expected.to be_falsy }
    end
  end

  describe '.show_registration_enabled_user_callout?' do
    let_it_be(:admin) { create(:user, :admin) }

    subject { helper.show_registration_enabled_user_callout? }

    context 'when on gitlab.com' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(true)
        allow(helper).to receive(:current_user).and_return(admin)
        stub_application_setting(signup_enabled: true)
        allow(helper).to receive(:user_dismissed?).with(described_class::REGISTRATION_ENABLED_CALLOUT) { false }
      end

      it { is_expected.to be false }
    end

    context 'when `current_user` is not an admin' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(false)
        allow(helper).to receive(:current_user).and_return(user)
        stub_application_setting(signup_enabled: true)
        allow(helper).to receive(:user_dismissed?).with(described_class::REGISTRATION_ENABLED_CALLOUT) { false }
      end

      it { is_expected.to be false }
    end

    context 'when signup is disabled' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(false)
        allow(helper).to receive(:current_user).and_return(admin)
        stub_application_setting(signup_enabled: false)
        allow(helper).to receive(:user_dismissed?).with(described_class::REGISTRATION_ENABLED_CALLOUT) { false }
      end

      it { is_expected.to be false }
    end

    context 'when user has dismissed callout' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(false)
        allow(helper).to receive(:current_user).and_return(admin)
        stub_application_setting(signup_enabled: true)
        allow(helper).to receive(:user_dismissed?).with(described_class::REGISTRATION_ENABLED_CALLOUT) { true }
      end

      it { is_expected.to be false }
    end

    context 'when not gitlab.com, `current_user` is an admin, signup is enabled, and user has not dismissed callout' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(false)
        allow(helper).to receive(:current_user).and_return(admin)
        stub_application_setting(signup_enabled: true)
        allow(helper).to receive(:user_dismissed?).with(described_class::REGISTRATION_ENABLED_CALLOUT) { false }
      end

      it { is_expected.to be true }
    end
  end

  describe '.show_unfinished_tag_cleanup_callout?' do
    subject { helper.show_unfinished_tag_cleanup_callout? }

    before do
      allow(helper).to receive(:user_dismissed?).with(described_class::UNFINISHED_TAG_CLEANUP_CALLOUT) { dismissed }
    end

    context 'when user has not dismissed' do
      let(:dismissed) { false }

      it { is_expected.to be true }
    end

    context 'when user dismissed' do
      let(:dismissed) { true }

      it { is_expected.to be false }
    end
  end
end

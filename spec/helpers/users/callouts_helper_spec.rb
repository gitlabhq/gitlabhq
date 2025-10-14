# frozen_string_literal: true

require "spec_helper"

RSpec.describe Users::CalloutsHelper, feature_category: :navigation do
  include StubVersion
  let_it_be(:user, refind: true) { create(:user) }

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
        create(:callout, user: user, feature_name: described_class::FEATURE_FLAGS_NEW_VERSION)
      end

      it { is_expected.to be_falsy }
    end
  end

  describe '.show_registration_enabled_user_callout?', :do_not_mock_admin_mode_setting do
    let_it_be(:admin) { create(:user, :admin) }

    subject { helper.show_registration_enabled_user_callout? }

    using RSpec::Parameterized::TableSyntax

    where(:gitlab_com, :current_user, :signup_enabled, :controller_path, :expected_result) do
      false | ref(:admin) | true  | 'admin/users'     | true
      true  | ref(:admin) | true  | 'admin/users'     | false
      false | ref(:admin) | false | 'admin/users'     | false
      false | ref(:admin) | true  | 'projects/issues' | false
    end

    with_them do
      before do
        allow(::Gitlab).to receive(:com?).and_return(gitlab_com)
        allow(helper).to receive(:current_user).and_return(current_user)
        stub_application_setting(signup_enabled: signup_enabled)
        allow(helper.controller).to receive(:controller_path).and_return(controller_path)
      end

      it { is_expected.to be expected_result }
    end
  end

  describe '.show_openssl_callout?', :do_not_mock_admin_mode_setting do
    let_it_be(:admin) { create(:user, :admin) }

    subject { helper.show_openssl_callout? }

    using RSpec::Parameterized::TableSyntax

    where(:version, :current_user, :user_dismissed, :controller_path, :expected_result) do
      '17.1.0'  | ref(:admin) | false | 'admin'       | true
      '17.1.0'  | ref(:admin) | false | 'admin/users' | true
      '17.6.99' | ref(:admin) | false | 'admin'       | true
      '17.0.0'  | ref(:admin) | false | 'admin'       | false
      '17.7.0'  | ref(:admin) | false | 'admin'       | false
      '17.1.0'  | ref(:user)  | false | 'admin'       | false
      '17.1.0'  | ref(:admin) | true  | 'admin'       | false
      '17.1.0'  | ref(:admin) | false | 'admin-'      | false
    end

    with_them do
      before do
        stub_version(version, 'abcdefg')
        allow(helper).to receive(:current_user).and_return(current_user)
        allow(helper).to receive(:user_dismissed?).with(described_class::OPENSSL_CALLOUT) { user_dismissed }
        allow(helper.controller).to receive(:controller_path).and_return(controller_path)
      end

      it { is_expected.to be expected_result }
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

  describe '.show_security_newsletter_user_callout?', :do_not_mock_admin_mode_setting do
    let_it_be(:admin) { create(:user, :admin) }

    subject { helper.show_security_newsletter_user_callout? }

    context 'when `current_user` is not an admin' do
      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:user_dismissed?).with(described_class::SECURITY_NEWSLETTER_CALLOUT) { false }
      end

      it { is_expected.to be false }
    end

    context 'when user has dismissed callout' do
      before do
        allow(helper).to receive(:current_user).and_return(admin)
        allow(helper).to receive(:user_dismissed?).with(described_class::SECURITY_NEWSLETTER_CALLOUT) { true }
      end

      it { is_expected.to be false }
    end

    context 'when `current_user` is an admin and user has not dismissed callout' do
      before do
        allow(helper).to receive(:current_user).and_return(admin)
        allow(helper).to receive(:user_dismissed?).with(described_class::SECURITY_NEWSLETTER_CALLOUT) { false }
      end

      it { is_expected.to be true }
    end
  end

  describe '.show_branch_rules_tip?' do
    subject { helper.show_branch_rules_tip? }

    before do
      allow(helper).to receive(:user_dismissed?).with(described_class::BRANCH_RULES_TIP_CALLOUT) { dismissed }
    end

    context 'when user has dismissed callout' do
      let(:dismissed) { true }

      it { is_expected.to be false }
    end

    context 'when user has not dismissed callout' do
      let(:dismissed) { false }

      it { is_expected.to be true }
    end
  end

  describe '#web_hook_disabled_dismissed?', feature_category: :webhooks do
    context 'without a project' do
      it 'is false' do
        expect(helper).not_to be_web_hook_disabled_dismissed(nil)
      end
    end

    context 'with a project' do
      let_it_be(:project) { create(:project) }
      let(:factory) { :project_callout }
      let(:container_key) { :project }
      let(:container) { project }
      let(:key) { "web_hooks:last_failure:project-#{project.id}" }

      include_examples 'CalloutsHelper#web_hook_disabled_dismissed shared examples'
    end
  end

  describe '.show_transition_to_jihu_callout?', :do_not_mock_admin_mode_setting do
    let_it_be(:admin) { create(:user, :admin) }

    subject { helper.show_transition_to_jihu_callout? }

    using RSpec::Parameterized::TableSyntax

    where(:gitlab_jh, :current_user, :timezone, :user_dismissed, :expected_result) do
      false | ref(:admin) | 'Asia/Hong_Kong'      | false | true
      false | ref(:admin) | 'Asia/Shanghai'       | false | true
      false | ref(:admin) | 'Asia/Macau'          | false | true
      false | ref(:admin) | 'Asia/Chongqing'      | false | true

      true  | ref(:admin) | 'Asia/Shanghai'       | false | false
      false | ref(:user)  | 'Asia/Shanghai'       | false | false
      false | ref(:admin) | 'America/Los_Angeles' | false | false
      false | ref(:admin) | 'Asia/Shanghai'       | true  | false
    end

    with_them do
      before do
        allow(::Gitlab).to receive(:jh?).and_return(gitlab_jh)
        allow(helper).to receive(:current_user).and_return(current_user)
        allow(helper).to receive(:user_dismissed?).with(described_class::TRANSITION_TO_JIHU_CALLOUT) { user_dismissed }
        allow(current_user).to receive(:timezone).and_return(timezone)
      end

      it { is_expected.to be expected_result }
    end
  end

  describe '.show_period_in_terraform_state_name_alert_callout?' do
    subject { helper.show_period_in_terraform_state_name_alert_callout? }

    before do
      allow(helper).to receive(:user_dismissed?).with(described_class::PERIOD_IN_TERRAFORM_STATE_NAME_ALERT) { dismissed }
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

  describe '.show_new_mr_dashboard_banner?' do
    subject { helper.show_new_mr_dashboard_banner? }

    before do
      allow(helper).to receive(:user_dismissed?).with(described_class::NEW_MR_DASHBOARD_BANNER) { dismissed }
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

  describe '.render_product_usage_data_collection_changes', :do_not_mock_admin_mode_setting do
    let_it_be(:admin) { create(:user, :admin) }

    subject(:render_callout) { helper.render_product_usage_data_collection_changes(current_user) }

    context 'when current_user is nil' do
      let(:current_user) { nil }

      it 'does not render the callout' do
        expect(helper).not_to receive(:render)
        render_callout
      end
    end

    context 'when current_user is not an admin' do
      let(:current_user) { user }

      before do
        allow(user).to receive(:can_admin_all_resources?).and_return(false)
      end

      it 'does not render the callout' do
        expect(helper).not_to receive(:render)
        render_callout
      end
    end

    context 'when current_user is admin but has dismissed the callout' do
      let(:current_user) { admin }

      before do
        allow(admin).to receive(:can_admin_all_resources?).and_return(true)
        allow(helper).to receive(:user_dismissed?)
          .with(described_class::PRODUCT_USAGE_DATA_COLLECTION_CHANGES).and_return(true)
      end

      it 'does not render the callout' do
        expect(helper).not_to receive(:render)
        render_callout
      end
    end

    context 'when current_user is admin and has not dismissed the callout' do
      let(:current_user) { admin }

      before do
        allow(admin).to receive(:can_admin_all_resources?).and_return(true)
        allow(helper).to receive(:user_dismissed?)
          .with(described_class::PRODUCT_USAGE_DATA_COLLECTION_CHANGES).and_return(false)
      end

      it 'renders the callout' do
        expect(helper).to receive(:render).with('shared/product_usage_data_collection_changes_callout')
        render_callout
      end
    end
  end

  describe '#show_email_otp_enrollment_callout?' do
    subject { helper.show_email_otp_enrollment_callout? }

    let(:email_otp_required_after) { 31.days.from_now }

    before do
      user.update!(email_otp_required_after: email_otp_required_after)
    end

    it { is_expected.to be true }

    context 'when user is not signed in' do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it { is_expected.to be false }
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(email_based_mfa: false)
      end

      it { is_expected.to be false }
    end

    context 'when user has dismissed the banner' do
      before do
        create(:callout, user: user, feature_name: :email_otp_enrollment_callout)
      end

      it { is_expected.to be false }
    end

    context 'when user does not have email_otp_required_after set' do
      let(:email_otp_required_after) { nil }

      it { is_expected.to be false }
    end

    context 'when user has two-factor authentication enabled' do
      before do
        user.update!(otp_required_for_login: true)
      end

      it { is_expected.to be false }
    end

    context 'when user does not sign in with a password' do
      before do
        user.update!(password_automatically_set: true)
      end

      it { is_expected.to be false }
    end

    context 'when email_otp_required_after is more than 60 days away' do
      let(:email_otp_required_after) { 61.days.from_now }

      it { is_expected.to be false }
    end

    context 'when email_otp_required_after is less than 31 days away' do
      let(:email_otp_required_after) { 30.days.from_now }

      it { is_expected.to be false }
    end
  end
end

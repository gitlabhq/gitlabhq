# frozen_string_literal: true

require "spec_helper"

RSpec.describe Users::CalloutsHelper do
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
        create(:callout, user: user, feature_name: described_class::FEATURE_FLAGS_NEW_VERSION)
      end

      it { is_expected.to be_falsy }
    end
  end

  describe '.show_registration_enabled_user_callout?', :do_not_mock_admin_mode_setting do
    let_it_be(:admin) { create(:user, :admin) }

    subject { helper.show_registration_enabled_user_callout? }

    using RSpec::Parameterized::TableSyntax

    where(:gitlab_com, :current_user, :signup_enabled, :user_dismissed, :controller_path, :expected_result) do
      false | ref(:admin) | true  | false | 'admin/users'     | true
      true  | ref(:admin) | true  | false | 'admin/users'     | false
      false | ref(:user)  | true  | false | 'admin/users'     | false
      false | ref(:admin) | false | false | 'admin/users'     | false
      false | ref(:admin) | true  | true  | 'admin/users'     | false
      false | ref(:admin) | true  | false | 'projects/issues' | false
    end

    with_them do
      before do
        allow(::Gitlab).to receive(:com?).and_return(gitlab_com)
        allow(helper).to receive(:current_user).and_return(current_user)
        stub_application_setting(signup_enabled: signup_enabled)
        allow(helper).to receive(:user_dismissed?).with(described_class::REGISTRATION_ENABLED_CALLOUT) { user_dismissed }
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

  describe '#web_hook_disabled_dismissed?' do
    context 'without a project' do
      it 'is false' do
        expect(helper).not_to be_web_hook_disabled_dismissed(nil)
      end
    end

    context 'with a project' do
      let_it_be(:project) { create(:project) }

      context 'the web-hook failure callout has never been dismissed' do
        it 'is false' do
          expect(helper).not_to be_web_hook_disabled_dismissed(project)
        end
      end

      context 'the web-hook failure callout has been dismissed', :freeze_time do
        before do
          create(:project_callout,
                 feature_name: described_class::WEB_HOOK_DISABLED,
                 user: user,
                 project: project,
                 dismissed_at: 1.week.ago)
        end

        it 'is true' do
          expect(helper).to be_web_hook_disabled_dismissed(project)
        end

        context 'when there was an older failure', :clean_gitlab_redis_shared_state do
          let(:key) { "web_hooks:last_failure:project-#{project.id}" }

          before do
            Gitlab::Redis::SharedState.with { |r| r.set(key, 1.month.ago.iso8601) }
          end

          it 'is true' do
            expect(helper).to be_web_hook_disabled_dismissed(project)
          end
        end

        context 'when there has been a more recent failure', :clean_gitlab_redis_shared_state do
          let(:key) { "web_hooks:last_failure:project-#{project.id}" }

          before do
            Gitlab::Redis::SharedState.with { |r| r.set(key, 1.day.ago.iso8601) }
          end

          it 'is false' do
            expect(helper).not_to be_web_hook_disabled_dismissed(project)
          end
        end
      end
    end
  end
end

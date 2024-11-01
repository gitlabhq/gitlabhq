# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BasePolicy do
  include ExternalAuthorizationServiceHelpers
  include AdminModeHelper

  describe '.class_for' do
    it 'detects policy class based on the subject ancestors' do
      expect(DeclarativePolicy.class_for(GenericCommitStatus.new)).to eq(CommitStatusPolicy)
    end

    it 'detects policy class for a presented subject' do
      presentee = Ci::BuildPresenter.new(Ci::Build.new)

      expect(DeclarativePolicy.class_for(presentee)).to eq(Ci::BuildPolicy)
    end

    it 'uses GlobalPolicy when :global is given' do
      expect(DeclarativePolicy.class_for(:global)).to eq(GlobalPolicy)
    end
  end

  shared_examples 'admin only access' do |ability|
    def policy
      # method, because we want a fresh cache each time.
      described_class.new(current_user, nil)
    end

    let(:current_user) { build_stubbed(:user) }

    subject { policy }

    it { is_expected.not_to be_allowed(ability) }

    context 'with an admin' do
      let(:current_user) { build_stubbed(:admin) }

      it 'allowed when in admin mode' do
        enable_admin_mode!(current_user)

        is_expected.to be_allowed(ability)
      end

      context 'when user from job token' do
        before do
          allow(current_user).to receive(:from_ci_job_token?).and_return(true)
          enable_admin_mode!(current_user)
        end

        it 'prevents when settings in admin mode' do
          allow(Gitlab::CurrentSettings).to receive(:admin_mode).and_return(false)

          is_expected.to be_disallowed(ability)
        end

        it 'prevents when user is admin' do
          is_expected.to be_disallowed(ability)
        end
      end

      it 'prevented when not in admin mode' do
        is_expected.not_to be_allowed(ability)
      end
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.not_to be_allowed(ability) }
    end

    describe 'bypassing the session for sessionless login', :request_store do
      let(:current_user) { build_stubbed(:admin) }

      it 'changes from prevented to allowed' do
        expect { Gitlab::Auth::CurrentUserMode.bypass_session!(current_user.id) }
          .to change { policy.allowed?(ability) }.from(false).to(true)
      end
    end
  end

  describe 'read cross project' do
    let(:current_user) { build_stubbed(:user) }
    let(:user) { build_stubbed(:user) }

    subject { described_class.new(current_user, [user]) }

    it { is_expected.to be_allowed(:read_cross_project) }

    context 'for anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_allowed(:read_cross_project) }
    end

    context 'when an external authorization service is enabled' do
      before do
        enable_external_authorization_service_check
      end

      it_behaves_like 'admin only access', :read_cross_project
    end
  end

  describe 'full private access: read_all_resources' do
    it_behaves_like 'admin only access', :read_all_resources
  end

  describe 'full private access: admin_all_resources' do
    it_behaves_like 'admin only access', :admin_all_resources
  end

  describe 'change_repository_storage' do
    it_behaves_like 'admin only access', :change_repository_storage
  end

  describe 'placeholder_user' do
    let(:current_user) { build_stubbed(:user, user_type: :placeholder) }

    subject { described_class.new(current_user, nil) }

    it { expect_disallowed(:access_git) }
    it { expect_disallowed(:log_in) }
    it { expect_disallowed(:access_api) }
    it { expect_disallowed(:receive_notifications) }
    it { expect_disallowed(:use_slash_commands) }
  end

  describe 'import_user' do
    let(:current_user) { build_stubbed(:user, user_type: :import_user) }

    subject { described_class.new(current_user, nil) }

    it { expect_disallowed(:access_git) }
    it { expect_disallowed(:log_in) }
    it { expect_disallowed(:access_api) }
    it { expect_disallowed(:receive_notifications) }
    it { expect_disallowed(:use_slash_commands) }
  end
end

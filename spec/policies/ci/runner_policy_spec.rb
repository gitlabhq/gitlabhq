# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerPolicy, feature_category: :runner_core do
  let_it_be(:owner) { create(:user) }

  subject(:policy) { described_class.new(user, runner) }

  include_context 'with runner policy environment'

  describe 'ability :read_runner' do
    it_behaves_like 'runner policy not allowed for levels lower than maintainer', :read_runner
    it_behaves_like 'runner policy', :read_runner
  end

  describe 'ability :read_builds' do
    it_behaves_like 'runner policy not allowed for levels lower than maintainer', :read_builds

    context 'without access' do
      let_it_be(:user) { create(:user) }

      it_behaves_like 'does not allow accessing runners/runner managers on any scope', :read_builds
    end

    context 'with guest access' do
      let(:user) { guest }

      it_behaves_like 'does not allow accessing runners/runner managers on any scope', :read_builds
    end

    context 'with reporter access' do
      let(:user) { reporter }

      it_behaves_like 'does not allow accessing runners/runner managers on any scope', :read_builds
    end

    context 'with developer access' do
      let(:user) { developer }

      it_behaves_like 'does not allow accessing runners/runner managers on any scope', :read_builds
    end

    context 'with maintainer access' do
      let(:user) { maintainer }

      context 'with instance runner' do
        let(:runner) { instance_runner }

        it { expect_disallowed :read_builds }
      end

      context 'with group runner' do
        let(:runner) { group_runner }

        it { expect_allowed :read_builds }
      end

      it_behaves_like 'runner policy with project runner', :read_builds
    end

    it_behaves_like 'runner policy for user with owner access', :read_builds
    it_behaves_like 'runner policy for admin user', :read_builds
  end

  describe 'ability :read_runner_sensitive_data' do
    it_behaves_like 'runner policy not allowed for levels lower than maintainer', :read_runner_sensitive_data
    it_behaves_like 'runner policy', :read_runner_sensitive_data, scope: %i[group_runner project_runner]

    context 'with instance runner' do
      let(:runner) { instance_runner }

      context 'with owner access' do
        let(:user) { owner }

        # Non-admin users don't have access to instance runner sensitive data
        it { expect_disallowed :read_runner_sensitive_data }
      end

      context 'with admin access' do
        let_it_be(:user) { create(:admin) }

        # Admin users don't have access to instance runner sensitive data, unless admin mode is enabled
        it { expect_disallowed :read_runner_sensitive_data }

        context 'when admin mode is enabled', :enable_admin_mode do
          it { expect_allowed :read_runner_sensitive_data }
        end
      end
    end
  end

  describe 'ability :update_runner' do
    it_behaves_like 'runner policy not allowed for levels lower than maintainer', :update_runner

    context 'with maintainer access' do
      let(:user) { maintainer }

      context 'with instance runner' do
        let(:runner) { instance_runner }

        it { expect_disallowed :update_runner }
      end

      context 'with group runner' do
        let(:runner) { group_runner }

        it { expect_disallowed :update_runner }
      end

      it_behaves_like 'runner policy with project runner', :update_runner
    end

    it_behaves_like 'runner policy for user with owner access', :update_runner
  end

  describe 'ability :read_ephemeral_token' do
    let_it_be(:runner) { create(:ci_runner, creator: owner) }

    let(:creator) { owner }

    context 'with request made by creator' do
      let(:user) { creator }

      it { expect_allowed :read_ephemeral_token }
    end

    context 'with request made by another user' do
      let(:user) { create(:admin) }

      it { expect_disallowed :read_ephemeral_token }
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeployKeyPolicy do
  subject { described_class.new(current_user, deploy_key) }

  describe 'updating a deploy_key' do
    context 'when a regular user' do
      let(:current_user) { create(:user) }

      context 'tries to update private deploy key attached to project' do
        let(:deploy_key) { create(:deploy_key, public: false) }
        let(:project) { create(:project_empty_repo) }

        before do
          project.add_maintainer(current_user)
          project.deploy_keys << deploy_key
        end

        it { is_expected.to be_allowed(:update_deploy_key) }
      end

      context 'tries to update private deploy key attached to other project' do
        let(:deploy_key) { create(:deploy_key, public: false) }
        let(:other_project) { create(:project_empty_repo) }

        before do
          other_project.deploy_keys << deploy_key
        end

        it { is_expected.to be_disallowed(:update_deploy_key) }
      end

      context 'tries to update public deploy key' do
        let(:deploy_key) { create(:another_deploy_key, public: true) }

        it { is_expected.to be_disallowed(:update_deploy_key) }
      end
    end

    context 'when an admin user' do
      let(:current_user) { create(:user, :admin) }

      context 'tries to update private deploy key' do
        let(:deploy_key) { create(:deploy_key, public: false) }

        context 'when admin mode enabled', :enable_admin_mode do
          it { is_expected.to be_allowed(:update_deploy_key) }
        end

        context 'when admin mode disabled' do
          it { is_expected.to be_disallowed(:update_deploy_key) }
        end
      end

      context 'when an admin user tries to update public deploy key' do
        let(:deploy_key) { create(:another_deploy_key, public: true) }

        context 'when admin mode enabled', :enable_admin_mode do
          it { is_expected.to be_allowed(:update_deploy_key) }
        end

        context 'when admin mode disabled' do
          it { is_expected.to be_disallowed(:update_deploy_key) }
        end
      end
    end
  end
end

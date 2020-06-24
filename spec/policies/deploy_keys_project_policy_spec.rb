# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeployKeysProjectPolicy do
  subject { described_class.new(current_user, deploy_key.deploy_keys_project_for(project)) }

  describe 'updating a deploy_keys_project' do
    context 'when a project maintainer' do
      let(:current_user) { create(:user) }

      context 'tries to update private deploy key attached to project' do
        let(:deploy_key) { create(:deploy_key, public: false) }
        let(:project) { create(:project_empty_repo) }

        before do
          project.add_maintainer(current_user)
          project.deploy_keys << deploy_key
        end

        it { is_expected.to be_disallowed(:update_deploy_keys_project) }
      end

      context 'tries to update public deploy key attached to project' do
        let(:deploy_key) { create(:deploy_key, public: true) }
        let(:project) { create(:project_empty_repo) }

        before do
          project.add_maintainer(current_user)
          project.deploy_keys << deploy_key
        end

        it { is_expected.to be_allowed(:update_deploy_keys_project) }
      end
    end

    context 'when a non-maintainer project member' do
      let(:current_user) { create(:user) }
      let(:project) { create(:project_empty_repo) }

      before do
        project.add_developer(current_user)
        project.deploy_keys << deploy_key
      end

      context 'tries to update private deploy key attached to project' do
        let(:deploy_key) { create(:deploy_key, public: false) }

        it { is_expected.to be_disallowed(:update_deploy_keys_project) }
      end

      context 'tries to update public deploy key attached to project' do
        let(:deploy_key) { create(:deploy_key, public: true) }

        it { is_expected.to be_disallowed(:update_deploy_keys_project) }
      end
    end

    context 'when a user is not a project member' do
      let(:current_user) { create(:user) }
      let(:project) { create(:project_empty_repo) }
      let(:deploy_key) { create(:deploy_key, public: true) }

      before do
        project.deploy_keys << deploy_key
      end

      context 'tries to update public deploy key attached to project' do
        it { is_expected.to be_disallowed(:update_deploy_keys_project) }
      end
    end
  end
end
